#!/bin/bash

CURRENT_BRANCH=$(git symbolic-ref -q HEAD)
CURRENT_BRANCH=${CURRENT_BRANCH##refs/heads/}

case $CURRENT_BRANCH in
  user-test-[1-3])
    # Nothing
    ;;
  *)
    echo Unknown branch $CURRENT_BRANCH
    exit 1
    ;;
esac

DEST=git@heroku.com:govuk-licence-finder-${CURRENT_BRANCH#user-test-}.git

echo deploying $CURRENT_BRANCH to $DEST
git push $DEST ${CURRENT_BRANCH}:master
