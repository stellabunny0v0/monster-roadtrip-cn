#!/bin/bash
set -e
here="$(cd "$(dirname "$0")" && pwd -P)"
IFS= read -r app < "$here/BepInEx/MonsterRoadtripChinese.macos-install/app-name.txt"
case "$app" in */*|*..*|'') echo '无效的游戏安装记录。'; exit 1;; esac
exe=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$here/$app/Contents/Info.plist")
case "$exe" in */*|*..*|'') echo '无效的游戏程序名。'; exit 1;; esac
target="$here/$app/Contents/MacOS/$exe"
# Steam expands %command% to its normal executable followed by launch arguments.
if [ "$#" -gt 0 ]; then
    case "$1" in "$target"|"$here/$app"|"$here/$app/") shift;;
        -*) ;; *) echo 'Steam 传入的游戏路径不匹配，请重新复制安装器显示的启动选项。'; exit 1;;
    esac
fi
cd "$here"
exec /bin/bash "$here/run_bepinex.sh" "$target" "$@"
