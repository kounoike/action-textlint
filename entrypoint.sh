#!/bin/sh

cd "$GITHUB_WORKSPACE" || true

# setup and check.
if [ -x "./node_modules/.bin/textlint"  ]; then
  # pass
  :
elif [ -f "./package.json" ] && grep -q "textlint" "./package.json"; then
  npm ci
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

"$TEXTLINT_BIN" --version

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

"$TEXTLINT_BIN" -f checkstyle "${INPUT_TEXTLINT_FLAGS}"    \
      | reviewdog -f=checkstyle                         \
        -name="${INPUT_TOOL_NAME}"                      \
        -reporter="${INPUT_REPORTER:-github-pr-review}" \
        -filter-mode="${INPUT_FILTER_MODE}"             \
        -fail-on-error="${INPUT_FAIL_ON_ERROR}"         \
        -level="${INPUT_LEVEL}"                         \
        ${INPUT_REVIEWDOG_FLAGS}

# github-pr-review only diff adding
if [ "${INPUT_REPORTER}" = "github-pr-review" ]; then
  # fix
  "$TEXTLINT_BIN" --fix "${INPUT_TEXTLINT_FLAGS:-.}" || true

  TMPFILE=$(mktemp)
  git diff >"${TMPFILE}"

  reviewdog                        \
    -name="textlint-fix"           \
    -f=diff                        \
    -f.diff.strip=1                \
    -name="${INPUT_TOOL_NAME}-fix" \
    -reporter="github-pr-review"   \
    -filter-mode="diff_context"    \
    -level="${INPUT_LEVEL}"        \
    ${INPUT_REVIEWDOG_FLAGS} < "${TMPFILE}"

  git restore . || true
  rm -f "${TMPFILE}"
fi

# EOF
