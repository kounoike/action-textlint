#!/bin/sh

set -x

cd "$GITHUB_WORKSPACE" || true

# setup and check.
if [ -x "./node_modules/.bin/textlint"  ]; then
  # pass
  :
elif [ -f "./package.json" ] && grep -q "textlint" "./package.json"; then
  npm ci
  npm ls @kounoike/textlint-formatter-rdjsonl || npm install @kounoike/textlint-formatter-rdjsonl
fi

if [ -x "./node_modules/.bin/textlint"  ]; then
  TEXTLINT_BIN="$(pwd)/node_modules/.bin/textlint"
else
  echo "This repository was not configured for textlint, using pre-installed textlint"
  TEXTLINT_BIN=/textlint/node_modules/.bin/textlint
  TARGET_TEXTLINTRC="$GITHUB_WORKSPACE/.textlintrc"

  if [ -f "${TARGET_TEXTLINTRC}" ]; then
    (cd /textlint; node configloader.js | xargs npm install)
  fi
fi

echo -n "textlint version: "
"$TEXTLINT_BIN" --version

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"
BEFORE_SHA=$(jq -r '.pull_requests[0].base.sha' $GITHUB_EVENT_PATH)

git fetch $(jq -r '.pull_requests[0].base.repo.url' $GITHUB_EVENT_PATH) 7a778a875c69f09d99e1ffc27c3a7f95d152beef

(git diff --name-only "${BEFORE_SHA}" | xargs "$TEXTLINT_BIN" -f @kounoike/textlint-formatter-rdjsonl "${INPUT_TEXTLINT_FLAGS}") | tee rd.jsonl
cat rd.jsonl \
      | reviewdog -f=rdjsonl                            \
        -name="${INPUT_TOOL_NAME}"                      \
        -reporter="${INPUT_REPORTER:-github-pr-review}" \
        -filter-mode="${INPUT_FILTER_MODE}"             \
        -fail-on-error="${INPUT_FAIL_ON_ERROR}"         \
        -level="${INPUT_LEVEL}"                         \
        ${INPUT_REVIEWDOG_FLAGS} || exit $?

# EOF
