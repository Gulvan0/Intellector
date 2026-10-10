#!/usr/bin/env bash
#
# Rebuilds the `intellector` branch of the haxeui-core fork from scratch:
# haxeui/haxeui-core's master plus one squashed commit per open upstream PR opened from the fork.
# A PR that got merged upstream drops out on the next run; the others are kept.
# Workflow and rules: knowledge/haxeui_pending.md.
#
# Usage: scripts/sync_haxeui_core.sh [--no-push]
#   --no-push   rebuild the local branch only
#
# Environment:
#   HAXEUI_CORE_DIR   the fork's checkout (default: haxelib's haxeui-core dev/git dir)
#
# Needs git and an authenticated gh. Run from Git Bash on Windows.

set -euo pipefail

UPSTREAM_REPO="haxeui/haxeui-core"
FORK_OWNER="Gulvan0"
FORK_URL="https://github.com/$FORK_OWNER/haxeui-core.git"
UPSTREAM_URL="https://github.com/$UPSTREAM_REPO.git"
BRANCH="intellector"
WORK_BRANCH="$BRANCH-rebuild"

push=true
for arg in "$@"; do
    case "$arg" in
        --no-push) push=false ;;
        *) echo "Unknown argument: $arg" >&2; exit 2 ;;
    esac
done

repo="${HAXEUI_CORE_DIR:-$(haxelib libpath haxeui-core)}"
cd "$repo"

if [ -n "$(git status --porcelain)" ]; then
    echo "Uncommitted changes in $repo - the checkout must stay clean. Aborting." >&2
    git status --short >&2
    exit 1
fi

git remote get-url upstream >/dev/null 2>&1 || git remote add upstream "$UPSTREAM_URL"
[ "$(git remote get-url origin)" = "$FORK_URL" ] || echo "Warning: origin is $(git remote get-url origin), expected $FORK_URL" >&2

git fetch -q upstream
git fetch -q --prune origin

# number<TAB>head branch<TAB>title, oldest first
prs=$(gh pr list -R "$UPSTREAM_REPO" --author "$FORK_OWNER" --state open --limit 100 \
    --json number,title,headRefName,headRepositoryOwner \
    --jq "[.[] | select(.headRepositoryOwner.login == \"$FORK_OWNER\")] | sort_by(.number) | .[] | \"\(.number)\t\(.headRefName)\t\(.title)\"")

previous_branch=$(git rev-parse --abbrev-ref HEAD)
git checkout -q -B "$WORK_BRANCH" upstream/master

applied=()
while IFS=$'\t' read -r number head title; do
    [ -z "$number" ] && continue

    if ! git merge --squash -q "origin/$head" >/dev/null 2>&1; then
        echo "PR #$number ($head) doesn't merge cleanly onto upstream/master - rebase that PR branch first." >&2
        git merge --abort 2>/dev/null || git reset -q --hard
        git checkout -q "$previous_branch"
        git branch -q -D "$WORK_BRANCH"
        exit 1
    fi

    if git diff --cached --quiet; then
        echo "PR #$number ($head): nothing left to apply, skipped"
        continue
    fi

    git commit -q -m "PR #$number: $title" -m "https://github.com/$UPSTREAM_REPO/pull/$number (fork branch $head)"
    applied+=("#$number")
done <<< "$prs"

git checkout -q -B "$BRANCH" "$WORK_BRANCH"
git branch -q -D "$WORK_BRANCH"

echo "$BRANCH = upstream/master ($(git rev-parse --short upstream/master)) + ${#applied[@]} pending PR(s): ${applied[*]:-none}"
git log --oneline "upstream/master..$BRANCH"

if $push; then
    git push -q --force-with-lease origin "$BRANCH"
    git branch -q --set-upstream-to="origin/$BRANCH" "$BRANCH"
    echo "Pushed to origin/$BRANCH"
fi
