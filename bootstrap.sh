set -e
export DEBIAN_FRONTEND=noninteractive
export QUARRY_REPO=${QUARRY_REPO:-"https://github.com/binocarlos/quarry.git"}
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

apt-get update
apt-get install -y git make curl software-properties-common

# this is for annoying locale issue on new DO servers
locale-gen en_US.UTF-8
dpkg-reconfigure locales

cd ~ && test -d quarry || git clone $QUARRY_REPO
cd ~/quarry && make all

#echo
#echo "Be sure to upload a public key for your user:"
#echo "  cat ~/.ssh/id_rsa.pub | ssh root@$HOSTNAME \"gitreceive upload-key progrium\""
