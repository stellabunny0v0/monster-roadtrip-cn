#!/bin/bash
here="$(cd "$(dirname "$0")" && pwd -P)" || exit 1
/bin/bash "$here/installer/manage-macos.sh" uninstall "$@"
result=$?
if [ -t 0 ]; then read -r -p '按回车关闭窗口…' _; fi
exit "$result"
