{ config, lib, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Terminal emulators
    kitty
    ghostty

    # Terminal multiplexers
    tmux
    screen
    zellij

    # Terminal recording
    asciinema
    termtosvg

    # Terminal utilities
    tmate
    gotty

    # Terminal UI libraries
    ncurses

    # Clipboard
    xclip
    xsel
    wl-clipboard
  ];
}
