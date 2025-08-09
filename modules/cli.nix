{ config, pkgs, pkgs-unstable, lib, inputs, ... }:

{
  # unstable-packages = final: _prev: {
  #   unstable = import inputs.nixpkgs-unstable {
  #     system = final.system;
  #     config.allowUnfree = true;
  #   };
  # };
  programs.zsh.enable = true;
  programs.zsh.autosuggestions.enable = true;
  # This Nix config only contains the settings for the command line.
  environment.systemPackages = (with pkgs; [
    # list of stable packages go here
    # Main utils
    vim
    htop
    tmux
    autojump
    git
    tree-sitter
    busybox
    file
    coreutils-full
    chezmoi
    tree
    usbutils

    # CLI Tools
    dua
    fzf
    bat
    jq
    fx
    fzf
    lf
    ripgrep
  ])

    ++

    (with pkgs-unstable;
      [
        # list of unstable packages go here
        neovim
      ]);
}
