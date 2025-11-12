#!/usr/bin/env bash
set -euo pipefail

# Change these via env vars when needed.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${ENV_FILE:-$DEFAULT_REPO_DIR/.env}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

REPO_DIR="${REPO_DIR:-$DEFAULT_REPO_DIR}"
LOG_DIR="${LOG_DIR:-$REPO_DIR/logs}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/git-auto-pull.log}"
BRANCH="${BRANCH:-}"
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
SLACK_CHANNEL="${SLACK_CHANNEL:-}"
SLACK_USERNAME="${SLACK_USERNAME:-}"

mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S%z')" "$*"
}

json_escape() {
  local s="${1//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  printf '%s' "$s"
}

notify_slack() {
  [[ -z "$SLACK_WEBHOOK_URL" ]] && return
  local message="$1"
  local payload
  payload=$(printf '{"text":"%s"' "$(json_escape "$message")")
  if [[ -n "$SLACK_CHANNEL" ]]; then
    payload+=$(printf ',"channel":"%s"' "$(json_escape "$SLACK_CHANNEL")")
  fi
  if [[ -n "$SLACK_USERNAME" ]]; then
    payload+=$(printf ',"username":"%s"' "$(json_escape "$SLACK_USERNAME")")
  fi
  payload+='}'
  if ! curl -sS -X POST -H 'Content-type: application/json' -d "$payload" "$SLACK_WEBHOOK_URL" >/dev/null 2>&1; then
    log "WARN: failed to send Slack notification"
  fi
}

cleanup() {
  local exit_code=$1
  if [[ $exit_code -eq 0 ]]; then
    log "git-auto-pull finished successfully"
  else
    log "git-auto-pull failed with exit code $exit_code"
    local host
    host="$(hostname -f 2>/dev/null || hostname || echo 'unknown-host')"
    notify_slack "git-auto-pull failed on ${host} (repo: ${REPO_DIR}, branch: ${BRANCH:-unknown}). Exit ${exit_code}. See ${LOG_FILE}."
  fi
}

trap 'cleanup $?' EXIT

exec >>"$LOG_FILE" 2>&1

log "git-auto-pull start"

if ! cd "$REPO_DIR"; then
  log "ERROR: failed to cd into $REPO_DIR"
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  log "ERROR: $REPO_DIR is not a git repository"
  exit 1
fi

if [[ -z "$BRANCH" ]]; then
  BRANCH="$(git rev-parse --abbrev-ref HEAD)"
fi

if [[ -n "$(git status --porcelain --ignore-submodules)" ]]; then
  log "Local changes detected. Skipping pull to avoid overwriting work."
  exit 0
fi

log "Fetching and fast-forwarding branch '$BRANCH'"
git fetch origin "$BRANCH" --prune
git checkout "$BRANCH" >/dev/null 2>&1 || git switch "$BRANCH" >/dev/null 2>&1
git pull --ff-only origin "$BRANCH"

if [[ -f ".gitmodules" ]]; then
  log "Syncing git submodule URLs"
  git submodule sync --recursive
  log "Updating git submodules to recorded revisions"
  git submodule update --init --recursive

  if submodule_keys=$(git config --file .gitmodules --name-only --get-regexp '^submodule\..*\.path$' 2>/dev/null); then
    log "Fast-forwarding git submodules to their tracked branches"
    while IFS= read -r key; do
      [[ -z "$key" ]] && continue
      name="${key#submodule.}"
      name="${name%.path}"
      path="$(git config --file .gitmodules --get "$key" 2>/dev/null || true)"
      branch="$(git config --file .gitmodules --get "submodule.${name}.branch" 2>/dev/null || echo main)"
      if [[ -z "$path" || ! -d "$path" ]]; then
        log "WARN: submodule '$name' path '$path' missing; skipping fast-forward"
        continue
      fi
      log "Updating submodule '$name' at '$path' (branch '$branch')"
      if ! git -C "$path" fetch origin "$branch" --prune >/dev/null 2>&1; then
        log "WARN: failed to fetch origin/$branch for submodule '$name'"
        continue
      fi
      if ! git -C "$path" checkout "$branch" >/dev/null 2>&1 && \
         ! git -C "$path" switch "$branch" >/dev/null 2>&1; then
        log "WARN: failed to switch submodule '$name' to branch '$branch'"
        continue
      fi
      if ! git -C "$path" pull --ff-only origin "$branch" >/dev/null 2>&1; then
        log "WARN: failed to fast-forward submodule '$name' to origin/$branch"
        continue
      fi
      log "Submodule '$name' fast-forwarded to origin/$branch"
    done <<<"$submodule_keys"
  fi
fi
