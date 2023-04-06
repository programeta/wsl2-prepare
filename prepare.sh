#!/bin/bash

USER=`whoami`

apt-get update
apt install apt-transport-https ca-certificates curl software-properties-common gnupg2 -y
. /etc/os-release
curl -fsSL https://download.docker.com/linux/${ID}/gpg | sudo tee /etc/apt/trusted.gpg.d/docker.asc
echo "deb [arch=amd64] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list
apt-get update
apt install php8.1-cli php8.1-xml php8.1-curl php8.1-gd unzip make -y
apt install docker-ce net-tools -y
curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
mkdir /docker_projects
chown -R $USER:$USER /docker_projects
curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o /home/$USER/.git-completion.bash
ln -s /docker_projects /home/$USER/docker
usermod -G docker $USER
mkdir /home/$USER/.ssh
chown -R $USER:$USER /docker_projects
chown -R $USER:$USER /home/$USER
su -c 'ssh-keygen -b 4096 -t rsa -f /home/$USER/.ssh/id_rsa -q -N ""' $USER

cat << EOF >> /home/$USER/.bashrc

cd /docker_projects
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo service docker start

EOF
cat autocompletition.bashrc >> .bashrc

cat << EOF >> /etc/sudoers
$USER ALL=(ALL) NOPASSWD:ALL
EOF