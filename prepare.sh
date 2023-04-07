#!/bin/bash

# Regular Colors.
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
LightGreen='\033[1;32m'   # LightGreen
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White
Color_Off='\033[0m'       # Text Reset

# Resources.
checkStatusCode () {
  if [ $? -eq 0 ]
  then
    echo -e "\r\033[K${Blue}$2 ${White}[${Green}OK${White}]${Color_Off}"
  else
    echo -e "\r\033[K${Red}$2 ${White}[${Red}ERROR${White}]${Color_Off}"
    echo -e "${Red}Code: $1"
    exit $1
  fi
}

printInline () {
  echo -ne "${Yellow}$1...${Color_Off}"
}

echo -e "\n\n${White}#########################${Color_Off}"
echo -e "${White}#  WSL2-PREPARE SCRIPT  #${Color_Off}"
echo -e "${White}#                       #${Color_Off}"
echo -e "${White}#  oembunut - pgrandeg  #${Color_Off}"
echo -e "${White}# NTTDATA EMEAL 2023-04 #${Color_Off}"
echo -e "${White}#########################${Color_Off}\n\n"

# Script start.
START=`date +%s`

# Step 1.
TEXT="Update apt packages"
printInline "$TEXT"
apt-get update > /dev/null 2>&1
checkStatusCode 1 "$TEXT"

# Step 2.
TEXT="Install packages (apt-transport-https ca-certificates curl software-properties-common gnupg2)"
printInline "$TEXT"
apt install apt-transport-https ca-certificates curl software-properties-common gnupg2 -y > /dev/null 2>&1
checkStatusCode 2 "$TEXT"

# Step 3.
TEXT="Install docker repository to apt"
printInline "$TEXT"
. /etc/os-release > /dev/null 2>&1
curl -fsSL https://download.docker.com/linux/${ID}/gpg | sudo tee /etc/apt/trusted.gpg.d/docker.asc > /dev/null 2>&1
echo "deb [arch=amd64] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null 2>&1
checkStatusCode 3 "$TEXT"

# Step 4.
TEXT="Update apt packages"
printInline "$TEXT"
apt-get update > /dev/null 2>&1
checkStatusCode 4 "$TEXT"

# Step 5.
TEXT="Install packages (php8.1-cli php8.1-xml php8.1-curl php8.1-gd unzip make)"
printInline "$TEXT"
apt install php8.1-cli php8.1-xml php8.1-curl php8.1-gd unzip make -y > /dev/null 2>&1
checkStatusCode 5 "$TEXT"

# Step 6.
TEXT="Install docker-ce, net-tools and docker-compose"
printInline "$TEXT"
apt install docker-ce net-tools -y > /dev/null 2>&1
curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose > /dev/null 2>&1
chmod +x /usr/local/bin/docker-compose
checkStatusCode 6 "$TEXT"

# Step 7.
TEXT="Initialize /docker_projects tree folder"
printInline "$TEXT"
mkdir -p /docker_projects
chown -R dev:dev /docker_projects
curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o /home/dev/.git-completion.bash > /dev/null 2>&1
ln -s -f /docker_projects /home/dev/docker
checkStatusCode 7 "$TEXT"

# Step 8.
TEXT="Set and update user and groups permissions"
printInline "$TEXT"
usermod -G docker dev
mkdir -p /home/dev/.ssh
chown -R dev:dev /docker_projects
chown -R dev:dev /home/dev
checkStatusCode 8 "$TEXT"

# Step 9.
TEXT="Generate SSH keys"
printInline "$TEXT"
su -c 'ssh-keygen -b 4096 -t rsa -f /home/dev/.ssh/id_rsa -q -N ""' dev
checkStatusCode 9 "$TEXT"

# Step 10.
TEXT="Update user .bashrc file"
printInline "$TEXT"
cat << EOF >> /home/dev/.bashrc

cd /docker_projects
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo service docker start

EOF
cat autocompletition.bashrc >> .bashrc
checkStatusCode 10 "$TEXT"

# Step 11.
TEXT="Include current user in sudoers file"
printInline "$TEXT"
cat << EOF >> /etc/sudoers
dev ALL=(ALL) NOPASSWD:ALL
EOF
checkStatusCode 11 "$TEXT"

# Return script execution feedback to user.
END=`date +%s`
RUNTIME=$((END-START))
echo -e "${Cyan}\n\nSUCCESS! The docker profile has been succesfully installed in your WSL2 instance.${Color_Off}"
echo -e "${White}The installation took $RUNTIME seconds to run.${Color_Off}"
