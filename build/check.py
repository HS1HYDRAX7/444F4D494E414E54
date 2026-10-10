import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SKIP = {"build", "dist", "vendor", ".git"}
STRING_FILES = ["shared/strings.lua", "shared/strings_tools.lua", "games/pressure/strings.lua", "games/forsaken/strings.lua"]
FORSAKEN_CORE = "games/forsaken/core.lua"


def lua_files():
    out = []
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in SKIP]
        for name in filenames:
            if name.endswith(".lua"):
                out.append(os.path.relpath(os.path.join(dirpath, name), ROOT).replace(os.sep, "/"))
    return sorted(out)


def code_only(src):
    out = []
    i, n = 0, len(src)
    while i < n:
        ch = src[i]
        if src.startswith("--", i):
            m = re.match(r"--\[(=*)\[", src[i:])
            if m:
                close = "]" + m.group(1) + "]"
                j = src.find(close, i)
                j = n if j < 0 else j + len(close)
            else:
                j = src.find("\n", i)
                j = n if j < 0 else j
            out.append(re.sub(r"[^\n]", " ", src[i:j]))
            i = j
            continue
        m = re.match(r"\[(=*)\[", src[i:])
        if m:
            close = "]" + m.group(1) + "]"
            j = src.find(close, i)
            j = n if j < 0 else j + len(close)
            out.append(re.sub(r"[^\n]", " ", src[i:j]))
            i = j
            continue
        if ch in "\"'":
            j = i + 1
            while j < n and src[j] != ch:
                j += 2 if src[j] == "\\" else 1
            j = min(j + 1, n)
            out.append(re.sub(r"[^\n]", " ", src[i:j]))
            i = j
            continue
        out.append(ch)
        i += 1
    return "".join(out)


def balance_problem(code):
    depth = 0
    for token in re.findall(r"\b(function|if|do|repeat|end|until)\b", code):
        if token in ("function", "if", "do", "repeat"):
            depth += 1
        else:
            depth -= 1
        if depth < 0:
            return "unexpected end/until"
    return None if depth == 0 else "unclosed block (depth %d)" % depth


def en_keys():
    keys = set()
    for rel in STRING_FILES:
        path = os.path.join(ROOT, rel)
        if not os.path.exists(path):
            continue
        text = open(path, encoding="utf-8").read()
        m = re.search(r"\n\s*en = \{", text)
        if not m:
            continue
        rest = text[m.end():]
        end = re.search(r"\n\s*(pt|es|ru) = \{|\n\s*\},?\n", rest)
        block = rest[:end.start()] if end else rest
        keys.update(re.findall(r"([A-Za-z_][A-Za-z0-9_]*)\s*=\s*\"", block))
    return keys


def pack_keys(lang):
    keys = set()
    for rel in STRING_FILES:
        path = os.path.join(ROOT, rel)
        if not os.path.exists(path):
            continue
        text = open(path, encoding="utf-8").read()
        m = re.search(r"\n\s*%s = \{" % lang, text)
        if not m:
            continue
        rest = text[m.end():]
        end = re.search(r"\n\s*(en|pt|es|ru) = \{|\n\s*\},?\n", rest)
        block = rest[:end.start()] if end else rest
        keys.update(re.findall(r"([A-Za-z_][A-Za-z0-9_]*)\s*=\s*\"", block))
    return keys


def main():
    problems = []
    files = lua_files()
    keys_en = en_keys()

    for rel in files:
        raw = open(os.path.join(ROOT, rel), encoding="utf-8").read()
        code = code_only(raw)
        if rel != FORSAKEN_CORE:
            issue = balance_problem(code)
            if issue:
                problems.append("%s: block balance: %s" % (rel, issue))
        for m in re.finditer(r"require\(\s*\"([^\"]+)\"\s*\)", raw):
            target = m.group(1)
            if not os.path.exists(os.path.join(ROOT, target + ".lua")):
                problems.append("%s: require of missing module '%s'" % (rel, target))
        if rel == FORSAKEN_CORE or rel.endswith("strings.lua"):
            continue
        for m in re.finditer(r"\b(?:ctx\.|core\.|self\.)?L\(\s*\"([A-Za-z0-9_]+)\"", raw):
            if not m.group(1).endswith("_") and m.group(1) not in keys_en:
                problems.append("%s: missing string key '%s'" % (rel, m.group(1)))
        for m in re.finditer(r"ui\.(?:section|toggle|slider|dropdown|button|number|color|keybind|labelToggle)\(\s*\w+\s*,\s*\"([A-Za-z0-9_]+)\"", raw):
            if not m.group(1).endswith("_") and m.group(1) not in keys_en:
                problems.append("%s: missing UI key '%s'" % (rel, m.group(1)))
        for m in re.finditer(r"H\.(?:Section|Button|Toggle|Slider|Dropdown|Textbox|Number|Color)\(\s*\w+\s*,\s*\"([A-Za-z0-9_]+)\"", raw):
            if m.group(1) not in keys_en:
                problems.append("%s: missing UI key '%s'" % (rel, m.group(1)))


    required = set()
    for rel in files:
        raw = open(os.path.join(ROOT, rel), encoding="utf-8").read()
        for m in re.finditer(r"require\(\s*\"([^\"]+)\"\s*\)", raw):
            required.add(m.group(1))
        for m in re.finditer(r"\"((?:games|shared|core|vendor|assets)/[^\"]+)\"", raw):
            required.add(m.group(1))
    entry = {"loader", "games/index", "core/app", "core/base", "core/config", "core/modules", "core/i18n", "core/ui",
             "core/vind", "core/keysystem", "shared/assets", "shared/sounds", "shared/ui_common", "assets/index"}
    for rel in files:
        key = rel[:-4]
        if key.startswith(("build/", "dist/", "vendor/", "scripts/")) or key in entry:
            continue
        if re.match(r"games/[a-z]+/(init|strings|changelog)$", key):
            continue
        if key not in required and not any(r.startswith(key) for r in required):
            problems.append("%s: never loaded (unused file)" % rel)

    for lang in ["pt", "es", "ru"]:
        missing = sorted(keys_en - pack_keys(lang))
        if missing:
            problems.append("language %s is missing %d keys (first: %s)" % (lang, len(missing), ", ".join(missing[:5])))

    for rel in ["games/forsaken/init.lua", "games/pressure/init.lua"]:
        path = os.path.join(ROOT, rel)
        if os.path.exists(path):
            text = open(path, encoding="utf-8").read()
            if "tab_settings" in text:
                problems.append("%s: has its own settings tab (duplicates the main Settings)" % rel)

    for leftover in ["shared/chat", "features/integrations"]:
        for rel in files:
            if leftover in open(os.path.join(ROOT, rel), encoding="utf-8").read():
                problems.append("%s: still references removed '%s'" % (rel, leftover))

    if problems:
        for p in problems:
            print("PROBLEM:", p)
        print("%d problem(s)" % len(problems))
        return 1
    print("OK: %d Lua files checked, no problems" % len(files))
    return 0


if __name__ == "__main__":
    sys.exit(main())
