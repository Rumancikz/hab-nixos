# Hardware configuration for hab-atlas.
#
# Kernel/interface data generated on the box (nixos-generate-config);
# fileSystems section is still missing and must be filled in BEFORE the
# first rebuild. Get the real devices from the running box:
#
#   ssh atlas@10.0.0.2 'sudo cat /etc/nixos/hardware-configuration.nix'
#   # or: ssh atlas@10.0.0.2 'sudo findmnt -no SOURCE,FSTYPE /; sudo findmnt -no SOURCE /boot'
#
# Until then this file fails evaluation on purpose (see assertions) so
# nobody deploys a /etc/fstab pointing at nonexistent devices.
{ config, lib, pkgs, modulesPath, ... }:
{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  # TODO: real root device, e.g. /dev/disk/by-uuid/... (ext4)
  fileSystems."/" =
    { device = "TODO-root-device";
      fsType = "ext4";
    };

  # TODO: real EFI system partition device (vfat, mounted at /boot)
  fileSystems."/boot" =
    { device = "TODO-boot-device";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "uas" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp1s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp2s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Fail fast until the placeholders above are replaced — deploying with
  # them would write a /etc/fstab pointing at nonexistent devices.
  assertions = [
    {
      assertion = config.fileSystems."/".device != "TODO-root-device";
      message = "hab-atlas: set the device of the fileSystems '/' entry to the real root device (see header comment in hosts/hab-atlas/hardware-configuration.nix)";
    }
    {
      assertion = config.fileSystems."/boot".device != "TODO-boot-device";
      message = "hab-atlas: set the device of the fileSystems '/boot' entry to the real /boot ESP device (see header comment in hosts/hab-atlas/hardware-configuration.nix)";
    }
  ];
}
