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

execute () {
  
  TEXT=$1
  ERRORCODE="$2"
  shift 2
  COMMANDS=$@

  printInline "$TEXT"
  for ARG in "${COMMANDS[@]}"; do
    eval $ARG
    if [ $? -ne 0 ]
    then
      echo -e "\r\033[K${Red}$TEXT ${White}[${Red}ERROR${White}]${Color_Off}"
      echo -e "${Red}Code: $ERRORCODE"
      exit $ERRORCODE
    fi
  done
  checkStatusCode $ERRORCODE "$TEXT"
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
COMMANDS=("apt-get update > /dev/null 2>&1")
execute "Update apt packages" 1 $COMMANDS

# Step 2.
COMMANDS=("apt install apt-transport-https ca-certificates curl software-properties-common gnupg2 -y > /dev/null 2>&1")
execute "Install packages (apt-transport-https ca-certificates curl software-properties-common gnupg2)" 2 $COMMANDS

# Step 3.
COMMANDS=(
  '. /etc/os-release > /dev/null 2>&1'
  'curl -fsSL https://download.docker.com/linux/${ID}/gpg | sudo tee /etc/apt/trusted.gpg.d/docker.asc > /dev/null 2>&1'
  'echo "deb [arch=amd64] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null 2>&1'
)
execute "Install docker repository to apt" 3 $COMMANDS

# Step 4.
COMMANDS=('apt-get update > /dev/null 2>&1')
execute "Update apt packages" 4 $COMMANDS

# Step 5.
COMMANDS=(
  "add-apt-repository ppa:ondrej/php -y > /dev/null 2>&1"
  "apt install php8.3-cli php8.3-xml php8.3-curl php8.3-gd unzip make -y > /dev/null 2>&1"
)
execute "Install PHP8.3, unzip and make. (php packages: 'cli', 'xml', 'curl' and 'gd')" 5 $COMMANDS

# Step 6.
COMMANDS=(
  'apt install docker-ce net-tools -y > /dev/null 2>&1'
  'curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose > /dev/null 2>&1'
  'chmod +x /usr/local/bin/docker-compose'
)
execute "Install docker-ce, net-tools and docker-compose" 6 $COMMANDS

# Step 7.
COMMANDS=(
  'mkdir -p /docker_projects'
  'chown -R dev:dev /docker_projects'
  'curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o /home/dev/.git-completion.bash > /dev/null 2>&1'
  'ln -s -f /docker_projects /home/dev/docker'
)
execute "Initialize /docker_projects tree folder" 7 $COMMANDS

# Step 8.
COMMANDS=(
  'usermod -G docker dev'
  'mkdir -p /home/dev/.ssh'
  'chown -R dev:dev /docker_projects'
  'chown -R dev:dev /home/dev'
)
execute "Set and update user and groups permissions" 8 $COMMANDS

# Step 9.
TEXT="Generate SSH keys"
printInline "$TEXT"
if [ ! -f /home/dev/.ssh/id_rsa ]; then
  su -c 'ssh-keygen -b 4096 -t rsa -f /home/dev/.ssh/id_rsa -q -N ""' dev
else
  echo "The file 'id_rsa' already exists on /home/dev/.ssh/ folder. If you want to create a new ssh keys, run 'ssh-keygen' command."
fi
checkStatusCode 9 "$TEXT"

# Step 10.
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" > /dev/null 2>&1
COMMANDS=(
  'php composer-setup.php > /dev/null 2>&1'
  'php -r "unlink(\"composer-setup.php\");" > /dev/null 2>&1'
  'mv composer.phar /usr/local/bin/composer > /dev/null 2>&1'
)
execute "Install composer on host machine" 10 $COMMANDS

# Step 11.
COMMANDS=(
  'apt install libnss3-tools xdg-utils libnspr4 libnss3 -y > /dev/null 2>&1'
  'wget https://github.com/ddev/ddev/releases/download/v1.22.7/ddev_1.22.7_linux_amd64.deb > /dev/null 2>&1'
  'sudo dpkg -i ddev_1.22.7_linux_amd64.deb > /dev/null 2>&1'
)
execute "Install ddev" 11 $COMMANDS

# Step 12.
COMMANDS=(
  'wget https://github.com/lando/lando/releases/download/v3.20.8/lando-x64-v3.20.8.deb > /dev/null 2>&1'
  'sudo dpkg -i lando-x64-v3.20.8.deb > /dev/null 2>&1'
)
execute "Install lando" 12 $COMMANDS

# Step 13.
TEXT="Update user .bashrc file"
printInline "$TEXT"
cat << EOF >> /home/dev/.bashrc

cd /docker_projects
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo service docker start

EOF
cat autocompletition.bashrc >> .bashrc
checkStatusCode 13 "$TEXT"

# Step 14.
TEXT="Include current user in sudoers file"
printInline "$TEXT"
cat << EOF >> /etc/sudoers
dev ALL=(ALL) NOPASSWD:ALL
EOF
checkStatusCode 14 "$TEXT"

# Return script execution feedback to user.
END=`date +%s`
RUNTIME=$((END-START))
echo -e "${Cyan}\n\nSUCCESS! The docker profile has been succesfully installed in your WSL2 instance.${Color_Off}"
echo -e "${White}The installation took $RUNTIME seconds to run.${Color_Off}"
