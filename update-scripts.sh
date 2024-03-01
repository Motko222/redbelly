#!/bin/bash

FOLDER=$(echo $(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd) | awk -F/ '{print $NF}')

cd ~/scripts/$FOLDER
git stash push --include-untracked
git pull
chmod +x *.sh
