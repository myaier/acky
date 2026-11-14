#!/bin/bash
# First installation only. Published copies pin this URL to one immutable release.
set -euo pipefail
main() {
  local cdn_origin='https://cdn.acky.dev'
  local release_base='https://github.com/myaier/acky/releases/download/v0.5.1779'
  local machine archive
  # Bash 5 unwinds function locals before EXIT after errexit; rollback state must outlive main.
  temporary=''; destination=''; stage=''; staged=''; backup=''; backupApp=''; swapper=''; app=''; installed=0; replacement=0; restored=0
  [ "$(uname -s)" = Darwin ] || { echo '此安装方式只支持 macOS。' >&2; exit 1; }
  machine=$(uname -m)
  case "${machine}" in
    arm64) archive=acky-mac-arm64.zip ;;
    *) echo "不支持的架构：${machine}" >&2; exit 1 ;;
  esac
  destination=${ACKY_INSTALL_DIR:-/Applications}
  app="${destination}/acky.app"
  temporary=$(mktemp -d "${TMPDIR:-/tmp}/acky-download.XXXXXX")
  privilege=(command)
  cleanup() {
    local result=$?
    trap - EXIT INT TERM
    set +e
    if [ "${installed}" = 0 ] && [ "${replacement}" = 1 ] && [ -n "${backupApp}" ] && "${privilege[@]}" test -e "${backupApp}"; then
      if "${privilege[@]}" test -e "${app}"; then
        "${swapper}" "${app}" "${backupApp}" && restored=1 || echo "恢复失败，旧版本保留在 ${backupApp}" >&2
      else
        "${privilege[@]}" mv "${backupApp}" "${app}" && restored=1 || echo "恢复失败，旧版本保留在 ${backupApp}" >&2
      fi
    fi
    [ -z "${stage}" ] || "${privilege[@]}" rm -rf "${stage}" "${staged}"
    [ -z "${backup}" ] || "${privilege[@]}" rm -rf "${backup}"
    if [ "${installed}" = 1 ] || [ "${replacement}" = 0 ] || [ "${restored}" = 1 ]; then
      [ -z "${backupApp}" ] || "${privilege[@]}" rm -rf "${backupApp}"
    fi
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
  if [[ "${release_base}" =~ /releases/download/(v[0-9]+\.[0-9]+\.[0-9]+)$ ]]; then version="${BASH_REMATCH[1]}"; fi
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
  staged="${stage}.app"
  # The staged and installed bundles are siblings: cross-parent app renames can stall in macOS.
  "${privilege[@]}" ditto --noqtn --noextattr "${temporary}/unpack/acky.app" "${staged}"
  "${privilege[@]}" xattr -dr com.apple.quarantine "${staged}"
  swapper="${stage}/update-swap"
  "${privilege[@]}" cp "${staged}/Contents/Resources/update-swap" "${swapper}"
  "${privilege[@]}" chmod 755 "${swapper}"
  # Never replace a running app. The one-line installer is also safe to run again after quitting acky.
  if pgrep -f "^${app}/Contents/MacOS/acky([[:space:]]|$)" >/dev/null; then
    echo '请先退出 acky，再重新执行安装命令。原应用未更改。' >&2; exit 1
  fi
  backup=$("${privilege[@]}" mktemp -d "${destination}/.acky-backup.XXXXXX")
  backupApp="${backup}.app"
  if [ -e "${app}" ]; then
    "${privilege[@]}" cp -c -R "${app}" "${backupApp}"
    "${swapper}" "${app}" "${staged}"
  else
    "${privilege[@]}" mv "${staged}" "${app}"
  fi
  replacement=1
  "${privilege[@]}" xattr -dr com.apple.quarantine "${app}"
  open "${app}"
  installed=1
  "${privilege[@]}" rm -rf "${backup}" "${backupApp}"
  backup=''; backupApp=''
  echo 'acky 已安装并打开。后续可直接在应用内更新。'
  exit 0
}
main "$@"
