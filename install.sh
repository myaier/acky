#!/bin/bash
# First installation only. Published copies pin this URL to one immutable release.
set -euo pipefail
main() {
  local cdn_origin='https://cdn.acky.dev'
  local release_base='https://github.com/myaier/acky/releases/download/v0.4.652'
  local machine archive
  # Bash 5 unwinds function locals before EXIT after errexit; rollback state must outlive main.
  temporary=''; destination=''; stage=''; backup=''; app=''; installed=0
  [ "$(uname -s)" = Darwin ] || { echo '此安装方式只支持 macOS。' >&2; exit 1; }
  machine=$(uname -m)
  case "${machine}" in
    arm64) archive=acky-mac-arm64.zip ;;
    x86_64) archive=acky-mac-universal.zip ;;
    *) echo "不支持的架构：${machine}" >&2; exit 1 ;;
  esac
  destination=${ACKY_INSTALL_DIR:-/Applications}
  app="${destination}/acky.app"
  temporary=$(mktemp -d "${TMPDIR:-/tmp}/acky-download.XXXXXX")
  stage=''; backup=''
  privilege=(command)
  cleanup() {
    local result=$?
    trap - EXIT INT TERM
    set +e
    if [ "${installed}" = 0 ] && [ -n "${backup}" ] && "${privilege[@]}" test -e "${backup}/acky.app"; then
      "${privilege[@]}" rm -rf "${app}"
      "${privilege[@]}" mv "${backup}/acky.app" "${app}" || echo "恢复失败，旧版本保留在 ${backup}/acky.app" >&2
    fi
    [ -z "${stage}" ] || "${privilege[@]}" rm -rf "${stage}"
    # Keep a backup if restoration failed.
    if [ -n "${backup}" ] && ! "${privilege[@]}" test -e "${backup}/acky.app"; then "${privilege[@]}" rmdir "${backup}"; fi
    rm -rf "${temporary}"
    exit "${result}"
  }
  trap cleanup EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  echo "下载 ${archive}，并核对 SHA-256…"
  local expected actual
  local source_base version downloaded=0
  version=latest
  if [[ "$release_base" =~ /releases/download/(v[0-9]+\.[0-9]+\.[0-9]+)$ ]]; then version="${BASH_REMATCH[1]}"; fi
  sources=("$release_base")
  if [ -n "$cdn_origin" ]; then sources=("$cdn_origin/desktop/$version" "$release_base"); fi
  for source_base in "${sources[@]}"; do
    if ! curl --fail --silent --show-error --location --connect-timeout 15 --max-time 60 --proto '=https' --proto-redir '=https' \
      --output "${temporary}/checksum" "${source_base}/${archive}.sha256"; then continue; fi
    expected=$(awk 'NR == 1 {print $1}' "${temporary}/checksum")
    [[ "${expected}" =~ ^[0-9a-f]{64}$ ]] || continue
    if ! curl --fail --silent --show-error --location --connect-timeout 15 --max-time 3600 --proto '=https' --proto-redir '=https' \
      --output "${temporary}/${archive}" "${source_base}/${archive}"; then continue; fi
    actual=$(shasum -a 256 "${temporary}/${archive}"); actual=${actual%% *}
    if [ "${actual}" = "${expected}" ]; then downloaded=1; break; fi
  done
  [ "$downloaded" = 1 ] || { echo '下载或 SHA-256 校验失败，原应用未更改。' >&2; exit 1; }
  mkdir -p "${temporary}/unpack"
  ditto -x -k --noqtn --noextattr "${temporary}/${archive}" "${temporary}/unpack"
  [ -f "${temporary}/unpack/acky.app/Contents/Info.plist" ] || { echo '安装包中没有 acky.app。' >&2; exit 1; }
  codesign --verify --deep --strict "${temporary}/unpack/acky.app"
  if [ ! -w "${destination}" ]; then privilege=(sudo); "${privilege[@]}" -v; fi
  "${privilege[@]}" mkdir -p "${destination}"
  stage=$("${privilege[@]}" mktemp -d "${destination}/.acky-install.XXXXXX")
  "${privilege[@]}" ditto --noqtn --noextattr "${temporary}/unpack/acky.app" "${stage}/acky.app"
  "${privilege[@]}" xattr -dr com.apple.quarantine "${stage}/acky.app"
  # Never replace a running app. The one-line installer is also safe to run again after quitting acky.
  if pgrep -f "^${app}/Contents/MacOS/acky([[:space:]]|$)" >/dev/null; then
    echo '请先退出 acky，再重新执行安装命令。原应用未更改。' >&2; exit 1
  fi
  backup=$("${privilege[@]}" mktemp -d "${destination}/.acky-backup.XXXXXX")
  if [ -e "${app}" ]; then "${privilege[@]}" mv "${app}" "${backup}/acky.app"; fi
  "${privilege[@]}" mv "${stage}/acky.app" "${app}"
  "${privilege[@]}" xattr -dr com.apple.quarantine "${app}"
  open "${app}"
  installed=1
  "${privilege[@]}" rm -rf "${backup}"
  backup=''
  echo 'acky 已安装并打开。后续可直接在应用内更新。'
  exit 0
}
main "$@"
