#!/bin/bash

set -e


SOURCE="https://gitlab.com/hagezi/mirror.git"


echo "================================"
echo "Backup source:"
echo "$SOURCE"
echo "================================"



mkdir work

cd work


git init



git remote add upstream "$SOURCE"



git remote add origin \
"https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"



echo "Fetching upstream..."

git fetch upstream



echo "Pushing branches..."



for branch in $(git branch -r | grep upstream | sed 's#upstream/##')
do

    echo "Sync branch: $branch"

    git push origin \
    "refs/remotes/upstream/$branch:refs/heads/$branch" || true

done



echo "Pushing tags..."

git push origin --tags || true



echo "Backup complete"
