import base64
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "dist", "Dominant_bundle.lua")
SKIP_ASSETS = {"logo.png", "index.lua"}
SKIP_DIRS = {"build", "dist", ".git", "scripts"}


def read(path):
    with open(path, "r", encoding="utf-8") as handle:
        return handle.read()


def module_key(relpath):
    return relpath[:-4].replace(os.sep, "/")


def collect_modules():
    modules = []
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for name in filenames:
            if not name.endswith(".lua") or name == "loader.lua":
                continue
            full = os.path.join(dirpath, name)
            rel = os.path.relpath(full, ROOT)
            modules.append((module_key(rel), read(full)))
    modules.sort()
    return modules


def collect_assets():
    assets = {}
    base = os.path.join(ROOT, "assets")
    for dirpath, dirnames, filenames in os.walk(base):
        for name in filenames:
            if name.endswith(".lua") or name in SKIP_ASSETS:
                continue
            full = os.path.join(dirpath, name)
            key = os.path.relpath(full, base).replace(os.sep, "/")
            with open(full, "rb") as handle:
                assets[key] = base64.b64encode(handle.read()).decode("ascii")
    return dict(sorted(assets.items()))


def build():
    lines = ["local __EMBED = {}", ""]
    for key, source in collect_modules():
        lines.append('__EMBED["%s"] = function()' % key)
        lines.append(source.rstrip("\n"))
        lines.append("end")
        lines.append("")
    assets = collect_assets()
    lines.append("local __ASSETS = {")
    for key, encoded in assets.items():
        lines.append('    ["%s"] = "%s",' % (key, encoded))
    lines.append("}")
    lines.append("")

    loader = read(os.path.join(ROOT, "loader.lua"))
    old = (
        '        local Modules = loadstring(game:HttpGet(BASE .. "core/modules.lua"))()\n'
        "        local modules = Modules.new(BASE)\n"
    )
    new = (
        '        local Modules = __EMBED["core/modules"]()\n'
        "        local modules = Modules.new(BASE)\n"
        "        modules.embedded = __EMBED\n"
        "        modules.embeddedAssets = __ASSETS\n"
    )
    assert loader.count(old) == 1, "loader anchor not found"
    loader = loader.replace(old, new)
    logo_spawn = "task.spawn(function()\n    screen.setLogo(resolveLogo())\nend)\n"
    assert loader.count(logo_spawn) == 1, "logo anchor not found"
    loader = loader.replace(logo_spawn, "")
    lines.append(loader.rstrip("\n"))
    lines.append("")

    with open(OUT, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines))
    size = os.path.getsize(OUT)
    print("modules:", len(collect_modules()), "assets:", len(assets), "bytes:", size)
    return OUT


if __name__ == "__main__":
    build()
