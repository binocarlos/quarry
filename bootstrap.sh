set -e
export DEBIAN_FRONTEND=noninteractive
export QUARRY_REPO=${QUARRY_REPO:-"https://github.com/binocarlos/quarry.git"}

apt-get update
apt-get install -y git make curl software-properties-common

cd ~ && test -d quarry || git clone $QUARRY_REPO
make all

#echo
#echo "Be sure to upload a public key for your user:"
#echo "  cat ~/.ssh/id_rsa.pub | ssh root@$HOSTNAME \"gitreceive upload-key progrium\""
