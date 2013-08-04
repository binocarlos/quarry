#
# this is based on the dokku bootstrap script - https://github.com/progrium/dokku/blob/master/bootstrap.sh
set -e
export DEBIAN_FRONTEND=noninteractive
export QUARRY_REPO=${QUARRY_REPO:-"https://github.com/binocarlos/quarry.git"}
apt-get update
apt-get install -y git make curl

#cd ~ && test -d quarry || git clone $QUARRY_REPO
#cd quarry && test $QUARRY_BRANCH && git checkout origin/$QUARRY_BRANCH || true
#make all

#echo
#echo "Be sure to upload a public key for your user:"
#echo "  cat ~/.ssh/id_rsa.pub | ssh root@$HOSTNAME \"gitreceive upload-key progrium\""