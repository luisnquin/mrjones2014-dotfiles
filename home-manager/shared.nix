{ pkgs, ... }:
{
  home.sessionVariables = {
    MANPAGER = "nvim -c 'Man!' -o -";
    PAGER = "less -FRX";
  };
  home.packages = [ pkgs.nix-search-cli ];
  imports = [
    ../nixos/nix-conf.nix
    ../nixos/theme.nix
    ./components/fish.nix
    ./components/nvim.nix
    ./components/ssh.nix
    ./components/starship.nix
    ./components/vcs
    ./components/fzf.nix
  ];
}
