#!/bin/sh

cd "$GITHUB_WORKSPACE"

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

npm ls textlint

echo exitcode $?

# setup and check.
if npm ls textlint &> /dev/null; then
  # pass
  :
else
  npm ci
fi

npm ls textlint

echo exitcode $?

if npm ls textlint &> /dev/null; then
  npx textlint --version
else
  echo This repository was not configured for textlint, process done.
  exit 1
fi

npx textlint -f checkstyle "${INPUT_TEXTLINT_FLAGS:-.}"            \
      | reviewdog -f=checkstyle -name="textlint"                   \
                  -reporter="${INPUT_REPORTER:-'github-pr-check'}" \
                  -level="${INPUT_LEVEL:-'error'}"

# EOF
