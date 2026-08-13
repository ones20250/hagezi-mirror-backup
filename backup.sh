#!/bin/bash

set -e


SOURCE="https://gitlab.com/hagezi/mirror.git"


echo "Clone source repository"


rm -rf repo


git clone --bare "$SOURCE" repo


cd repo


git remote add backup \
"https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"



echo "Detect branches"


for branch in $(git for-each-ref --format='%(refname:short)' refs/heads/)
do

    echo "Push branch: $branch"

    git push backup \
    "refs/heads/$branch:refs/heads/$branch"

done



echo "Push tags"


git push backup --tags



echo "Backup finished"
