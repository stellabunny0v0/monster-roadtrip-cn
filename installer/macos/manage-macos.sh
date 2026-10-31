#!/bin/bash
# Bash 3.2 compatible. No sudo, network downloads, signing or save restoration.
mr_fail() { printf '错误：%s\n' "$*" >&2; return 1; }
mr_hash() {
    if command -v shasum >/dev/null 2>&1; then shasum -a 256 < "$1" | awk '{print $1}';
    else sha256sum < "$1" | awk '{print $1}'; fi
}
mr_platform() { [ "$(uname -s)" = Darwin ] || mr_fail '此包只用于 macOS。'; }
mr_plist_executable() { /usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$1/Contents/Info.plist"; }
mr_architecture() { file -b "$1"; }
mr_rosetta() {
    if [ "$(/usr/sbin/sysctl -n hw.optional.arm64 2>/dev/null || true)" = 1 ]; then
        /usr/bin/arch -x86_64 /usr/bin/true || mr_fail '请先按 macOS 系统提示安装 Rosetta，然后重新安装。'
    fi
}
mr_not_running() {
    if pgrep -x "$1" >/dev/null 2>&1; then mr_fail '请先正常退出游戏。'; fi
}
mr_plain_path() {
    case "$1" in *$'\n'*|*$'\r'*|*$'\t'*|*:*) mr_fail '路径不能包含换行、制表符或冒号。';; esac
}
mr_relative() {
    case "$1" in ''|/*|../*|*/../*|*/..|./*|*/./*|*//*|*\\*) return 1;; esac
    mr_plain_path "$1"
}
mr_allowed() {
    mr_relative "$2" || return 1
    case "$1:$2" in
        loader:.doorstop_version|loader:changelog.txt|loader:libdoorstop.dylib|loader:run_bepinex.sh) ;;
        loader:BepInEx/core/*.dll|loader:BepInEx/core/MonsterRoadtripMonoCompat.LICENSE.txt)
            case "${2#BepInEx/core/}" in */*) return 1;; esac;;
        plugin:BepInEx/plugins/MonsterRoadtripChinese/MonsterRoadtripChinese.dll) ;;
        plugin:BepInEx/plugins/MonsterRoadtripChinese/Translation/*)
            case "${2#BepInEx/plugins/MonsterRoadtripChinese/Translation/}" in */*) return 1;; esac;;
        launcher:monster_roadtrip_cn.sh) ;;
        *) return 1;;
    esac
}
mr_no_links() {
    local base="$1" rest="$2" part
    while [ -n "$rest" ]; do
        part="${rest%%/*}"; base="$base/$part"
        [ ! -L "$base" ] || { mr_fail "拒绝符号链接：$base"; return 1; }
        if [ "$rest" = "$part" ]; then break; fi
        rest="${rest#*/}"
    done
}
mr_select_game() {
    local selected="${1:-}" candidate
    if [ -z "$selected" ]; then
        candidate="$HOME/Library/Application Support/Steam/steamapps/common/Monster Prom 3 - Monster Roadtrip"
        if [ -d "$candidate" ]; then selected="$candidate";
        else selected=$(/usr/bin/osascript -e 'POSIX path of (choose file with prompt "请选择 Monster Prom 3 - Monster Roadtrip 游戏 .app" of type {"com.apple.application-bundle"})'); fi
    fi
    selected="${selected%/}"
    mr_plain_path "$selected"
    case "$selected" in
        *.app) MR_APP="$(basename "$selected")"; MR_ROOT="$(cd "$(dirname "$selected")" && pwd -P)";;
        *) MR_ROOT="$(cd "$selected" && pwd -P)"; MR_APP=''
           for candidate in "$MR_ROOT"/*.app; do
               [ -d "$candidate" ] || continue
               [ -z "$MR_APP" ] || { mr_fail '目录中有多个 .app，请直接选择游戏的 .app。'; return 1; }
               MR_APP="$(basename "$candidate")"
           done;;
    esac
    [ -n "$MR_APP" ] && [ "$MR_ROOT" != / ] && [ -w "$MR_ROOT" ] || { mr_fail '未找到可写的游戏目录。'; return 1; }
    mr_plain_path "$MR_ROOT/$MR_APP"
    mr_no_links "$MR_ROOT" "$MR_APP/Contents/Info.plist"
    MR_EXE=$(mr_plist_executable "$MR_ROOT/$MR_APP")
    case "$MR_EXE" in ''|*/*|*..*) mr_fail '游戏程序名不合法。'; return 1;; esac
    [ "$(printf '%s' "$MR_EXE" | tr '[:upper:]' '[:lower:]' | tr -d ' _-')" = monsterroadtrip ] || { mr_fail '请选择 Monster Roadtrip，不是系列中的其他游戏。'; return 1; }
    mr_no_links "$MR_ROOT" "$MR_APP/Contents/MacOS/$MR_EXE"
    [ -x "$MR_ROOT/$MR_APP/Contents/MacOS/$MR_EXE" ] || { mr_fail '游戏程序不存在或没有执行权限。'; return 1; }
    mr_not_running "$MR_EXE"
    MR_STATE="$MR_ROOT/BepInEx/MonsterRoadtripChinese.macos-install"
    mr_no_links "$MR_ROOT" 'BepInEx/MonsterRoadtripChinese.macos-install'
}
mr_check_game() {
    local arch managed='' dir symbol
    arch=$(mr_architecture "$MR_ROOT/$MR_APP/Contents/MacOS/$MR_EXE")
    case "$arch" in *Mach-O*x86_64*) ;; *) mr_fail '实验包只接受含 x86_64 的 Mac 游戏程序；不支持纯 arm64、32 位或 Windows 程序。'; return 1;; esac
    for dir in "$MR_ROOT/$MR_APP/Contents/Resources/Data/Managed" "$MR_ROOT/$MR_APP/Contents/Managed"; do
        if [ -f "$dir/Assembly-CSharp.dll" ]; then managed="$dir"; break; fi
    done
    [ -n "$managed" ] || { mr_fail '找不到 Mono 游戏程序集；不支持 IL2CPP 版。'; return 1; }
    for symbol in Assembly-CSharp.dll UnityEngine.dll UnityEngine.CoreModule.dll Unity.Addressables.dll Unity.ResourceManager.dll; do
        [ -f "$managed/$symbol" ] || { mr_fail "缺少 $symbol"; return 1; }
        mr_no_links "$MR_ROOT" "${managed#"$MR_ROOT"/}/$symbol"
    done
    for symbol in CoreCheckpointXmlSerializer SerializeCorePlayerData UnserializeCorePlayerData StatWidget ConvertTextTags ReadLocalizedTextFile LoadMetatextsFile; do
        LC_ALL=C grep -a -q "$symbol" "$managed/Assembly-CSharp.dll" || { mr_fail "游戏接口不匹配：$symbol"; return 1; }
    done
    mr_rosetta
}
mr_save_roots() {
    printf '%s\n' 'UserData' "$MR_APP/UserData" "$MR_APP/Contents/UserData" "$MR_APP/Contents/Resources/UserData"
}
mr_inventory_saves() {
    local base="$1" out="$2" rel f name unsorted="$2.unsorted"
    : > "$unsorted"
    while IFS= read -r rel; do
        mr_no_links "$base" "$rel"
        [ -d "$base/$rel" ] || continue
        while IFS= read -r -d '' f; do
            [ ! -L "$f" ] || { mr_fail 'UserData 中存在符号链接，已停止。'; return 1; }
            [ -f "$f" ] || continue
            name="${f#"$base"/}"; mr_plain_path "$name"
            printf '%s\t%s\n' "$(mr_hash "$f")" "$name" >> "$unsorted"
        done < <(find "$base/$rel" -print0)
    done < <(mr_save_roots)
    LC_ALL=C sort "$unsorted" > "$out"
    rm -f "$unsorted"
}
mr_backup() {
    local base="${2:-$HOME/Library/Application Support/MonsterRoadtripChinese/backups}" rel
    mr_plain_path "$base"
    mkdir -p "$base"
    base="$(cd "$base" && pwd -P)"
    case "$base/" in "$MR_ROOT/"*) mr_fail '备份目录必须位于游戏目录以外。'; return 1;; esac
    MR_BACKUP=$(mktemp -d "$base/$(date +%Y%m%d-%H%M%S)-XXXXXX")
    mr_inventory_saves "$MR_ROOT" "$MR_BACKUP/saves-before.tsv"
    mkdir "$MR_BACKUP/UserDataCopies" "$MR_BACKUP/previous"
    while IFS= read -r rel; do
        if [ -d "$MR_ROOT/$rel" ]; then
            mkdir -p "$MR_BACKUP/UserDataCopies/$(dirname "$rel")"
            cp -pR "$MR_ROOT/$rel" "$MR_BACKUP/UserDataCopies/$rel"
        fi
    done < <(mr_save_roots)
    mr_inventory_saves "$MR_BACKUP/UserDataCopies" "$MR_BACKUP/saves-copy.tsv"
    cmp -s "$MR_BACKUP/saves-before.tsv" "$MR_BACKUP/saves-copy.tsv" || { mr_fail '存档备份校验失败，未开始修改 Mod 文件。'; return 1; }
    printf '操作：%s\n游戏：%s\n仅复制备份，不自动还原存档。\n' "$1" "$MR_ROOT" > "$MR_BACKUP/operation.txt"
    printf '备份：%s\n' "$MR_BACKUP"
}
mr_validate_manifest() {
    local hash kind rel allowed extra count=0
    [ -f "$MR_PACKAGE/package-version.txt" ] && [ -f "$MR_PACKAGE/package-files.tsv" ] || { mr_fail '安装包不完整。'; return 1; }
    MR_VERSION=$(cat "$MR_PACKAGE/package-version.txt")
    case "$MR_VERSION" in ''|*[!a-zA-Z0-9.-]*) return 1;; esac
    [ "$(cut -f3 "$MR_PACKAGE/package-files.tsv" | LC_ALL=C sort | uniq -d | wc -l | tr -d ' ')" = 0 ] || { mr_fail '安装清单路径重复。'; return 1; }
    while IFS=$'\t' read -r hash kind rel allowed extra; do
        [[ "$hash" =~ ^[a-f0-9]{64}$ ]] && [ -z "$extra" ] && mr_allowed "$kind" "$rel" || { mr_fail '安装清单不合法。'; return 1; }
        if [ "$allowed" != '-' ]; then [[ "$allowed" =~ ^[a-f0-9]{64}$ ]] || return 1; fi
        mr_no_links "$MR_PACKAGE" "payload/$rel"
        [ -f "$MR_PACKAGE/payload/$rel" ] && [ "$(mr_hash "$MR_PACKAGE/payload/$rel")" = "$hash" ] || { mr_fail "安装包校验失败：$rel"; return 1; }
        mr_no_links "$MR_ROOT" "$rel"
        [ ! -e "$MR_ROOT/$rel" ] || [ -f "$MR_ROOT/$rel" ] || { mr_fail "目标不是普通文件：$rel"; return 1; }
        if [ "$kind" != plugin ] && [ -f "$MR_ROOT/$rel" ]; then
            local existing; existing=$(mr_hash "$MR_ROOT/$rel")
            [ "$existing" = "$hash" ] || [ "$existing" = "$allowed" ] || { mr_fail "已有加载器不匹配，已停止：$rel"; return 1; }
        fi
        count=$((count+1))
    done < "$MR_PACKAGE/package-files.tsv"
    [ "$count" -ge 30 ] || { mr_fail '安装清单缺少文件。'; return 1; }
    [ ! -e "$MR_ROOT/winhttp.dll" ] || { mr_fail '目录中有 Windows 加载器，请先确认游戏和安装包平台。'; return 1; }
    [ ! -d "$MR_ROOT/BepInEx/core" ] || [ -f "$MR_ROOT/BepInEx/core/BepInEx.dll" ] || { mr_fail '已有加载器目录不完整，请先核对原安装。'; return 1; }
}
mr_validate_record() {
    local hash kind rel created extra
    [ -f "$MR_STATE/files.tsv" ] && [ -f "$MR_STATE/version.txt" ] || { mr_fail '找不到有效安装记录。'; return 1; }
    mr_no_links "$MR_ROOT" 'BepInEx/MonsterRoadtripChinese.macos-install/files.tsv'
    for rel in version.txt app-name.txt loader-existed.txt backup-path.txt; do
        mr_no_links "$MR_ROOT" "BepInEx/MonsterRoadtripChinese.macos-install/$rel"
        [ -f "$MR_STATE/$rel" ] || { mr_fail '安装记录缺少文件。'; return 1; }
    done
    while IFS=$'\t' read -r hash kind rel created extra; do
        [[ "$hash" =~ ^[a-f0-9]{64}$ ]] && [ -z "$extra" ] && mr_allowed "$kind" "$rel" || { mr_fail '安装记录不合法。'; return 1; }
        case "$created" in 0|1) ;; *) return 1;; esac
        mr_no_links "$MR_ROOT" "$rel"
        [ -f "$MR_ROOT/$rel" ] && [ "$(mr_hash "$MR_ROOT/$rel")" = "$hash" ] || { mr_fail "已安装文件缺失或被修改，请先保留并核对：$rel"; return 1; }
    done < "$MR_STATE/files.tsv"
    [ -s "$MR_STATE/files.tsv" ] || return 1
}
mr_rollback() {
    local result=$? hash kind rel created extra
    if [ "${MR_TRANSACTION:-0}" = 1 ]; then
        printf '安装未完成，正在回退本次 Mod 文件修改；不会还原或覆盖存档。\n' >&2
        while IFS=$'\t' read -r hash kind rel created extra; do
            if [ "$created" = 1 ]; then rm -f "$MR_ROOT/$rel";
            elif [ -f "$MR_BACKUP/previous/$rel" ]; then cp -p "$MR_BACKUP/previous/$rel" "$MR_ROOT/$rel"; fi
        done < "$MR_TEMP/files.tsv"
        rm -f "$MR_TEMP/files.tsv" "$MR_TEMP/version.txt" "$MR_TEMP/app-name.txt" "$MR_TEMP/loader-existed.txt" "$MR_TEMP/backup-path.txt"
        rmdir "$MR_TEMP" 2>/dev/null || true
    fi
    exit "$result"
}
mr_launch_option() {
    local path="$MR_ROOT/monster_roadtrip_cn.sh"
    path="${path//\\/\\\\}"; path="${path//\"/\\\"}"; path="${path//\$/\\$}"; path="${path//\`/\\\`}"
    printf '"/bin/bash" "%s" %%command%%\n' "$path"
}
mr_install() {
    local hash kind rel allowed extra created loader=0
    mr_check_game
    mr_validate_manifest
    if [ -d "$MR_STATE" ]; then
        mr_validate_record
        [ "$(cat "$MR_STATE/version.txt")" = "$MR_VERSION" ] && cmp -s <(cut -f1-3 "$MR_PACKAGE/package-files.tsv") <(cut -f1-3 "$MR_STATE/files.tsv") || { mr_fail '请先使用旧安装包卸载旧版，再安装新版。'; return 1; }
        printf '此版本已完整安装，无需重复安装。\n'; mr_launch_option; return
    fi
    [ ! -e "$MR_ROOT/BepInEx/core" ] && [ ! -e "$MR_ROOT/libdoorstop.dylib" ] && [ ! -e "$MR_ROOT/run_bepinex.sh" ] || loader=1
    mr_backup install "${1:-}"
    mkdir -p "$MR_ROOT/BepInEx"
    MR_TEMP=$(mktemp -d "$MR_ROOT/BepInEx/.mr-cn-install-XXXXXX")
    : > "$MR_TEMP/files.tsv"; MR_TRANSACTION=1; trap mr_rollback EXIT
    while IFS=$'\t' read -r hash kind rel allowed extra; do
        created=1
        if [ -f "$MR_ROOT/$rel" ]; then
            created=0; mkdir -p "$MR_BACKUP/previous/$(dirname "$rel")"
            cp -p "$MR_ROOT/$rel" "$MR_BACKUP/previous/$rel"
            cmp -s "$MR_ROOT/$rel" "$MR_BACKUP/previous/$rel"
        fi
        printf '%s\t%s\t%s\t%s\n' "$hash" "$kind" "$rel" "$created" >> "$MR_TEMP/files.tsv"
        mkdir -p "$MR_ROOT/$(dirname "$rel")"
        cp -p "$MR_PACKAGE/payload/$rel" "$MR_ROOT/$rel"
        case "$rel" in *.sh) chmod u+x "$MR_ROOT/$rel";; esac
        [ "$(mr_hash "$MR_ROOT/$rel")" = "$hash" ]
    done < "$MR_PACKAGE/package-files.tsv"
    mr_inventory_saves "$MR_ROOT" "$MR_BACKUP/saves-after.tsv"
    cmp -s "$MR_BACKUP/saves-before.tsv" "$MR_BACKUP/saves-after.tsv"
    printf '%s\n' "$MR_VERSION" > "$MR_TEMP/version.txt"
    printf '%s\n' "$MR_APP" > "$MR_TEMP/app-name.txt"
    printf '%s\n' "$loader" > "$MR_TEMP/loader-existed.txt"
    printf '%s\n' "$MR_BACKUP" > "$MR_TEMP/backup-path.txt"
    mv "$MR_TEMP" "$MR_STATE"
    MR_TRANSACTION=0; trap - EXIT
    printf '\n安装完成（macOS 实验版，尚未真机验证）。\n将下一行复制到 Steam → 属性 → 通用 → 启动选项，然后通过 Steam 启动游戏：\n'
    mr_launch_option
}
mr_uninstall() {
    local hash kind rel created extra keep=0 f
    mr_validate_record
    [ "$(cat "$MR_STATE/app-name.txt")" = "$MR_APP" ] || { mr_fail '所选 .app 与安装记录不一致。'; return 1; }
    [ "$(cat "$MR_STATE/loader-existed.txt")" = 0 ] || keep=1
    for f in "$MR_ROOT"/BepInEx/plugins/* "$MR_ROOT"/BepInEx/patchers/*; do
        [ -e "$f" ] || continue
        [ "$f" = "$MR_ROOT/BepInEx/plugins/MonsterRoadtripChinese" ] || keep=1
    done
    mr_backup uninstall "${1:-}"
    while IFS=$'\t' read -r hash kind rel created extra; do
        if [ "$kind" = loader ] && { [ "$keep" = 1 ] || [ "$created" = 0 ]; }; then continue; fi
        mkdir -p "$MR_BACKUP/previous/$(dirname "$rel")"
        cp -p "$MR_ROOT/$rel" "$MR_BACKUP/previous/$rel"
        cmp -s "$MR_ROOT/$rel" "$MR_BACKUP/previous/$rel"
    done < "$MR_STATE/files.tsv"
    # All hashes and backups pass before the first deletion.
    while IFS=$'\t' read -r hash kind rel created extra; do
        if [ "$kind" = loader ] && { [ "$keep" = 1 ] || [ "$created" = 0 ]; }; then continue; fi
        rm -f "$MR_ROOT/$rel"
    done < "$MR_STATE/files.tsv"
    mr_inventory_saves "$MR_ROOT" "$MR_BACKUP/saves-after.tsv"
    cmp -s "$MR_BACKUP/saves-before.tsv" "$MR_BACKUP/saves-after.tsv"
    rm -f "$MR_STATE/files.tsv" "$MR_STATE/version.txt" "$MR_STATE/app-name.txt" "$MR_STATE/loader-existed.txt" "$MR_STATE/backup-path.txt"
    rmdir "$MR_STATE"
    # Only empty directories are removed; config, logs, backups and other mods remain.
    rmdir "$MR_ROOT/BepInEx/plugins/MonsterRoadtripChinese/Translation" "$MR_ROOT/BepInEx/plugins/MonsterRoadtripChinese" "$MR_ROOT/BepInEx/plugins" "$MR_ROOT/BepInEx/core" "$MR_ROOT/BepInEx" 2>/dev/null || true
    printf '汉化已卸载。请在 Steam 启动选项中删除本汉化的那一行，再正常启动。存档、配置和备份已保留。\n'
    [ "$keep" = 0 ] || printf '检测到共享加载器或其他 Mod，已保留 BepInEx 加载器。\n'
}
mr_main() {
    set -e
    mr_platform
    local action="${1:-}" selected="${2:-}" backup="${3:-}"
    case "$action" in install|uninstall) ;; *) mr_fail '用法：manage-macos.sh install|uninstall [游戏目录或.app] [备份目录]'; return 1;; esac
    [ "$#" -le 3 ] || return 1
    MR_PACKAGE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
    mr_select_game "$selected"
    case "$action" in install) mr_install "$backup";; uninstall) mr_uninstall "$backup";; esac
}
if [ "${BASH_SOURCE[0]}" = "$0" ]; then mr_main "$@"; fi
