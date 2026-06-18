#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_NAME=${0##*/}
APPLY=0
TARGET_USER=${SUDO_USER:-${USER:-}}
TARGET_HOME=""
CLEANUP_SINCE=$(date '+%Y-%m-%d %H:%M:%S')

AI_PATTERN='kylin-ai|aiassistant|kyai|kytensor|recollect|kylin_ai|coreai|genai|vector-engine'

PRIMARY_PKGS=(
  kyai-data-management-service
  kylin-ai-document-qa-service
  kylin-ai-document-service
  kylin-ai-vector-engine
  kylin-ai-subsystem-plugin
  kylin-ai-subsystem-modelconfig
  kylin-ai-abstract-models
  kylin-ai-engine-plugins
  kylin-ai-python-env
  kylin-ai-subsystem
  kylin-ai-runtime
  kylin-ai-recollect-service
)

EXTENDED_SAFE_PKGS=(
  libkylin-ai-document-qa-service
  libkylin-ai-document-service
  libkylin-ai-recollect-client
  libkylin-ondevice-ai-engine-plugin
  libkylin-ondevice-embedding-engine
  libkylin-ondevice-nlp-engine
  libkylin-ondevice-traditional-ai-engine-plugin
  libkylin-ondevice-vision-engine
  kytensor-server
  kytensor-client
  kytensor-python
  kytensor-llm
  llm-backend
  onnxruntime-backend
  kyml
  libkyai-assistant0
  libkyai-business-framework
  libkyai-config0
  libkyai-depends
  libkysdk-genai-nlp0
  libkysdk-genai-vision0
)

MODEL_ENGINE_PKGS=(
  kylin-cn-clip-model
  kylin-gte-base-model
  kylin-paddle-ocr-model
  kylin-portrait-matting-model
  libkylin-baidu-ai-engine-plugin
  libkylin-baidu-nlp-engine
  libkylin-baidu-speech-engine
  libkylin-baidu-vision-engine
  libkylin-custom-ai-engine-plugin
  libkylin-custom-nlp-engine
  libkylin-deepseek-ai-engine-plugin
  libkylin-deepseek-nlp-engine
  libkylin-freetrial-ai-engine-plugin
  libkylin-freetrial-nlp-engine
  libkylin-qwen-ai-engine-plugin
  libkylin-qwen-nlp-engine
  libkylin-xunfei-ai-engine-plugin
  libkylin-xunfei-nlp-engine
  libkylin-xunfei-speech-engine
  libkylin-xunfei-vision-engine
)

ISOLATED_SAFE_PKGS=(
  libkylin-coreai-embedding
  libkysdk-coreai-speech0
  libkysdk-vector-engine-client
)

PROTECTED_AI_PKGS=(
  libkyai-data-management-client
  libkysdk-ai-common
  libkysdk-coreai-vision0
)

CORE_GUARD_PKGS=(
  peony
  peony-intelligent-data-management-service
  ukui-clipboard
  ukui-desktop-environment
  ukui-panel
  ukui-search
  ukui-widget-system-tray
  libukui-search2
)

SYSTEM_PATHS=(
  /etc/systemd/system/default.target.wants/kytensor.service
  /usr/etc/systemd/system/default.target.wants/kytensor.service
  /usr/etc/systemd/user/default.target.wants/kyai-data-management-service.service
  /usr/etc/systemd/user/default.target.wants/kylin-ai-document-qa-service.service
  /usr/etc/systemd/user/default.target.wants/kylin-ai-vector-engine.service
  /usr/etc/xdg/autostart/kylin-ai-runtime.desktop
  /usr/etc/xdg/autostart/kylin-aiassistant-autostart.desktop
  /etc/kylin-firewall/builtin_rules/Share-kytensor-apiserver.xml
  /etc/kylin-firewall/builtin_rules/kytensor-service.xml
  /etc/kylin-firewall/custom_rules/Share-kytensor-apiserver.xml
  /etc/kylin-firewall/custom_rules/kytensor-service.xml
  /usr/etc/kylin-firewall/builtin_rules/Share-kytensor-apiserver.xml
  /usr/etc/kylin-firewall/builtin_rules/kytensor-service.xml
  /usr/etc/kylin-firewall/custom_rules/Share-kytensor-apiserver.xml
  /usr/etc/kylin-firewall/custom_rules/kytensor-service.xml
  /usr/etc/kylin-ai
  /var/opt/appdata/kylin-ai
  /opt/system/resource/kylin/kylin-ai
  /opt/system/resource/kylin/kylin-ai-document-service
  /opt/system/resource/kylin/kylin-ai-python-env
  /opt/system/resource/kylin/kylin-ai-subsystem-plugin
  /opt/system/resource/kylin/kylin-ai-vector-engine
  /var/opt/system/resource/kylin/kylin-ai
  /var/opt/system/resource/kylin/kylin-ai-document-service
  /var/opt/system/resource/kylin/kylin-ai-python-env
  /var/opt/system/resource/kylin/kylin-ai-subsystem-plugin
  /var/opt/system/resource/kylin/kylin-ai-vector-engine
  /var/opt/kare-applications/shadow/upper/tmp/kylin-ai
  /var/opt/kare-applications/shadow/upper/tmp/kylin-aiassistant
  /var/opt/kare-applications/shadow/upper/usr/share/kylin-ai-python-env
  /var/opt/kare-applications/shadow/merge/tmp/kylin-ai
  /var/opt/kare-applications/shadow/merge/tmp/kylin-aiassistant
  /opt/kare-applications/shadow/upper/tmp/kylin-ai
  /opt/kare-applications/shadow/upper/tmp/kylin-aiassistant
  /opt/kare-applications/shadow/upper/usr/share/kylin-ai-python-env
)

usage() {
  cat <<EOF
Usage:
  $SCRIPT_NAME [--dry-run] [--apply] [--user USER]

Default mode is --dry-run. Use --apply as root in Kylin maintain mode to remove
Kylin AI packages, Kaiming app data, dead service/autostart entries, and known
unowned residues.

Examples:
  $SCRIPT_NAME --dry-run --user zengjianqi
  sudo $SCRIPT_NAME --apply --user zengjianqi
EOF
}

log() {
  printf '%s\n' "$*"
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

run_cmd() {
  if (( APPLY )); then
    log "+ $*"
    "$@"
  else
    log "[dry-run] $*"
  fi
}

while (($#)); do
  case "$1" in
    --dry-run)
      APPLY=0
      ;;
    --apply)
      APPLY=1
      ;;
    --user)
      shift
      [[ $# -gt 0 ]] || die "--user requires a value"
      TARGET_USER=$1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
  shift
done

if [[ -z "$TARGET_USER" || "$TARGET_USER" == root ]]; then
  TARGET_USER=$(logname 2>/dev/null || true)
fi
[[ -n "$TARGET_USER" && "$TARGET_USER" != root ]] || die "cannot determine target desktop user; pass --user USER"

TARGET_HOME=$(getent passwd "$TARGET_USER" | awk -F: '{print $6}')
[[ -n "$TARGET_HOME" && -d "$TARGET_HOME" ]] || die "cannot determine home directory for user $TARGET_USER"

USER_PATHS=(
  "$TARGET_HOME/.config/autostart/kylin-aiassistant-autostart.desktop"
  "$TARGET_HOME/.var/app/cn.kylin.kylin-aiassistant"
  "$TARGET_HOME/.cache/kylin-aiassistant"
  "$TARGET_HOME/.config/kylin-ai"
  "$TARGET_HOME/.config/kylin-ai-runtime"
  "$TARGET_HOME/.config/kylin-ai-subsystem-modelconfig"
  "$TARGET_HOME/.config/kylin-aiassistant"
  "$TARGET_HOME/.local/kylin-ai-business-framework"
  "$TARGET_HOME/.local/share/kylin-ai-vector-engine"
  "$TARGET_HOME/.log/kylin-ai-runtime"
  "$TARGET_HOME/.log/kylin-aiassistant.log"
  "$TARGET_HOME/文档/kylin-aiassistant"
  "$TARGET_HOME/Documents/kylin-aiassistant"
)

require_apply_preconditions() {
  if (( ! APPLY )); then
    return
  fi
  [[ $(id -u) -eq 0 ]] || die "--apply must run as root, for example: sudo $0 --apply --user $TARGET_USER"
  have_cmd mm-cli || die "mm-cli not found; cannot verify Kylin maintain mode"

  local mode
  mode=$(mm-cli -s 2>&1 || true)
  log "mm-cli -s: $mode"
  if ! grep -qi 'maintain' <<<"$mode"; then
    die "system is not in maintain mode; run 'sudo mm-cli -o', reboot, then rerun this script"
  fi
}

is_installed_pkg() {
  local pkg=$1
  local status
  status=$(dpkg-query -W -f='${db:Status-Abbrev}' "$pkg" 2>/dev/null || true)
  [[ "$status" == ii* || "$status" == rc* ]]
}

collect_installed_candidates() {
  local pkg
  INSTALLED_CANDIDATES=()
  for pkg in "${PRIMARY_PKGS[@]}" "${EXTENDED_SAFE_PKGS[@]}" "${MODEL_ENGINE_PKGS[@]}" "${ISOLATED_SAFE_PKGS[@]}"; do
    if is_installed_pkg "$pkg"; then
      INSTALLED_CANDIDATES+=("$pkg")
    fi
  done
}

simulate_package_purge() {
  if ((${#INSTALLED_CANDIDATES[@]} == 0)); then
    log "No removable Kylin AI dpkg packages found."
    return
  fi

  have_cmd apt-get || die "apt-get not found"
  local tmp guard
  tmp=$(mktemp)
  if ! apt-get -s purge "${INSTALLED_CANDIDATES[@]}" >"$tmp" 2>&1; then
    cat "$tmp" >&2
    rm -f "$tmp"
    die "apt purge simulation failed"
  fi

  for guard in "${CORE_GUARD_PKGS[@]}"; do
    if grep -Eq "^(Remv|Purg) ${guard}([ :]|$)" "$tmp"; then
      cat "$tmp" >&2
      rm -f "$tmp"
      die "apt simulation would remove protected desktop package: $guard"
    fi
  done

  log "Package purge simulation passed."
  grep -E '^(Remv|Purg) ' "$tmp" || true
  rm -f "$tmp"
}

purge_packages() {
  if ((${#INSTALLED_CANDIDATES[@]} == 0)); then
    return
  fi
  run_cmd apt-get purge -y "${INSTALLED_CANDIDATES[@]}"
}

remove_kaiming_aiassistant() {
  local kaiming=/opt/kaiming-tools/bin/kaiming
  [[ -x "$kaiming" ]] || return 0
  if "$kaiming" list 2>/dev/null | grep -q 'cn\.kylin\.kylin-aiassistant'; then
    run_cmd "$kaiming" uninstall -y --delete-data cn.kylin.kylin-aiassistant
  else
    log "Kaiming AI assistant app is not listed."
  fi
}

kill_ai_processes() {
  local pids=()
  local pid comm args
  while read -r pid comm args; do
    [[ -n "${pid:-}" ]] || continue
    [[ "$pid" == "$$" || "$pid" == "$PPID" ]] && continue
    [[ "$args" == *"$SCRIPT_NAME"* ]] && continue
    pids+=("$pid")
  done < <(ps -eo pid=,comm=,args= | awk -v pat="$AI_PATTERN" '
    { line=tolower($0) }
    line ~ pat && line !~ /awk -v pat/ { pid=$1; comm=$2; $1=""; $2=""; sub(/^  */, "", $0); print pid, comm, $0 }
  ')

  if ((${#pids[@]} == 0)); then
    log "No running Kylin AI processes found."
    return
  fi
  run_cmd kill "${pids[@]}"
}

is_dpkg_owned() {
  local path=$1
  dpkg -S "$path" >/dev/null 2>&1
}

remove_user_path() {
  local path=$1
  [[ -e "$path" || -L "$path" ]] || return 0
  run_cmd rm -rf -- "$path"
}

remove_unowned_system_path() {
  local path=$1
  [[ -e "$path" || -L "$path" ]] || return 0
  if is_dpkg_owned "$path"; then
    log "Skip package-owned path: $path"
    return 0
  fi
  run_cmd rm -rf -- "$path"
}

cleanup_paths() {
  local path
  for path in "${USER_PATHS[@]}"; do
    remove_user_path "$path"
  done
  for path in "${SYSTEM_PATHS[@]}"; do
    remove_unowned_system_path "$path"
  done
}

cleanup_memorymap_box() {
  have_cmd boxadm || return 0
  if ! boxadm -l 2>/dev/null | grep -Eq '^kylin-ai-memorymap([[:space:]]|$)'; then
    log "No kylin-ai-memorymap box entry found."
    return 0
  fi
  run_cmd boxadm -r kylin-ai-memorymap
}

reload_systemd() {
  run_cmd systemctl daemon-reload
  run_cmd systemctl reset-failed

  if have_cmd runuser; then
    if (( APPLY )); then
      runuser -u "$TARGET_USER" -- systemctl --user daemon-reload 2>/dev/null || true
      runuser -u "$TARGET_USER" -- systemctl --user reset-failed 2>/dev/null || true
    else
      log "[dry-run] runuser -u $TARGET_USER -- systemctl --user daemon-reload"
      log "[dry-run] runuser -u $TARGET_USER -- systemctl --user reset-failed"
    fi
  fi
}

verify_state() {
  log
  log "Verification snapshot:"
  log "-- processes"
  ps -ef | grep -Ei "$AI_PATTERN" | grep -Ev "grep|$SCRIPT_NAME" || true

  log "-- failed system units"
  systemctl --failed --no-pager || true

  log "-- failed user units"
  if have_cmd runuser; then
    runuser -u "$TARGET_USER" -- systemctl --user --failed --no-pager 2>/dev/null || true
  fi

  log "-- remaining AI packages"
  dpkg-query -W -f='${db:Status-Abbrev} ${binary:Package}\t${Version}\n' \
    "${PRIMARY_PKGS[@]}" "${EXTENDED_SAFE_PKGS[@]}" "${MODEL_ENGINE_PKGS[@]}" "${ISOLATED_SAFE_PKGS[@]}" "${PROTECTED_AI_PKGS[@]}" \
    2>/dev/null | grep -E '^(ii|rc) ' || true

  log "-- AI commands still resolvable"
  command -v kyai-data-management-service kylin-ai-document-qa-service kylin-ai-vector-engine kylin-ai-runtime kylin-aiassistant kytensor 2>/dev/null || true

  log "-- startup/service references"
  find /etc/xdg/autostart /usr/etc/xdg/autostart /etc/systemd /usr/etc/systemd /usr/lib/systemd "$TARGET_HOME/.config/systemd" \
    \( -xtype l -o -type f \) 2>/dev/null | grep -Ei "$AI_PATTERN" || true

  log "-- journal since cleanup start ($CLEANUP_SINCE)"
  journalctl -b --since "$CLEANUP_SINCE" --no-pager 2>/dev/null | grep -Ei "Scheduled restart job|203/EXEC|not found|$AI_PATTERN" || true
}

main() {
  require_apply_preconditions

  log "Mode: $([[ $APPLY -eq 1 ]] && printf apply || printf dry-run)"
  log "Target user: $TARGET_USER"
  log "Target home: $TARGET_HOME"
  log

  collect_installed_candidates
  simulate_package_purge

  remove_kaiming_aiassistant
  kill_ai_processes
  purge_packages
  cleanup_paths
  cleanup_memorymap_box
  reload_systemd
  verify_state

  log
  log "Protected AI-named packages intentionally kept unless the desktop dependency chain changes:"
  printf '  %s\n' "${PROTECTED_AI_PKGS[@]}"
  log
  if (( APPLY )); then
    log "Done. Exit maintain mode after reviewing results: sudo mm-cli -c -a"
    log "Then reboot."
  else
    log "Dry-run complete. Re-run with --apply as root in maintain mode to execute."
  fi
}

main "$@"
