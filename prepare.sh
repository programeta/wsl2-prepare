#!/bin/bash
mkdir /home/dev/.ssh
ssh-keygen -b 4096 -t rsa -f /home/dev/.ssh/id_rsa -q -N ""
apt-get update
apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg |sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt-get update
apt install docker-ce net-tools -y
curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
mkdir /docker_projects
chown -R dev:dev /docker_projects
curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o /home/dev/.git-completion.bash
ln -s /docker_projects /home/dev/docker
usermod -G docker dev
cat << EOF >> /home/dev/.bashrc

cd /docker_projects

sudo service docker start
EOF

cat << EOF >> /etc/sudoers
dev ALL=(ALL) NOPASSWD:ALL
EOF

