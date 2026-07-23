#!/bin/bash
if [ "$(playerctl status 2>/dev/null)" = "Playing" ]; then
    song_info=$(playerctl metadata --format '{{title}}   <span> {{artist}}</span>')
    echo "$song_info" 
else
    echo ""
fi