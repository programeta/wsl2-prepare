#!/bin/bash
apt-get update
apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg |sudo gpg --export
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu jammy stable"
apt-get update
apt install php8.1-cli php8.1-xml php8.1-curl php8.1-gd unzip make -y
apt install docker-ce net-tools -y
curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
mkdir /docker_projects
chown -R dev:dev /docker_projects
curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o /home/dev/.git-completion.bash
ln -s /docker_projects /home/dev/docker
usermod -G docker dev
mkdir /home/dev/.ssh
chown -R dev:dev /docker_projects
chown -R dev:dev /home/dev
su -c 'ssh-keygen -b 4096 -t rsa -f /home/dev/.ssh/id_rsa -q -N ""' dev

cat << EOF >> /home/dev/.bashrc

cd /docker_projects
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo service docker start

EOF
cat autocompletition.bashrc >> .bashrc

cat << EOF >> /etc/sudoers
dev ALL=(ALL) NOPASSWD:ALL
EOF
