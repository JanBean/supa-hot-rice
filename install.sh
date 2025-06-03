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
  printf 'Do you want to confirm every time before a command executes?[y/N/a]\n'
  printf '  y = Yes, ask me before executing each of them.\n'
  printf '  N = No, just execute them automatically. (DEFAULT)\n'
  printf '  a = Abort.\n\e[0m'
  read -p "====> " p
  case $p in
    y) ask=true ;;
    a) exit 1 ;;
    *) ask=false ;;
  esac
}

step_system_update() {
  ask_execute sudo pacman -Syu
}


step_set_up_installers() {
  # isntall yay, because paru does not support cleanbuild. Also see https://wiki.hyprland.org/FAQ/#how-do-i-update
  if ! command -v yay >/dev/null 2>&1;then
    echo -e "\e[33m[$0]: \"yay\" not found.\e[0m"
    showfun install-yay
    ask_execute install-yay
  fi
}

step_install_packages() {
  showfun handle-deprecated-dependencies
  ask_execute handle-deprecated-dependencies

  install_packages
}

step_install_apps() {
  install_apps
  ask_execute fc-cache -fv # scan font directories and rebuild font cache
}

step_setup_system() {
  base_system_config
}

step_symlink_dotfiles() {
  # In case some folders do not exists
  ask_execute mkdir -p $XDG_BIN_HOME $XDG_CACHE_HOME $XDG_CONFIG_HOME $XDG_DATA_HOME

  if gum confirm --default=true "Set Desktop wallpaper? (Some themes require a Wallpaper)"; then
    wallpaper_path=$(gum input --placeholder "Enter path to wallpaper")
    if [ -n "$wallpaper_path" ]; then
      ask_execute wall -i "$wallpaper_path"
    else
      echo "No path specified, continuing symlinking dotfiles"
    fi
  fi

  DOTFILES_DIR="./dotfiles"
  TARGET="$HOME"

  # Get all subdirectories (i.e., stow packages)
  mapfile -t stow_dirs < <(find "$DOTFILES_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n")

  # Prompt user to choose
  selected_dotfiles=$(gum choose --no-limit "${stow_dirs[@]}" "CANCEL")
  if [[ "$selected_dotfiles" == "CANCEL" || -z "$selected_dotfiles" ]]; then
    echo ":: Loading dotfiles cancelled."
  else
    mapfile -t dotfile_dirs <<< "$selected_dotfiles"
    for dir in "${dotfile_dirs[@]}"; do
      echo ":: Preparing to stow '$dir'"
      ask_execute stow "$dir" -d "$DOTFILES_DIR" -t "$TARGET" --adopt # stow dir to target and adopt existing files
      if gum confirm --default=false "Git diff to compare adopted and committed files?"; then
        ask_execute git diff
      fi
      if gum confirm --default=true "Discard adopted files and revert back to contents from last commit?"; then
        ask_execute git reset --hard # Discard adopted file and revert back to contents as per last commit
      fi
    done
    echo ":: Done stowing selected dotfiles."
  fi
}

step_uninstall_gum() {
  sudo pacman -Rns gum
}

########################################## SCRIPT START ###############################################

if ! command -v pacman >/dev/null 2>&1; then
  printf "\e[31m[$0]: pacman not found, it seems that the system is not ArchLinux or Arch-based distros. Aborting...\e[0m\n"
  exit 1
fi

prevent_sudo_or_root


# Prompt user choices
case $ask in # prevents repeated start
  false)sleep 0 ;;
  *)start_task ;;
esac

set -e # exit if non zero exit status


# Check if gum is installed, install if not
if ! command -v gum >/dev/null; then
  echo -e "\e[34m$me: Gum is not installed. Installing for fancy installation....\e[0m"
  on_error_retry sudo pacman -Sy --noconfirm gum
fi

############################################ Run Steps ############################################

# Map step names to functions
declare -A STEP_FUNCTIONS

STEP_FUNCTIONS["Update System"]="step_system_update"
STEP_FUNCTIONS["Set Up Installers"]="step_set_up_installers"
STEP_FUNCTIONS["Install Packages"]="step_install_packages"
STEP_FUNCTIONS["Install Apps"]="step_install_apps"
STEP_FUNCTIONS["Setup System and Services"]="step_setup_system"
STEP_FUNCTIONS["Symlink + Configure Dotfiles"]="step_symlink_dotfiles"
STEP_FUNCTIONS["Uninstall Gum"]="step_uninstall_gum"

# --- Step Selection Prompt ---
echo -e "\n\e[1;36mSelect which steps to run:\e[0m"
selected_steps=$(gum choose --no-limit \
  --selected "Update System" \
  --selected "Set Up Installers" \
  --selected "Install Packages" \
  --selected "Install Apps" \
  --selected "Setup System and Services" \
  --selected "Symlink + Configure Dotfiles" \
  "Update System" \
  "Set Up Installers" \
  "Install Packages" \
  "Install Apps" \
  "Setup System and Services" \
  "Symlink + Configure Dotfiles" \
  "Uninstall Gum")

# Run the selected steps
mapfile -t steps <<< "$selected_steps"
for step_label in "${steps[@]}"; do
  echo -e "\n\e[36m ############################################ \e[1m$step_label\e[36m ########################################\e[0m\n"
  step_func="${STEP_FUNCTIONS[$step_label]}"
  if [[ -n "$step_func" ]]; then
    on_error_retry $step_func
  else
    echo "!! Unknown step: $step_label"
  fi
done

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