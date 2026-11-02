#!/bin/bash
# Isolated file-operation tests; never loads code or changes system policy.
set -e
repo="$(cd "$(dirname "$0")/../.." && pwd -P)"
source "$repo/installer/macos/manage-macos.sh"
fixture=$(mktemp -d "${TMPDIR:-/tmp}/mr-loader-trust-XXXXXX")
trap 'rm -rf "$fixture"' EXIT
passes=0
pass() { passes=$((passes+1)); printf 'PASS %s: %s\n' "$passes" "$1"; }
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
reset_case() {
    MR_ROOT="$fixture/$1 游戏 with spaces"; MR_PACKAGE="$fixture/$1 package"
    mkdir -p "$MR_ROOT" "$MR_PACKAGE"
    printf 'fixture loader bytes\n' > "$MR_ROOT/libdoorstop.dylib"
    expected=$(mr_hash "$MR_ROOT/libdoorstop.dylib")
    printf '%s\tloader\tlibdoorstop.dylib\t-\n' "$expected" > "$MR_PACKAGE/package-files.tsv"
    marker="$MR_PACKAGE/quarantine"; events="$MR_PACKAGE/xattr-events"
    : > "$marker"; : > "$events"
    xattr_fail=0; read_fail=0; xattr_stuck=0; tamper=''
}
# Model one quarantine attribute and one independent attribute. Record every
# attempted mutation and reject any target other than the exact loader path.
mr_xattr() {
    if [ "$#" = 1 ]; then
        [ "$1" = "$MR_ROOT/libdoorstop.dylib" ] || return 91
        [ "$read_fail" = 0 ] || return 92
        printf 'com.example.keep\n'
        if [ -e "$marker" ]; then printf 'com.apple.quarantine\n'; fi
    elif [ "$#" = 3 ] && [ "$1" = -d ] && [ "$2" = com.apple.quarantine ] && [ "$3" = "$MR_ROOT/libdoorstop.dylib" ]; then
        printf '%s\n' "$3" >> "$events"
        [ "$xattr_fail" = 0 ] || return 93
        if [ "$xattr_stuck" = 0 ]; then rm "$marker"; fi
    else return 94; fi
}
read() {
    local result=0
    builtin read "$@" || result=$?
    case "$tamper" in
        content) printf changed >> "$MR_ROOT/libdoorstop.dylib";;
        symlink) rm "$MR_ROOT/libdoorstop.dylib"; ln -s "$outside" "$MR_ROOT/libdoorstop.dylib";;
        hardlink) ln "$MR_ROOT/libdoorstop.dylib" "$MR_ROOT/alias";;
    esac
    return "$result"
}
offer() { printf '%s' "$1" | (mr_offer_loader_trust) > "$MR_PACKAGE/output.log" 2>&1; }
untouched() { [ -e "$marker" ] && [ ! -s "$events" ] || fail 'Unexpected quarantine change'; }

reset_case accept
offer $'YES\n'
[ ! -e "$marker" ] && [ "$(wc -l < "$events" | tr -d ' ')" = 1 ] || fail 'Exact consent did not remove marker once'
[ "$(mr_hash "$MR_ROOT/libdoorstop.dylib")" = "$expected" ] || fail 'File bytes changed'
pass 'explicit YES changes only quarantine on the exact, hash-matched loader'
for answer in '' $'\n' $'no\n' $'yes\n' $'y\n' YES; do
    reset_case "decline-$passes"
    offer "$answer"; untouched
    pass 'EOF, blank, negative, lowercase, shorthand or incomplete input skips'
done
reset_case no-marker
rm "$marker"; offer $'YES\n'
[ ! -s "$events" ] || fail 'Absent attribute triggered removal'
grep -q '无需处理' "$MR_PACKAGE/output.log" || fail 'Absent attribute not reported'
pass 'no quarantine means no prompt/mutation'
reset_case read-error
read_fail=1; offer $'YES\n'; untouched
pass 'unreadable attributes skip without claiming success'
reset_case delete-error
xattr_fail=1; offer $'YES\n'
[ -e "$marker" ] && grep -q '未能移除' "$MR_PACKAGE/output.log" || fail 'Removal failure hidden'
pass 'removal error is reported without failing the completed installation'
reset_case stuck
xattr_stuck=1; offer $'YES\n'
[ -e "$marker" ] && grep -q '无法确认' "$MR_PACKAGE/output.log" || fail 'Post-removal check missing'
pass 'post-removal check detects an attribute that remains'
reset_case corrupt
printf changed >> "$MR_ROOT/libdoorstop.dylib"; offer $'YES\n'; untouched
pass 'hash mismatch is rejected before reading/removing attributes'
outside="$fixture/outside.dylib"; printf outside > "$outside"
reset_case symlink
rm "$MR_ROOT/libdoorstop.dylib"; ln -s "$outside" "$MR_ROOT/libdoorstop.dylib"
offer $'YES\n'; untouched
pass 'symbolic link rejected'
reset_case hardlink
ln "$MR_ROOT/libdoorstop.dylib" "$MR_ROOT/alias"; offer $'YES\n'; untouched
pass 'hard link rejected'
for tamper_kind in content symlink hardlink; do
    reset_case "prompt-$tamper_kind"
    tamper="$tamper_kind"; offer $'YES\n'; untouched
    pass "file $tamper_kind introduced while confirming is rejected"
done
reset_case missing-manifest-entry
: > "$MR_PACKAGE/package-files.tsv"; offer $'YES\n'; untouched
pass 'missing manifest hash cannot authorize a mutation'

# On macOS also exercise the actual xattr utility on a harmless fixture file.
# All native attributes are limited to a temporary directory, never a game.
if [ "$(uname -s)" = Darwin ]; then
    reset_case native
    source "$repo/installer/macos/manage-macos.sh"
    /usr/bin/xattr -w com.apple.quarantine '0081;00000000;InstallerFixture;' "$MR_ROOT/libdoorstop.dylib"
    /usr/bin/xattr -w com.example.keep unchanged "$MR_ROOT/libdoorstop.dylib"
    before=$(/usr/bin/xattr -p com.apple.quarantine "$MR_ROOT/libdoorstop.dylib")
    offer $'\n'
    [ "$(/usr/bin/xattr -p com.apple.quarantine "$MR_ROOT/libdoorstop.dylib")" = "$before" ] || fail 'Native decline changed attribute'
    offer $'YES\n'
    if /usr/bin/xattr -p com.apple.quarantine "$MR_ROOT/libdoorstop.dylib" >/dev/null 2>&1; then fail 'Native attribute remains'; fi
    [ "$(/usr/bin/xattr -p com.example.keep "$MR_ROOT/libdoorstop.dylib")" = unchanged ] || fail 'Other attribute changed'
    [ "$(mr_hash "$MR_ROOT/libdoorstop.dylib")" = "$expected" ] || fail 'Native file bytes changed'
    pass 'native macOS xattr: decline preserves metadata, consent removes only quarantine; bytes unchanged'
fi
printf '\n%s loader-trust checks passed. No game was launched.\n' "$passes"
