# Wallpaper Collections

Project-level wallpaper collections live here so rices can reference a shared
library instead of storing every wallpaper inside theme dotfiles.

- `40k/`: Warhammer 40k themed wallpapers.
- `artistic/`: general illustrated and atmospheric wallpapers.

Themes can choose wallpaper directories and a standard wallpaper in
`themes/<theme>/theme.conf`:

```bash
wallpaper_dirs=(
  wallpapers/artistic
)
wallpaper=wallpapers/artistic/ruan-jia.jpg
fallback_wallpaper=wallpapers/artistic/ruan-jia.jpg
```

If `wallpaper_dirs` is not specified, shared wallpaper setup falls back to
`wallpapers/artistic`. If `wallpaper` is not specified, the first image in the
configured directories is used. If that also fails, `fallback_wallpaper` is used.

Shared setup code can call `resolve_theme_wallpaper_config` from
`scriptdata/wallpapers`.
It fills:

- `THEME_WALLPAPER_DIRS`
- `THEME_WALLPAPER`
- `THEME_FALLBACK_WALLPAPER`

Theme setup scripts can then decide how to apply that information, for example
with pywal, hyprpaper, swww, or another wallpaper backend.

The `sssystem-theme` Hyprland config uses `wallpaper-switch.sh` to cycle through
`THEME_WALLPAPER_DIRS` and run pywal for each selected wallpaper.
