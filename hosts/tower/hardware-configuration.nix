{
  lib,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  boot = {
    kernelParams = [
      "amdgpu.gpu_recovery=1"
      "amdgpu.ppfeaturemask=0xfffd3fff"
      "split_lock_detect=off"
    ];
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "nvme"
      "usbhid"
    ];
    kernelModules = [
      "kvm-amd"
      "coretemp"
      # WiFi and Bluetooth drivers for PCIe WiFi card
      "iwlwifi"
      "btusb"
      "bluetooth"
      "btintel"
    ];
    # do not load driver for motherboard's WiFi+Bluetooth chip, it sucks ass,
    # ensure the PCIe WiFi+Bluetooth card is used instead
    blacklistedKernelModules = [
      "mt7921e"
    ];
  };
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/d6f1cc32-5216-43eb-a22c-339f1e0ebabf";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/264C-1D31";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };

    "/mnt/storage" = {
      device = "/dev/disk/by-uuid/aad56a7c-b586-4e16-b91f-58fbd796f400";
      fsType = "ext4";
    };
  };

  swapDevices = [ ];
  networking = {
    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    useDHCP = lib.mkDefault true;
    networkmanager = {
      enable = true;
      wifi.powersave = false;
    };
  };
  # networking.interfaces.eno2.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlo1.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = "performance";
  powerManagement.powertop.enable = true;

  # See: https://wiki.nixos.org/wiki/AMD_GPU#Sporadic_Crashes
  services.lact.enable = true;
  hardware = {
    amdgpu.overdrive.enable = true;
    cpu.amd.updateMicrocode = true;
    enableRedistributableFirmware = true;
    enableAllHardware = true;
  };
}
