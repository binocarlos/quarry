#!/usr/bin/env bash
set -eo pipefail
export DEBIAN_FRONTEND=noninteractive
export QUARRY_REPO=${QUARRY_REPO:-"https://github.com/binocarlos/quarry.git"}

if ! which apt-get &>/dev/null
then
  echo "This installation script requires apt-get. For manual installation instructions, consult https://github.com/binocarlos/quarry ."
  exit 1
fi

apt-get update
apt-get install -y git make curl software-properties-common


[[ `lsb_release -sr` == "12.04" ]] && apt-get install -y python-software-properties

cd ~ && test -d quarry || git clone $QUARRY_REPO
cd quarry
git fetch origin

if [[ -n $QUARRY_BRANCH ]]; then
  git checkout origin/$QUARRY_BRANCH
elif [[ -n $QUARRY_TAG ]]; then
  git checkout $QUARRY_TAG
fi

make install

echo
echo "quarry is installed! Add a user from your development machine to push stacks - see:"
echo "  https://github.com/binocarlos/quarry"