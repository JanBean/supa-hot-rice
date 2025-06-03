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

printf "\e[36m[$0]: ################################## 1. System update #############################################\n\e[0m"

case $SKIP_SYSUPDATE in
  true) sleep 0;;
  *) ask_execute sudo pacman -Syu;;
esac

printf "\e[36m[$0]: ############################## 2. Download installers ######################################\n\e[0m"

# isntall yay, because paru does not support cleanbuild. Also see https://wiki.hyprland.org/FAQ/#how-do-i-update
if ! command -v yay >/dev/null 2>&1;then
  echo -e "\e[33m[$0]: \"yay\" not found.\e[0m"
  showfun install-yay
  ask_execute install-yay
fi

printf "\e[36m[$0]: ########################## 3. Get packages, install apps ################################\n\e[0m"

showfun handle-deprecated-dependencies
ask_execute handle-deprecated-dependencies

install_packages

install_apps

ask_execute fc-cache -fv # scan font directories and rebuild font cache

printf "\e[36m[$0]: ############################ 4. setup user groups/services ##############################\n\e[0m"

base_system_config

printf "\e[36m[$0]: ############################### 5. Symlinking + Configuring Dotfiles ####################################\e[0m\n"

# In case some folders do not exists
ask_execute mkdir -p $XDG_BIN_HOME $XDG_CACHE_HOME $XDG_CONFIG_HOME $XDG_DATA_HOME

DOTFILES_DIR="./dotfiles"
TARGET="$HOME"

# Get all subdirectories (i.e., stow packages)
mapfile -t stow_dirs < <(find "$DOTFILES_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n")

# Prompt user to choose
selected=$(gum choose --no-limit "${stow_dirs[@]}" "CANCEL")
if [[ "$selected" == "CANCEL" || -z "$selected" ]]; then
    echo ":: Loading dotfiles cancelled."
else
  # Convert selection to an array if multiple were selected
  IFS=$'\n' read -rd '' -a choices <<<"$selected"

  # Loop through selected dirs
  for dir in "${choices[@]}"; do
      echo ":: Preparing to stow '$dir'"

      # Preview stow output and parse file paths
      while IFS= read -r line; do
          # stow -nv outputs something like: "LINK: .config/foo -> /home/user/.config/foo"
          # We extract the target path from the output
          target_path=$(echo "$line" | awk -F " -> " '{print $2}')
          if [[ -n "$target_path" ]]; then
              echo ":: Removing existing file: $target_path"
              rm -rf "$target_path"
          fi
      done < <(stow -nv "$dir" -d "$DOTFILES_DIR" -t "$TARGET")

      # Actually stow it now
      stow "$dir" -d "$DOTFILES_DIR" -t "$TARGET"
      echo ":: '$dir' stowed successfully"
  done
fi

# Prevent hyprland from not fully loaded
sleep 1

try hyprctl reload

################################# finish ################################

printf "\e[36mPress \e[30m\e[46m Super+/ \e[0m\e[36m for a list of keybinds\e[0m\n"
printf "\n"

if [[ -z "${SHR_VIRTUAL_ENV}" ]]; then
  printf "\n\e[31m[$0]: \!! Important \!! : Please ensure environment variable \e[0m \$SHR_VIRTUAL_ENV \e[31m is set to proper value (by default \"~/.local/state/ags/.venv\"), or AGS config will not work. We have already provided this configuration in ~/.config/hypr/hyprland/env.conf, but you need to ensure it is included in hyprland.conf, and also a restart is needed for applying it.\e[0m\n"
fi

##################################### print warn files #####################

warn_files=()
warn_files_tests=() # append for deprecation messages
for i in ${warn_files_tests[@]}; do
  echo $i
  test -f $i && warn_files+=($i)
  test -d $i && warn_files+=($i)
done

if [[ ! -z "${warn_files[@]}" ]]; then
  printf "\n\e[31m[$0]: \!! Important \!! : Please delete \e[0m ${warn_files[*]} \e[31m manually as soon as possible, since we\'re now using AUR package or local PKGBUILD to install them for Arch(based) Linux distros, and they'll take precedence over our installation, or at least take up more space.\e[0m\n"
fi
