#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

echo "Install Xfce4 UI components"
add-apt-repository -y ppa:gottcode/gcppa 
apt-get update 
apt-get install -y x11-xserver-utils supervisor xfce4 xfce4-terminal xfce4-whiskermenu-plugin libwebkitgtk-1.0-0 adwaita-icon-theme 
apt-get purge -y pm-utils xscreensaver
apt-get clean -y
