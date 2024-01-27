{ pkgs, config, ... }: {
  imports = [ ./hardware-configuration.nix ];
  powerManagement.cpuFreqGovernor = "performance";
  users.users.mat.shell = pkgs.fish;
  hardware = {

    # use proprietary nvidia drivers
    opengl.enable = true;
    nvidia = {
      # workaround for Steam new UI bug, change this back to `config.boot.kernelPackages.nvidiaPackages.stable` in the future.
      # see: https://wiki.archlinux.org/title/Steam/Troubleshooting#Steam_window_does_not_show_on_Nvidia_GPUs_after_the_June_14,_2023_update
      # see last answer here: https://discourse.nixos.org/t/using-older-revisions-of-nvidia-drivers/28645
      package = config.boot.kernelPackages.nvidiaPackages.latest;
      modesetting.enable = true;
      nvidiaPersistenced = true;
    };
  };

  programs = {
    fish.enable = true;

    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };

    neovim = {
      enable = true;
      defaultEditor = true;
    };
  };

  environment.variables = {
    SUDO_EDITOR = "nvim";
    EDITOR = "nvim";
  };

  environment.systemPackages = with pkgs; [
    steam-run
    parsec-bin
    mullvad-vpn
    prismlauncher
    # dolphinEmu # dolphin build is suuuuper slow and also broken rn
    rpcs3
  ];
  services.mullvad-vpn.enable = true;

  # for dolphin: https://nixos.wiki/wiki/Dolphin_Emulator
  # boot.extraModulePackages = [ config.boot.kernelPackages.gcadapter-oc-kmod ];

  # to autoload at boot:
  boot.kernelModules = [ "gcadapter_oc" ];
  # services.udev.packages = [ pkgs.dolphinEmu ];
}
