#!/usr/bin/env bash
# WSL2-Prepare (Ubuntu 24.04) — pretty edition

set -Eeuo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Colors & Icons
# ─────────────────────────────────────────────────────────────────────────────
Color_Off='\033[0m'
Black='\033[0;30m';  Red='\033[0;31m';  Green='\033[0;32m'
Yellow='\033[0;33m'; Blue='\033[0;34m'; Purple='\033[0;35m'
Cyan='\033[0;36m';   White='\033[0;37m'
BWhite='\033[1;37m'; LightGreen='\033[1;32m'

ICON_OK="✅"
ICON_ERR="🛑"
ICON_RUN="⏳"
ICON_STEP="▶"
ICON_DONE="🎉"

# ─────────────────────────────────────────────────────────────────────────────
# Globals
# ─────────────────────────────────────────────────────────────────────────────
START_TS=$(date +%s)
LOGFILE="/var/log/wsl2-prepare-$(date +%Y%m%d-%H%M%S).log"
if ! touch "$LOGFILE" >/dev/null 2>&1; then
  LOGFILE="/tmp/wsl2-prepare-$(date +%Y%m%d-%H%M%S).log"
fi
export DEBIAN_FRONTEND=noninteractive

TOTAL_STEPS=7
CURRENT_STEP=0

# ─────────────────────────────────────────────────────────────────────────────
# UI bits
# ─────────────────────────────────────────────────────────────────────────────
hide_cursor(){ tput civis 2>/dev/null || true; }
show_cursor(){ tput cnorm 2>/dev/null || true; }
cleanup(){ show_cursor; }
trap cleanup EXIT

banner () {
  echo -e "${BWhite}"
  echo "┌──────────────────────────────────────────────┐"
  echo "│               WSL2-PREPARE 🚀                │"
  echo "│         oembunut / pgrandeg — NTTDATA        │"
  echo "│                  2023–2025                   │"
  echo "└──────────────────────────────────────────────┘"
  echo -e "${Color_Off}${White}Log: ${Cyan}${LOGFILE}${Color_Off}\n"
}

note () { echo -e "${Cyan}ℹ${Color_Off} $*"; }

fail () {
  local code="$1"; shift
  echo -e "\r\033[K${Red}${ICON_ERR} $* (code ${code})${Color_Off}"
  echo "[ERROR] $* (code ${code})" >>"$LOGFILE"
  exit "$code"
}

spinner () {
  # show spinner while PID runs
  local pid="$1"
  local frames=('⠇' '⠋' '⠙' '⠸' '⠴' '⠦')
  local i=0
  hide_cursor
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r${Yellow}${ICON_RUN} %s${Color_Off} " "${frames[i]}"
    i=$(( (i+1) % ${#frames[@]} ))
    sleep 0.1
  done
  show_cursor
}

run_cmd () {
  # run a string command in bash -lc, log stdout/stderr
  /usr/bin/env bash -o pipefail -lc "$1" >>"$LOGFILE" 2>&1
}

run_step () {
  local title="$1"; local code="$2"; shift 2
  CURRENT_STEP=$((CURRENT_STEP + 1))
  local prefix="${Blue}${ICON_STEP} Paso ${CURRENT_STEP}/${TOTAL_STEPS}:${Color_Off}"
  printf "%b %s " "$prefix" "$title"

  {
    for cmd in "$@"; do
      echo -e "\n[CMD] $cmd" >>"$LOGFILE"
      run_cmd "$cmd"
    done
  } &
  local bg=$!
  spinner "$bg"
  wait "$bg" || fail "$code" "$title"

  echo -e "\r\033[K${LightGreen}${ICON_OK} ${title}${Color_Off}"
}

append_once () {
  # append_once "line" "file"
  local line="$1"; local file="$2"
  grep -qxF -- "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

# ─────────────────────────────────────────────────────────────────────────────
# Pre-flight checks
# ─────────────────────────────────────────────────────────────────────────────
banner

if [ -d /docker_projects ]; then
  echo -e "${Yellow}⚠ La carpeta /docker_projects ya existe. No se continúa para evitar pisar tu entorno.${Color_Off}"
  echo -e "Saliendo con código 1.\n"
  exit 1
fi

# ─────────────────────────────────────────────────────────────────────────────
# Steps
# ─────────────────────────────────────────────────────────────────────────────

run_step "Actualizar índices de apt" 1 \
  "apt-get update"

run_step "Instalar paquetes comunes (transport-https, certificados, curl, etc.)" 2 \
  "apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2 libnss3-tools xdg-utils libnspr4 libnss3"

run_step "Añadir repositorio de Docker a apt" 3 \
  "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg" \
  "echo 'deb [signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable' | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null"

run_step "Actualizar índices de apt (de nuevo)" 4 \
  "apt-get update"

run_step "Instalar PHP, unzip y make" 5 \
  "apt-get install -y php-cli php-xml php-curl php-gd unzip make docker-compose-plugin docker-ce docker-ce-cli containerd.io docker-buildx-plugin net-tools"

#run_step "Instalar docker-ce, net-tools y docker-compose v2" 6 \
#  "apt-get install -y docker-ce net-tools" \
#  "curl -L 'https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-\$(uname -s)-\$(uname -m)' -o /usr/local/bin/docker-compose" \
#  "chmod +x /usr/local/bin/docker-compose"

run_step "Inicializar árbol /docker_projects" 6 \
  "mkdir -p /docker_projects" \
  "chown -R dev:dev /docker_projects" \
  "curl -fsSL https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o /home/dev/.git-completion.bash" \
  "ln -s -f /docker_projects /home/dev/docker"

run_step "Permisos de usuario y grupos" 7 \
  "usermod -aG docker dev" \
  "mkdir -p /home/dev/.ssh" \
  "chown -R dev:dev /docker_projects" \
  "chown -R dev:dev /home/dev"

# Paso 9: SSH Keys (flujo especial para UI)
CURRENT_STEP=$((CURRENT_STEP + 1))
printf "%b %s " "${Blue}${ICON_STEP} Paso ${CURRENT_STEP}/${TOTAL_STEPS}:${Color_Off}" "Generar claves SSH"
if [ ! -f /home/dev/.ssh/id_rsa ]; then
  {
    echo "[INFO] Generating SSH keys for user dev" >>"$LOGFILE"
    su -c 'ssh-keygen -b 4096 -t rsa -f /home/dev/.ssh/id_rsa -q -N ""' dev >>"$LOGFILE" 2>&1
  } || fail 9 "Generar claves SSH"
  echo -e "\r\033[K${LightGreen}${ICON_OK} Generar claves SSH${Color_Off}"
else
  echo -e "\r\033[K${Yellow}🔑 Ya existe /home/dev/.ssh/id_rsa. Omite generación.${Color_Off}"
fi

# Paso 10: .bashrc
CURRENT_STEP=$((CURRENT_STEP + 1))
printf "%b %s " "${Blue}${ICON_STEP} Paso ${CURRENT_STEP}/${TOTAL_STEPS}:${Color_Off}" "Actualizar .bashrc de dev"
{
  append_once "# Prepare auto completion and ensure docker is started" "/home/dev/.bashrc"
  cat autocompletition.bashrc >> /home/dev/.bashrc 2>/dev/null || true
  append_once "cd /docker_projects" "/home/dev/.bashrc"
  #append_once "sudo update-alternatives --set iptables /usr/sbin/iptables-legacy" "/home/dev/.bashrc"
  append_once "sudo service docker start" "/home/dev/.bashrc"
  chown dev:dev /home/dev/.bashrc
} >>"$LOGFILE" 2>&1 || fail 10 "Actualizar .bashrc de dev"
echo -e "\r\033[K${LightGreen}${ICON_OK} Actualizar .bashrc de dev${Color_Off}"

# Paso 11: sudoers (archivo dedicado)
run_step "Conceder NOPASSWD a dev (sudoers.d)" 11 \
  "echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/99-dev-nopasswd && chmod 440 /etc/sudoers.d/99-dev-nopasswd && visudo -cf /etc/sudoers"

run_step "Instalar Composer" 12 \
  "curl -fsSL https://getcomposer.org/installer -o composer-setup.php" \
  "php composer-setup.php" \
  "php -r 'unlink(\"composer-setup.php\");'" \
  "mv composer.phar /usr/local/bin/composer"

run_step "Instalar ddev" 13 \
  "su - dev -c 'curl -fsSL https://ddev.com/install.sh | bash'"

# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────
END_TS=$(date +%s)
RUNTIME=$((END_TS - START_TS))
echo -e "\n${LightGreen}${ICON_DONE} ¡ÉXITO! Se ha configurado el perfil Docker en tu instancia WSL2.${Color_Off}"
echo -e "${White}Tiempo total: ${Cyan}${RUNTIME}s${Color_Off}"
echo -e "${White}Detalles en el log: ${Cyan}${LOGFILE}${Color_Off}\n"
