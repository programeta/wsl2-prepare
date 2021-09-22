#!/bin/bash
USER=`whoami`

mkdir /home/$USER/.ssh
ssh-keygen -b 4096 -t rsa -f /home/$USER/.ssh/id_rsa -q -N ""
apt-get update
apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg |sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt-get update
apt install docker-ce net-tools -y
curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
mkdir /docker_projects
chown -R $USER:$USER /docker_projects
curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o /home/$USER/.git-completion.bash
ln -s /docker_projects /home/$USER/docker
usermod -G docker $USER
chown -R $USER:$USER /docker_projects
chown -R $USER:$USER /home/$USER
cat << EOF >> /home/$USER/.bashrc

cd /docker_projects
sudo service docker start

EOF
cat autocompletition.bashrc >> .bashrc

cat << EOF >> /etc/sudoers
$USER ALL=(ALL) NOPASSWD:ALL
EOF
