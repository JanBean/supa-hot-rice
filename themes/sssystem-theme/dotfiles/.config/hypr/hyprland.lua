-- SSSystem Hyprland configuration.
-- This file uses the Lua configuration API introduced in Hyprland 0.55.

local home = os.getenv("HOME")
local color_config_path = home .. "/.cache/wal/colors-hyprland.conf"
local hyprpaper_config_path = home .. "/.cache/wal/hyprpaper.conf"
local scripts = home .. "/.config/hypr/scripts"
local monitor1 = "DP-1"

local function load_wal_colors(path)
    local colors = {}
    local file = io.open(path, "r")
    if not file then
        return colors
    end

    for line in file:lines() do
        local name, value = line:match("^%$(%S+)%s*=%s*(%S+)")
        if name and value then
            colors[name] = value
        end
    end
    file:close()
    return colors
end

local colors = load_wal_colors(color_config_path)
local function wal(name, fallback)
    return colors[name] or fallback
end

local terminal = "kitty"
local file_manager = "dolphin"
local menu = 'rofi -modi "drun,window,keys"'
local menu_launcher = menu .. " -show drun"
local menu_emoji = 'rofi -modi "emoji:rofimoji --action copy --files emojis,nerd:rofimoji --action copy --files nerd_font" -show emoji'
local main_mod = "SUPER"

hl.env("XCURSOR_SIZE", "30")
hl.env("HYPRCURSOR_SIZE", "30")
hl.env("HYPRCURSOR_THEME", "rose-pine-hyprcursor")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("QT_STYLE_OVERRIDE", "kvantum")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("GMB_BACKEND", "nvidia-drm")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("NVD_BACKEND", "direct")

hl.on("hyprland.start", function()
    hl.exec_cmd(scripts .. "/enshure-wal.sh")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("hyprpaper -c " .. hyprpaper_config_path)
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("waybar")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("swaync")
    hl.exec_cmd("swaync-client -df")
    hl.exec_cmd("hyprswitch init --show-title --size-factor 5.5 --workspaces-per-row 5")
    hl.exec_cmd("spotify-launcher")
    hl.exec_cmd("vesktop")
end)

hl.monitor({ output = monitor1, mode = "3840x2160", position = "0x0", scale = 2 })
hl.workspace_rule({ workspace = "1", monitor = monitor1, default = true, persistent = true })

hl.config({
    general = {
        gaps_in = 3,
        gaps_out = 10,
        border_size = 2,
        col = {
            active_border = { colors = { wal("color5", "0xffb45d3c"), wal("color1", "0xff32511e") }, angle = 45 },
            inactive_border = wal("color2_70", "rgba(5b532ab3)"),
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },
    group = {
        col = {
            border_active = { colors = { wal("color5", "0xffb45d3c"), wal("color1", "0xff32511e") }, angle = 45 },
            border_inactive = wal("color2_70", "rgba(5b532ab3)"),
        },
        groupbar = {
            enabled = true,
            gradients = false,
            col = {
                active = wal("color5", "0xffb45d3c"),
                inactive = wal("color2_70", "rgba(5b532ab3)"),
                locked_active = wal("color5_50", "rgba(b45d3c80)"),
                locked_inactive = wal("color2_40", "rgba(5b532a66)"),
            },
            font_family = "JetBrainsMonoNL Nerd Font Mono",
            font_size = 20,
            height = 20,
            indicator_height = 20,
            render_titles = true,
            rounding = 5,
        },
    },
    decoration = {
        rounding = 8,
        active_opacity = 1,
        inactive_opacity = 0.8,
        fullscreen_opacity = 1,
        blur = {
            enabled = true,
            size = 3,
            passes = 5,
            new_optimizations = true,
            ignore_opacity = true,
            xray = false,
            popups = true,
            contrast = 1.2,
            brightness = 1,
        },
        shadow = {
            enabled = true,
            range = 15,
            render_power = 4,
            color = wal("background_50", "rgba(160c0980)"),
        },
    },
    animations = { enabled = true },
    dwindle = { preserve_split = true },
    master = { new_status = "master" },
    misc = {
        force_default_wallpaper = 1,
        disable_hyprland_logo = true,
    },
    input = {
        kb_layout = "de",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = { natural_scroll = false },
        tablet = { output = monitor1 },
    },
    gestures = { workspace_swipe_touch = false },
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

local animations = {
    { "global", 1, 10, "default" },
    { "border", 1, 5.39, "easeOutQuint" },
    { "windows", 1, 4.79, "easeOutQuint" },
    { "windowsIn", 1, 4.1, "easeOutQuint", "popin 87%" },
    { "windowsOut", 1, 1.49, "linear", "popin 87%" },
    { "fadeIn", 1, 1.73, "almostLinear" },
    { "fadeOut", 1, 1.46, "almostLinear" },
    { "fade", 1, 3.03, "quick" },
    { "layers", 1, 3.81, "easeOutQuint" },
    { "layersIn", 1, 4, "easeOutQuint", "fade" },
    { "layersOut", 1, 1.5, "linear", "fade" },
    { "fadeLayersIn", 1, 1.79, "easeOutQuint" },
    { "fadeLayersOut", 1, 1.39, "easeOutQuint" },
    { "workspaces", 1, 1.94, "almostLinear", "fade" },
    { "workspacesIn", 1, 1.21, "almostLinear", "fade" },
    { "workspacesOut", 1, 1.94, "almostLinear", "fade" },
}
for _, animation in ipairs(animations) do
    hl.animation({ leaf = animation[1], enabled = true, speed = animation[3], bezier = animation[4], style = animation[5] })
end

local function layer_rule(match, effects)
    effects.match = match
    hl.layer_rule(effects)
end

layer_rule({ namespace = "rofi" }, { blur = true, xray = true, blur_popups = true, ignore_alpha = 0 })
layer_rule({ namespace = "swaync-control-center" }, { blur = true, ignore_alpha = 0.5 })
layer_rule({ namespace = "swaync-notification-window" }, { blur = true, ignore_alpha = 0.5 })

local function window_rule(match, effects)
    effects.match = match
    hl.window_rule(effects)
end

window_rule({ class = "^(vesktop)$" }, { workspace = "10" })
window_rule({ class = "^(discord)$" }, { workspace = "10" })
window_rule({ class = "^(Spotify)$" }, { workspace = "10" })
window_rule({ class = "^(steam)$" }, { workspace = "9" })
window_rule({ class = "^(steam_app_).*$" }, { fullscreen = true, monitor = monitor1 })
window_rule({ class = "^(org.kde.dolphin)$", title = "^(Copying.*Dolphin)$" }, { no_initial_focus = true, float = true })
window_rule({ class = "^(org.kde.dolphin)$" }, { float = true })
window_rule({ class = "^(com.saivert.pwvucontrol)$" }, { float = true })
window_rule({ class = "^(nm-connection-editor)$" }, { float = true })
window_rule({ class = "^(1Password)$" }, { float = true })
window_rule({ class = "^(com.interversehq.qView)$" }, { float = true })
window_rule({ class = "^(PureRef)$" }, { float = true })

for _, class in ipairs({ "firefox" }) do
    window_rule({ class = "^(" .. class .. ")$" }, { opacity = "0.8 override 0.8 override" })
end
for _, class in ipairs({
    "jetbrains-idea", "jetbrains-idea-ce", "jetbrains-idea-ultimate", "idea", "IntelliJ IDEA",
    "com.jetbrains.IntelliJ-IDEA", "jetbrains-rider", "Rider", "com.jetbrains.Rider",
    "jetbrains-studio", "android-studio", "com.google.android.studio",
}) do
    window_rule({ class = "^(" .. class .. ")$" }, { opacity = "0.9 override 0.9 override" })
end
for _, class in ipairs({ "com.interversehq.qView", "PureRef", "krita" }) do
    window_rule({ class = "^(" .. class .. ")$" }, { opacity = "1 override 1 override" })
end
window_rule({ class = ".*" }, { suppress_event = "maximize" })
window_rule({ class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false }, { no_focus = true })

local function bind(key, dispatcher, options)
    hl.bind(key, dispatcher, options)
end

bind(main_mod .. " + T", hl.dsp.exec_cmd(terminal))
bind(main_mod .. " + Q", hl.dsp.window.close())
bind(main_mod .. " + L", hl.dsp.exec_cmd("hyprlock"))
bind(main_mod .. " + M", hl.dsp.exit())
bind(main_mod .. " + E", hl.dsp.exec_cmd(file_manager))
bind(main_mod .. " + D", hl.dsp.window.float({ action = "toggle" }))
bind(main_mod .. " + RETURN", hl.dsp.window.fullscreen())
bind(main_mod .. " + R", hl.dsp.exec_cmd(menu_launcher))
bind(main_mod .. " + PERIOD", hl.dsp.exec_cmd(menu_emoji))
bind(main_mod .. " + P", hl.dsp.window.pseudo())
bind(main_mod .. " + J", hl.dsp.layout("togglesplit"))
bind(main_mod .. " + TAB", hl.dsp.exec_cmd("hyprswitch gui --mod-key tab --key tab --max-switch-offset 9 --hide-active-window-border"))
bind(main_mod .. " + V", hl.dsp.exec_cmd(scripts .. "/clip-manager.sh"))
bind(main_mod .. " + W", hl.dsp.submap("wallpaper"))

hl.define_submap("wallpaper", function()
    bind("right", hl.dsp.exec_cmd(scripts .. "/wallpaper-switch.sh next"))
    bind("left", hl.dsp.exec_cmd(scripts .. "/wallpaper-switch.sh previous"))
    bind("down", hl.dsp.exec_cmd(scripts .. "/wallpaper-switch.sh next-dir"))
    bind("up", hl.dsp.exec_cmd(scripts .. "/wallpaper-switch.sh previous-dir"))
    bind("escape", hl.dsp.submap("reset"))
    bind("W", hl.dsp.submap("reset"))
    bind("RETURN", hl.dsp.submap("reset"))
    bind("SPACE", hl.dsp.submap("reset"))
    bind("BACKSPACE", hl.dsp.submap("reset"))
end)

bind("PRINT", hl.dsp.exec_cmd("hyprshot -m output -o ~/Pictures/Screenshots"))
bind(main_mod .. " + SHIFT + S", hl.dsp.exec_cmd("hyprshot -m region -z --clipboard-only"))
bind(main_mod .. " + left", hl.dsp.focus({ direction = "left" }))
bind(main_mod .. " + right", hl.dsp.focus({ direction = "right" }))
bind(main_mod .. " + up", hl.dsp.focus({ direction = "up" }))
bind(main_mod .. " + down", hl.dsp.focus({ direction = "down" }))
bind(main_mod .. " + CTRL + right", hl.dsp.focus({ workspace = "r+1" }))
bind(main_mod .. " + CTRL + left", hl.dsp.focus({ workspace = "r-1" }))
bind(main_mod .. " + SHIFT + CTRL + right", hl.dsp.window.move({ workspace = "r+1" }))
bind(main_mod .. " + SHIFT + CTRL + left", hl.dsp.window.move({ workspace = "r-1" }))
bind(main_mod .. " + SHIFT + Left", hl.dsp.window.move({ direction = "left" }))
bind(main_mod .. " + SHIFT + Right", hl.dsp.window.move({ direction = "right" }))
bind(main_mod .. " + SHIFT + Up", hl.dsp.window.move({ direction = "up" }))
bind(main_mod .. " + SHIFT + Down", hl.dsp.window.move({ direction = "down" }))
bind(main_mod .. " + G", hl.dsp.group.next())
bind(main_mod .. " + SHIFT + G", hl.dsp.group.toggle())
for i = 1, 10 do
    local key = i % 10
    bind(main_mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    bind(main_mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
bind(main_mod .. " + F", hl.dsp.window.fullscreen({ mode = 1 }))
bind(main_mod .. " + O", hl.dsp.exec_cmd(scripts .. "/magic-workspace-toggle.sh"))
bind(main_mod .. " + SHIFT + O", hl.dsp.workspace.toggle_special("magic"))
bind(main_mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
bind(main_mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
bind(main_mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
bind(main_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
bind("mouse:278", hl.dsp.exec_cmd("pamixer -d 5"), { repeating = true })
bind("mouse:277", hl.dsp.exec_cmd("pamixer -i 5"), { repeating = true })

local media_options = { locked = true, repeating = true }
bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), media_options)
bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), media_options)
bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), media_options)
bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), media_options)
bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s 10%+"), media_options)
bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"), media_options)
bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd("brightnessctl -d 'asus::kbd_backlight' s 1+"), media_options)
bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd("brightnessctl -d 'asus::kbd_backlight' s 1-"), media_options)
bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
