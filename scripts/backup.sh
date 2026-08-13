#!/usr/bin/env bash
set -euo pipefail

CONFIG="config/repos.yml"
BACKUP_REPO="${GITHUB_REPOSITORY:-}"
TOKEN="${GITHUB_TOKEN:-}"
BACKUP_URL="https://x-access-token:${TOKEN}@github.com/${BACKUP_REPO}.git"

log() { echo "[backup] $*"; }

[ -n "$BACKUP_REPO" ] || { echo "[backup] ERROR: GITHUB_REPOSITORY not set"; exit 1; }
[ -n "$TOKEN" ]       || { echo "[backup] ERROR: GITHUB_TOKEN not set"; exit 1; }
[ -f "$CONFIG" ]      || { echo "[backup] ERROR: missing $CONFIG"; exit 1; }

sync_repo() {
  local name="$1" source="$2"
  log "== $name <= $source"

  # 1. Probe upstream first. If the source is gone (deleted / unreachable),
  #    skip it entirely and never touch the local backup.
  local upstream_info
  if ! upstream_info=$(git ls-remote --symref "$source" HEAD 2>/dev/null); then
    log "!! upstream unavailable, skipped (backup untouched): $source"
    return 0
  fi

  local default_branch sha
  default_branch=$(printf '%s\n' "$upstream_info" | awk '$1=="ref:" { split($2, a, "/"); print a[3]; exit }')
  sha=$(printf '%s\n' "$upstream_info" | awk 'NR==2 { print $1 }')
  [ -n "$default_branch" ] || default_branch="master"

  # 2. No-change check: compare against the last synced SHA we already hold.
  local synced
  synced=$(git ls-remote "$BACKUP_URL" "refs/heads/upstream/$name/$default_branch" 2>/dev/null | awk 'NR==1 { print $1 }' || true)
  if [ -n "$synced" ] && [ "$synced" = "$sha" ]; then
    log "no changes ($default_branch @ ${sha:0:7}), skipped"
    return 0
  fi
  log "change detected: upstream=${sha:0:7} current=${synced:0:7}"

  # 3. Full mirror sync into a per-source namespace.
  #    --force follows upstream updates, but never --prune: deleted upstream
  #    refs and deleted upstream repo are both preserved in our backup.
  local tmp
  tmp=$(mktemp -d)
  log "cloning mirror..."
  git clone --mirror "$source" "$tmp/mirror.git" 2>/dev/null
  git -C "$tmp/mirror.git" remote add backup "$BACKUP_URL"
  log "pushing branches -> refs/heads/upstream/$name/*"
  git -C "$tmp/mirror.git" push backup --force "refs/heads/*:refs/heads/upstream/$name/*"
  log "pushing tags -> refs/tags/upstream/$name/*"
  git -C "$tmp/mirror.git" push backup --force "refs/tags/*:refs/tags/upstream/$name/*"
  rm -rf "$tmp"
  log "synced OK"
}

parse_config() {
  awk '
    /^[[:space:]]*-[[:space:]]*name:/   { name=$3 }
    /^[[:space:]]*source:/              { if (name != "") print name "\t" $2; name="" }
  ' "$CONFIG"
}

ran_any=0
while IFS=$'\t' read -r name source; do
  [ -n "$name" ] || continue
  sync_repo "$name" "$source"
  ran_any=1
done < <(parse_config)

if [ "$ran_any" -eq 1 ]; then
  log "done"
else
  log "no repositories configured in $CONFIG"
  exit 1
fi
