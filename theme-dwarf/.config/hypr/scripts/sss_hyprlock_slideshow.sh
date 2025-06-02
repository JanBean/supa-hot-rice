#!/bin/bash
CURRENT_PID=$$
SCRIPT_NAME=$(basename "$0")
# Path to wallpaper folder
WALLPAPER_DIR="$HOME/Downloads"
# Interval between wallpaper changes (in seconds)
INTERVAL=8
# Temporary config file for hyprpaper slideshow
TEMP_HYPRPAPER_CONF="$HOME/.cache/hypr/hyprpaper-slideshow.conf"
# swww transition type (e.g., wipe, fade, random)
TRANSITION_TYPE="fade"
# Transition duration in seconds 
TRANSITION_DURATION=1

if [ ! -d "$WALLPAPER_DIR" ]; then
    echo ":: ERROR - Missing wallpaper directory $WALLPAPER_DIR"
    exit 1
fi


WALLPAPERS=() # Discovered wallpapers
discover_wallpapers() {
    while IFS= read -r -d '' file; do
        echo ":: Found wallpaper: $file"
        WALLPAPERS+=("$file")
    done < <(find "$WALLPAPER_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) -print0)

    if [ -z "$WALLPAPERS" ]; then
        echo ":: ERROR - No valid wallpapers found in $WALLPAPER_DIR"
        exit 1
    fi
}

kill_other_instances(){
    mapfile -t OTHERS < <(pgrep -f "$SCRIPT_NAME" | grep -v "^$CURRENT_PID$")
    
    if [ ${#OTHERS[@]} -eq 0 ]; then
        echo ":: No other instances of $SCRIPT_NAME found."
        return
    fi
    
    for pid in "${OTHERS[@]}"; do
        echo ":: Trying to kill $pid: $(ps -p "$pid" -o args=)"
        kill -9 "$pid"
    done
}

init_swww() {
    if ! pgrep -x "swww-daemon" > /dev/null; then
        echo ":: Starting swww-daemon"
        swww init
        # sleep 1
        if ! pgrep -x "swww-daemon" > /dev/null; then
            echo ":: ERROR - swww-daemon failed to start"
            exit 1
        fi
    fi
}

generate_conf(){
    # temporary config for hyprpaper
    echo ":: Setting up $TEMP_HYPRPAPER_CONF"
    mkdir -p "$(dirname "$TEMP_HYPRPAPER_CONF")" 
    touch "$TEMP_HYPRPAPER_CONF"
    printf "splash = false\n" > "$TEMP_HYPRPAPER_CONF"
    for wallpaper in "${WALLPAPERS[@]}"; do
        echo ":: Registering: $Wallpaper"
        printf "preload = $wallpaper\n" >> "$TEMP_HYPRPAPER_CONF"
    done
    first_wallpaper=$(echo "$WALLPAPERS" | head -n 1)
    printf "wallpaper = ,$first_wallpaper\n" >> "$TEMP_HYPRPAPER_CONF"
}

start_slideshow() {
    kill_other_instances
    # hyprctl hyprpaper unload all
    # killall hyprpaper 
    sleep 1

    init_swww

    discover_wallpapers
    generate_conf

    # Set initial wallpaper with zoom effect
    first_wallpaper="${WALLPAPERS[0]}"
    swww img "$first_wallpaper" --transition-duration 0

    while true; do
        # Shuffle wallpapers
        mapfile -d '' shuffled_wallpapers < <(printf '%s\0' "${WALLPAPERS[@]}" | shuf --zero-terminated)

        for current_wallpaper in "${shuffled_wallpapers[@]}"; do
            sleep "$INTERVAL"
            echo ":: Switching to: $current_wallpaper"
            swww img "$current_wallpaper" --transition-type "$TRANSITION_TYPE" --transition-duration "$TRANSITION_DURATION" || {
                echo ":: Failed to set wallpaper: $current_wallpaper"
            }
        done
    done &
}

stop_slideshow() {
    # hyprctl hyprpaper unload all
    # killall hyprpaper 

    kill_other_instances
    swww clear
    # Clean up temporary files
    rm -f "$TEMP_HYPRPAPER_CONF"


    # Restart hyprpaper with default config
    # hyprpaper &
}

# Handle start/stop commands
case "$1" in
    start)
        start_slideshow
        ;;
    stop)
        stop_slideshow
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac