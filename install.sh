#!/usr/bin/env bash
cd "$(dirname "$0")"
export base="$(pwd)"
source ./scriptdata/environment-variables
source ./scriptdata/functions
source ./scriptdata/installers
source ./scriptdata/options
source ./scriptdata/system-configuration
source ./manager/package-manager
source ./manager/app-manager

################################### Prompt user choices ##############################

if ! command -v pacman >/dev/null 2>&1; then 
  printf "\e[31m[$0]: pacman not found, it seems that the system is not ArchLinux or Arch-based distros. Aborting...\e[0m\n"
  exit 1
fi

prevent_sudo_or_root

start_task() {
    printf "\e[34m[$0]: Wassssssuuuuuuuuuup!!!?:\n"
    printf "\e[31m"

  ask_backup_files
  ask_confirm_exec
}

ask_backup_files () {
    printf '\n'
    printf "Would you like to create a backup for \"$XDG_CONFIG_HOME\" and \"$HOME/.local/\" folders?\n[y/N]: "
    read -p " " backup_confirm
    case $backup_confirm in
      [yY][eE][sS]|[yY])
        backup_configs
        ;;
      *)
        echo "Skipping backup..."
        ;;
    esac
}

ask_confirm_exec() {
  printf '\n'
  printf 'Do you want to confirm every time before a command executes?\n'
  printf '  y = Yes, ask me before executing each of them. (DEFAULT)\n'
  printf '  n = No, just execute them automatically.\n'
  printf '  a = Abort.\n'
  read -p "====> " p
  case $p in
    n) ask=false ;;
    a) exit 1 ;;
    *) ask=true ;;
  esac
}

case $ask in # prevents repeated start
  false)sleep 0 ;;
  *)start_task ;;
esac

set -e # exit if non zero exit status

################################ update sys and install yay ##################################

printf "\e[36m[$0]: 1. Get packages and setup user groups/services\n\e[0m"

case $SKIP_SYSUPDATE in
  true) sleep 0;;
  *) ask_execute sudo pacman -Syu;;
esac

# isntall yay, because paru does not support cleanbuild. Also see https://wiki.hyprland.org/FAQ/#how-do-i-update
if ! command -v yay >/dev/null 2>&1;then
  echo -e "\e[33m[$0]: \"yay\" not found.\e[0m"
  showfun install-yay
  ask_execute install-yay
fi

################################## load packages apps & dependencies #################################

showfun handle-deprecated-dependencies
ask_execute handle-deprecated-dependencies

install_packages

install_apps

################################ system config ################################

base_system_config

#####################################################################################
printf "\e[36m[$0]: 2. Copying + Configuring\e[0m\n"

# In case some folders does not exists
ask_execute mkdir -p $XDG_BIN_HOME $XDG_CACHE_HOME $XDG_CONFIG_HOME $XDG_DATA_HOME

# `--delete' for rsync to make sure that
# original dotfiles and new ones in the SAME DIRECTORY
# (eg. in ~/.config/hypr) won't be mixed together

# MISC (For .config/* but not AGS, not Fish, not Hyprland)
case $SKIP_MISCCONF in
  true) sleep 0;;
  *)
    for i in $(find .config/ -mindepth 1 -maxdepth 1 ! -name 'ags' ! -name 'fish' ! -name 'hypr' -exec basename {} \;); do
#      i=".config/$i"
      echo "[$0]: Found target: .config/$i"
      if [ -d ".config/$i" ];then ask_execute rsync -av --delete ".config/$i/" "$XDG_CONFIG_HOME/$i/"
      elif [ -f ".config/$i" ];then ask_execute rsync -av ".config/$i" "$XDG_CONFIG_HOME/$i"
      fi
    done
    ;;
esac

# For AGS
case $SKIP_AGS in
  true) sleep 0;;
  *)
    ask_execute rsync -av --delete --exclude '/user_options.jsonc' .config/ags/ "$XDG_CONFIG_HOME"/ags/
    t="$XDG_CONFIG_HOME/ags/user_options.jsonc"
    if [ -f $t ];then
      echo -e "\e[34m[$0]: \"$t\" already exists.\e[0m"
      # v cp -f .config/ags/user_options.jsonc $t.new
      existed_ags_opt=y
    else
      echo -e "\e[33m[$0]: \"$t\" does not exist yet.\e[0m"
      ask_execute cp .config/ags/user_options.jsonc $t
      existed_ags_opt=n
    fi
    ;;
esac

# For Hyprland
case $SKIP_HYPRLAND in
  true) sleep 0;;
  *)
    ask_execute rsync -av --delete --exclude '/custom' --exclude '/hyprlock.conf' --exclude '/hypridle.conf' --exclude '/hyprland.conf' .config/hypr/ "$XDG_CONFIG_HOME"/hypr/
    t="$XDG_CONFIG_HOME/hypr/hyprland.conf"
    if [ -f $t ];then
      echo -e "\e[34m[$0]: \"$t\" already exists.\e[0m"
      if [ -f "$XDG_STATE_HOME/ags/user/firstrun.txt" ]
      then
        ask_execute cp -f .config/hypr/hyprland.conf $t.new
        existed_hypr_conf=y
      else
        ask_execute mv $t $t.old
        ask_execute cp -f .config/hypr/hyprland.conf $t
        existed_hypr_conf_firstrun=y
      fi
    else
      echo -e "\e[33m[$0]: \"$t\" does not exist yet.\e[0m"
      ask_execute cp .config/hypr/hyprland.conf $t
      existed_hypr_conf=n
    fi
    t="$XDG_CONFIG_HOME/hypr/hypridle.conf"
    if [ -f $t ];then
      echo -e "\e[34m[$0]: \"$t\" already exists.\e[0m"
      ask_execute cp -f .config/hypr/hypridle.conf $t.new
      existed_hypridle_conf=y
    else
      echo -e "\e[33m[$0]: \"$t\" does not exist yet.\e[0m"
      ask_execute cp .config/hypr/hypridle.conf $t
      existed_hypridle_conf=n
    fi
    t="$XDG_CONFIG_HOME/hypr/hyprlock.conf"
    if [ -f $t ];then
      echo -e "\e[34m[$0]: \"$t\" already exists.\e[0m"
      ask_execute cp -f .config/hypr/hyprlock.conf $t.new
      existed_hyprlock_conf=y
    else
      echo -e "\e[33m[$0]: \"$t\" does not exist yet.\e[0m"
      ask_execute cp .config/hypr/hyprlock.conf $t
      existed_hyprlock_conf=n
    fi
    t="$XDG_CONFIG_HOME/hypr/custom"
    if [ -d $t ];then
      echo -e "\e[34m[$0]: \"$t\" already exists, will not do anything.\e[0m"
    else
      echo -e "\e[33m[$0]: \"$t\" does not exist yet.\e[0m"
      ask_execute rsync -av --delete .config/hypr/custom/ $t/
    fi
    ;;
esac


# some foldes (eg. .local/bin) should be processed separately to avoid `--delete' for rsync,
# since the files here come from different places, not only about one program.
ask_execute rsync -av ".local/bin/" "$XDG_BIN_HOME"

# Prevent hyprland from not fully loaded
sleep 1
try hyprctl reload

existed_zsh_conf=n
grep -q 'source ${XDG_CONFIG_HOME:-~/.config}/zshrc.d/dots-hyprland.zsh' ~/.zshrc && existed_zsh_conf=y

##################################### print warn files #####################

warn_files=()
warn_files_tests=()
warn_files_tests+=(/usr/local/bin/ags)
warn_files_tests+=(/usr/local/etc/pam.d/ags)
warn_files_tests+=(/usr/local/lib/{GUtils-1.0.typelib,Gvc-1.0.typelib,libgutils.so,libgvc.so})
warn_files_tests+=(/usr/local/share/com.github.Aylur.ags)
warn_files_tests+=(/usr/local/share/fonts/TTF/Rubik{,-Italic}'[wght]'.ttf)
warn_files_tests+=(/usr/local/share/licenses/ttf-rubik)
warn_files_tests+=(/usr/local/share/fonts/TTF/Gabarito-{Black,Bold,ExtraBold,Medium,Regular,SemiBold}.ttf)
warn_files_tests+=(/usr/local/share/licenses/ttf-gabarito)
warn_files_tests+=(/usr/local/share/icons/OneUI{,-dark,-light})
warn_files_tests+=(/usr/local/bin/{LaTeX,res})
for i in ${warn_files_tests[@]}; do
  echo $i
  test -f $i && warn_files+=($i)
  test -d $i && warn_files+=($i)
done

################################# finish ################################

printf "\e[36mPress \e[30m\e[46m Ctrl+Super+T \e[0m\e[36m to select a wallpaper\e[0m\n"
printf "\e[36mPress \e[30m\e[46m Super+/ \e[0m\e[36m for a list of keybinds\e[0m\n"
printf "\n"

if [[ -z "${SHR_VIRTUAL_ENV}" ]]; then
  printf "\n\e[31m[$0]: \!! Important \!! : Please ensure environment variable \e[0m \$SHR_VIRTUAL_ENV \e[31m is set to proper value (by default \"~/.local/state/ags/.venv\"), or AGS config will not work. We have already provided this configuration in ~/.config/hypr/hyprland/env.conf, but you need to ensure it is included in hyprland.conf, and also a restart is needed for applying it.\e[0m\n"
fi

if [[ ! -z "${warn_files[@]}" ]]; then
  printf "\n\e[31m[$0]: \!! Important \!! : Please delete \e[0m ${warn_files[*]} \e[31m manually as soon as possible, since we\'re now using AUR package or local PKGBUILD to install them for Arch(based) Linux distros, and they'll take precedence over our installation, or at least take up more space.\e[0m\n"
fi