#!/bin/sh

set -xe

TEXT_LINT_BIN=/textlint/node_modules/.bin/textlint

cd "$GITHUB_WORKSPACE" || true

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

ls -la

"$TEXT_LINT_BIN" "${INPUT_TEXTLINT_FLAGS}"

"$TEXT_LINT_BIN" -f checkstyle "${INPUT_TEXTLINT_FLAGS}"    \
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
  "$TEXT_LINT_BIN" --fix "${INPUT_TEXTLINT_FLAGS:-.}" || true

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
