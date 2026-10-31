#!/bin/bash
# Runs on Git Bash too. macOS probes are mocked: NOT a native Mac test.
set -e
repo="$(cd "$(dirname "$0")/../.." && pwd -P)"
package="$(cd "${1:?Pass the extracted Mac package directory}" && pwd -P)"
mkdir -p "$repo/.cache"
fixture=$(mktemp -d "$repo/.cache/macos-installer-XXXXXX")
runner="$fixture/runner.sh"
cat > "$runner" <<'RUNNER'
#!/bin/bash
set -e
source "$1/installer/manage-macos.sh"
shift
mr_platform() { :; }
mr_plist_executable() { printf '%s\n' MonsterRoadtrip; }
mr_architecture() { printf '%s\n' "${FIXTURE_ARCH:-Mach-O 64-bit executable x86_64}"; }
mr_rosetta() { :; }
mr_not_running() { [ "${FIXTURE_RUNNING:-0}" = 0 ] || mr_fail 'fixture game running'; }
cp() {
    if [ "${FIXTURE_COPY_FAIL:-0}" = 1 ]; then
        for arg in "$@"; do case "$arg" in */payload/BepInEx/core/BepInEx.dll) return 42;; esac; done
    fi
    command cp "$@"
}
mr_main "$@"
RUNNER
passes=0
pass() { passes=$((passes+1)); printf 'PASS %s: %s\n' "$passes" "$1"; }
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
new_game() {
    game="$fixture/$1 游戏 with spaces"
    app='Monster Roadtrip.app'
    mkdir -p "$game/$app/Contents/MacOS" "$game/$app/Contents/Resources/Data/Managed"
    printf fixture > "$game/$app/Contents/Info.plist"
    printf '#!/bin/sh\nexit 99\n' > "$game/$app/Contents/MacOS/MonsterRoadtrip"
    chmod u+x "$game/$app/Contents/MacOS/MonsterRoadtrip"
    managed="$game/$app/Contents/Resources/Data/Managed"
    printf '%s\n' CoreCheckpointXmlSerializer SerializeCorePlayerData UnserializeCorePlayerData StatWidget ConvertTextTags ReadLocalizedTextFile LoadMetatextsFile > "$managed/Assembly-CSharp.dll"
    for name in UnityEngine.dll UnityEngine.CoreModule.dll Unity.Addressables.dll Unity.ResourceManager.dll; do printf fixture > "$managed/$name"; done
    for rel in UserData "$app/UserData" "$app/Contents/UserData" "$app/Contents/Resources/UserData"; do
        mkdir -p "$game/$rel"
        printf '<name>杰奎琳</name> %s\n' "$rel" > "$game/$rel/玩家.xml"
    done
    backup="$fixture/$1 backups"
}
run() { /bin/bash "$runner" "$package" "$1" "$game" "$backup"; }
reject() { if run "$1" > "$fixture/rejected.log" 2>&1; then fail "Unexpected success: $2"; fi; pass "$2"; }
for script in "$repo"/installer/macos/*.sh "$repo"/installer/macos/*.command "$package/payload/run_bepinex.sh"; do /bin/bash -n "$script"; done
pass 'shell syntax including tuned upstream launcher'
new_game clean
run install > "$fixture/install.log"
[ -f "$game/BepInEx/plugins/MonsterRoadtripChinese/MonsterRoadtripChinese.dll" ] || fail 'DLL missing'
saved=$(find "$backup" -name saves-before.tsv -print)
cmp -s "$saved" "${saved%/*}/saves-copy.tsv"
cmp -s "$saved" "${saved%/*}/saves-after.tsv"
[ "$(wc -l < "$saved" | tr -d ' ')" = 4 ] || fail 'Did not back up all four save layouts'
pass 'install with spaces/Chinese paths; all four save layouts copied and unchanged'
count_before=$(find "$backup" -name operation.txt | wc -l)
run install > "$fixture/repeat.log"
[ "$(find "$backup" -name operation.txt | wc -l)" = "$count_before" ] || fail 'Repeated install wrote backup'
pass 'identical install is a no-op'
run uninstall > "$fixture/uninstall.log"
[ ! -e "$game/libdoorstop.dylib" ] && [ ! -e "$game/monster_roadtrip_cn.sh" ] || fail 'Clean loader remains'
find "$backup" -name saves-after.tsv -print | while IFS= read -r f; do cmp -s "$f" "${f%/*}/saves-before.tsv"; done
[ -f "$game/$app/UserData/玩家.xml" ] || fail 'Save removed'
pass 'uninstall removes new loader and keeps saves'
new_game rollback
FIXTURE_COPY_FAIL=1; export FIXTURE_COPY_FAIL
reject install 'failed copy rolls back files already copied'
unset FIXTURE_COPY_FAIL
[ ! -e "$game/.doorstop_version" ] && [ ! -e "$game/BepInEx/core/0Harmony.dll" ] && [ ! -e "$game/BepInEx/MonsterRoadtripChinese.macos-install" ] || fail 'Rollback left installed files'
[ -f "$game/$app/UserData/玩家.xml" ] || fail 'Rollback touched save'
new_game shared
mkdir -p "$game/BepInEx/core" "$game/BepInEx/plugins/AnotherMod" "$game/BepInEx/config"
cp -p "$package/payload/BepInEx/core/BepInEx.dll" "$game/BepInEx/core/BepInEx.dll"
printf other > "$game/BepInEx/plugins/AnotherMod/other.dll"
printf config > "$game/BepInEx/config/local.cfg"
run install > "$fixture/shared-install.log"
run uninstall > "$fixture/shared-uninstall.log"
[ -f "$game/BepInEx/core/BepInEx.dll" ] && [ -f "$game/libdoorstop.dylib" ] && [ -f "$game/BepInEx/plugins/AnotherMod/other.dll" ] && [ -f "$game/BepInEx/config/local.cfg" ] || fail 'Shared file removed'
pass 'pre-existing loader, another mod and config preserved'
new_game changed
run install > "$fixture/changed-install.log"
printf user-edit >> "$game/BepInEx/plugins/MonsterRoadtripChinese/Translation/schinese_events_bubbles.txt"
reject uninstall 'modified installed file stops uninstall before deleting anything'
[ -f "$game/libdoorstop.dylib" ] || fail 'Partial uninstall occurred'
new_game unknown
mkdir -p "$game/BepInEx/core"
printf unknown > "$game/BepInEx/core/BepInEx.dll"
reject install 'unknown loader rejected before backups or writes'
[ ! -d "$backup" ] || fail 'Unknown loader caused writes'
new_game arm
FIXTURE_ARCH='Mach-O 64-bit executable arm64'; export FIXTURE_ARCH
reject install 'arm64-only game rejected'
unset FIXTURE_ARCH
new_game running
FIXTURE_RUNNING=1; export FIXTURE_RUNNING
reject install 'running game rejected'
unset FIXTURE_RUNNING
new_game symbolic
mkdir "$fixture/outside"
if MSYS=winsymlinks:nativestrict ln -s "$fixture/outside" "$game/BepInEx" && [ -L "$game/BepInEx" ]; then
    reject install 'symbolic link in destination rejected'
else
    printf 'SKIP: native symbolic-link fixture unavailable on this host\n'
fi
new_game corrupt
original_package="$package"
cp -R "$package" "$fixture/corrupt-package"; package="$fixture/corrupt-package"
printf corrupt >> "$package/payload/BepInEx/core/BepInEx.dll"
reject install 'corrupted payload rejected'
package="$original_package"
new_game traversal
cp -R "$package" "$fixture/traversal-package"; package="$fixture/traversal-package"
printf '%064d\tplugin\t../outside\t-\n' 0 >> "$package/package-files.tsv"
reject install 'manifest traversal rejected'
package="$original_package"
new_game mismatch
printf old-interface > "$game/$app/Contents/Resources/Data/Managed/Assembly-CSharp.dll"
reject install 'missing required game interface rejected'
printf '\n%s fixture checks passed. macOS APIs were mocked; no game launched.\nFixture: %s\n' "$passes" "$fixture"
