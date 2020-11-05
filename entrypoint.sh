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

pwd
ls -a
(git diff --name-only HEAD^ | xargs "$TEXTLINT_BIN" -f @kounoike/textlint-formatter-rdjsonl "${INPUT_TEXTLINT_FLAGS}") | tee rd.jsonl
cat rd.jsonl \
      | reviewdog -f=rdjsonl                            \
        -name="${INPUT_TOOL_NAME}"                      \
        -reporter="${INPUT_REPORTER:-github-pr-review}" \
        -filter-mode="${INPUT_FILTER_MODE}"             \
        -fail-on-error="${INPUT_FAIL_ON_ERROR}"         \
        -level="${INPUT_LEVEL}"                         \
        ${INPUT_REVIEWDOG_FLAGS} || exit $?

# EOF
