#!/bin/bash

# Online script to install supa-hot-rice.

function try { "$@" || sleep 0; }
function x() {
  if "$@";then cmdstatus=0;else cmdstatus=1;fi # 0=normal; 1=failed; 2=failed but ignored
  while [ $cmdstatus == 1 ] ;do
    echo -e "\e[31m$REPO: Command \"\e[32m$@\e[31m\" has failed."
    echo -e "You may need to resolve the problem manually BEFORE repeating this command.\e[0m"
    echo "  r = Repeat this command (DEFAULT)"
    echo "  e = Exit now"
    read -p " [R/e]: " p
    case $p in
      [eE]) echo -e "\e[34mAlright, will exit.\e[0m";break;;
      *) echo -e "\e[34mOK, repeating...\e[0m"
         if "$@";then cmdstatus=0;else cmdstatus=1;fi
         ;;
    esac
  done
  case $cmdstatus in
    0) echo -e "\e[34m$REPO: Command \"\e[32m$@\e[34m\" finished.\e[0m";;
    1) echo -e "\e[31m$REPO: Command \"\e[32m$@\e[31m\" has failed. Exiting...\e[0m";exit 1;;
  esac
}

set -e

command -v pacman || { echo "\"pacman\" not found. This script only work for Arch(-based) Linux distros. Aborting..."; exit 1 ; }

REPO="supa-hot-rice"
BRANCH="master"
REMOTE_REPO="JanBean/${REPO}"

# optional use script url data passed as argument
SCRIPT_URL="$1"
if [[ $SCRIPT_URL =~ raw\.githubusercontent\.com/([^/]+)/([^/]+)/refs/heads/([^/]+) ]]; then
    USER="${BASH_REMATCH[1]}"
    REPO="${BASH_REMATCH[2]}"
    BRANCH="${BASH_REMATCH[3]}"
    REMOTE_REPO="${USER}/${REPO}"

    echo -e "\e[34mInstalling from $REMOTE_REPO@$BRANCH \e[0m"
else
    echo -e "\e[31mERROR: Could not extract repository metadata, using default values \e[0m"
fi

path="${HOME}/${REPO}"

# Check if git is installed, install if not
if ! command -v git >/dev/null; then
  echo -e "\e[34m$REPO: Git is not installed. Installing with pacman....\e[0m"
  x sudo pacman -Sy --noconfirm git
fi

echo "$REPO: Downloading repo to $path ..."
x mkdir -p "$path"
x cd "$path"
if [ -z "$(ls -A)" ]; then
  x git init -b "$BRANCH"
  x git remote add origin https://github.com/"$REMOTE_REPO"
fi
git remote get-url origin|grep -q "$REMOTE_REPO" || { echo "Dir \"$path\" is not empty, nor a git repo of $REMOTE_REPO. Aborting..."; exit 1 ; }
x git pull origin "$BRANCH" && git submodule update --init --recursive
echo "$REPO: Downloaded."
echo "$REPO: Running \"install.sh\"."
x ls -a
x ./install.sh || { echo "$REPO: Error occurred when running \"install.sh\"."; exit 1 ; }
