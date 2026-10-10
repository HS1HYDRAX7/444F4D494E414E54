import os
import re
import shutil

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
GAMES = {
    "forsaken": ["fly_gui", "esp", "world", "world_extras", "misc_extras", "player_extras", "automation"],
    "pressure": ["esp", "anti", "automation"],
}


def compress(game, names):
    folder = os.path.join(ROOT, "games", game, "features")
    out_path = os.path.join(ROOT, "games", game, "features.lua")
    lines = [
        "local features = {}",
        "",
    ]
    for name in names:
        source_path = os.path.join(folder, name + ".lua")
        with open(source_path, "r", encoding="utf-8") as handle:
            source = handle.read().rstrip("\n")
        lines.append("features[\"%s\"] = (function()" % name)
        lines.append(source)
        lines.append("end)()")
        lines.append("")
    lines.append("return features")
    lines.append("")
    with open(out_path, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines))
    shutil.rmtree(folder)
    return out_path


def rewrite_init(game, names):
    path = os.path.join(ROOT, "games", game, "init.lua")
    with open(path, "r", encoding="utf-8") as handle:
        text = handle.read()
    bundled = "local BUNDLED = { %s }\n" % ", ".join("%s = true" % n for n in names)
    text = text.replace("local FEATURES = {", bundled + "\nlocal FEATURES = {", 1)
    old_require = "        local feature = ctx.modules:require(path)\n"
    assert text.count(old_require) == 1, game + ": require line not found"
    new_require = (
        "        local feature\n"
        "        if BUNDLED[name] then\n"
        "            feature = ctx.modules:require(\"games/%s/features\")[name]\n"
        "        else\n"
        "            feature = ctx.modules:require(path)\n"
        "        end\n"
    ) % game
    text = text.replace(old_require, new_require, 1)
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(text)
    return path


if __name__ == "__main__":
    for game, names in GAMES.items():
        print("compressed:", compress(game, names))
        print("init updated:", rewrite_init(game, names))
