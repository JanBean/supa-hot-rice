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

# install gum for fancy dialogues
on_error_retry sudo pacman --noconfirm -S gum

# Map step names to functions
declare -A STEP_FUNCTIONS

STEP_FUNCTIONS["Update System"]="step_system_update"
STEP_FUNCTIONS["Download Installers (yay, ...)"]="step_download_installers"
STEP_FUNCTIONS["Install Packages"]="step_install_packages"
STEP_FUNCTIONS["Install Apps"]="step_install_apps"
STEP_FUNCTIONS["Setup Groups/Services"]="step_setup_services"
STEP_FUNCTIONS["Symlink + Configure Dotfiles"]="step_symlink_dotfiles"
STEP_FUNCTIONS["Uninstall Gum"]="step_uninstall_gum"

# --- Step Selection Prompt ---
echo -e "\n\e[1;36mSelect which steps to run:\e[0m"
selected_steps=$(gum choose --no-limit --cursor-prefix "[x] " --selected-prefix "[✓] " --unselected-prefix "[ ] " \
  --selected="Update System" \
  --selected="Download Installers (yay, ...)" \
  --selected="Install Packages" \
  --selected="Install Apps" \
  --selected="Setup Groups/Services" \
  --selected="Symlink + Configure Dotfiles" \
  "Uninstall Gum")

# Run the selected steps
while IFS= read -r step_label; do
  step_func="${STEP_FUNCTIONS[$step_label]}"
  if [[ -n "$step_func" ]]; then
    $step_func
  else
    echo "⚠️ Unknown step: $step_label"
  fi
done <<< "$selected_steps"

step_system_update() {
  printf "\e[36m[$0]: ################################## 1. System update #############################################\n\e[0m"
  ask_execute sudo pacman -Syu
}


step_download_installers() {
  printf "\e[36m[$0]: ############################## 2. Download installers (yay, ...) ######################################\n\e[0m"

  # isntall yay, because paru does not support cleanbuild. Also see https://wiki.hyprland.org/FAQ/#how-do-i-update
  if ! command -v yay >/dev/null 2>&1;then
    echo -e "\e[33m[$0]: \"yay\" not found.\e[0m"
    showfun install-yay
    ask_execute install-yay
  fi
}

step_install_packages() {
  printf "\e[36m[$0]: ######################### 3. Install packages ################################\n\e[0m"

  showfun handle-deprecated-dependencies
  ask_execute handle-deprecated-dependencies

  install_packages
}

step_install_apps() {
  printf "\e[36m[$0]: ########################## 4. Install Apps ################################\n\e[0m"

  install_apps

  ask_execute fc-cache -fv # scan font directories and rebuild font cache
}

step_setup_services() {
  printf "\e[36m[$0]: ######################### 5. setup user groups/services ##############################\n\e[0m"

  base_system_config
}

step_symlink_dotfiles() {
  printf "\e[36m[$0]: ######################### 6. Symlinking + Configuring Dotfiles #########################\e[0m\n"

  # In case some folders do not exists
  ask_execute mkdir -p $XDG_BIN_HOME $XDG_CACHE_HOME $XDG_CONFIG_HOME $XDG_DATA_HOME

  DOTFILES_DIR="./dotfiles"
  TARGET="$HOME"

  # Get all subdirectories (i.e., stow packages)
  mapfile -t stow_dirs < <(find "$DOTFILES_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n")

  # Prompt user to choose
  selected_dotfiles=$(gum choose --no-limit "${stow_dirs[@]}" "CANCEL")
  if [[ "$selected_dotfiles" == "CANCEL" || -z "$selected_dotfiles" ]]; then
      echo ":: Loading dotfiles cancelled."
  else
    # Convert selection to an array if multiple were selected
    IFS=$'\n' read -rd '' -a choices <<<"$selected_dotfiles"

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
}

step_uninstall_gum() {
  printf "\e[36m[$0]: ######################### 6. Uninstalling gum (shell script utility) ####################################\e[0m\n"
  sudo pacman -Rns gum
}


printf "\e[36m[$0]: ######################### Finishing ####################################\e[0m\n"

# Prevent hyprland from not fully loaded
sleep 1

try hyprctl reload

printf "\e[36mPress \e[30m\e[46m Super+/ \e[0m\e[36m for a list of keybinds\e[0m\n"
printf "\n"

if [[ -z "${SHR_VIRTUAL_ENV}" ]]; then
  printf "\n\e[31m[$0]: \!! Important \!! : Please ensure environment variable \e[0m \$SHR_VIRTUAL_ENV \e[31m is set to proper value (by default \"~/.local/state/ags/.venv\"), or AGS config will not work. We have already provided this configuration in ~/.config/hypr/hyprland/env.conf, but you need to ensure it is included in hyprland.conf, and also a restart is needed for applying it.\e[0m\n"
fi

# warn from conflicting files
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
