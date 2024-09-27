#!/usr/bin/env bash
# test_waybar_with_theme.sh
# Adds the catpuccin theme, generates an output theme file that can be used to test waybar theming
# catppuccin="$HOME/.local/cache/waybar_style_test_catpuccin"
catppuccin="$(mktemp -d)/cat"
if [ ! -d "$catppuccin" ]; then
  mkdir -p catppuccin
  git clone https://github.com/catppuccin/waybar "$catppuccin"
else
  git pull "$catppuccin"
fi
waybar_out=$(mktemp -d)
cp $catppuccin/themes/$1.css $waybar_out/
echo "@import \"$1.css\";" >>$waybar_out/waybar.css
cat waybar.css >>$waybar_out/waybar.css
waybar -s $waybar_out/waybar.css
# while inotifywait -e closewrite waybar.css; do
#   echo "Regenerating waybar.css"
#   cp $catppuccin/themes/$1.css $waybar_out/
#   echo "@import \"$1.css\";" >>$waybar_out/waybar.css
#   cat waybar.css >>$waybar_out/waybar.css
# done
