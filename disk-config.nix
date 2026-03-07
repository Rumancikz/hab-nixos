{ lib, ... }:
let
  # ZFS mirror disk IDs - from: ls -la /dev/disk/by-id/ | grep ata-
  diskA = "/dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV2N51Y-part1";
  diskB = "/dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV670K4-part1";
  diskC = "/dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV537CR-part1";

  # zfsDisk creates a disk configuration for ZFS usage
  # Accepts full disk path (e.g., /dev/disk/by-id/ata-YOUR_DISK_MODEL_SERIAL-...)
  zfsDisk = diskPath: {
    type = "disk";
    device = diskPath;
    content = {
      type = "gpt";
      partitions = {
        zsf = {
          size = "100%";
          content = {
            type = "zfs";
            pool = "ocean";
          };
        };
      };
    };
  };
in
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              name = "boot";
              size = "1M";
              type = "EF02";
            };
            esp = {
              name = "ESP";
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              name = "root";
              size = "100%";
              content = {
                type = "btrfs";
                mountpoint = "/";
                mountOptions = [ "compress=zstd" "noatime"];
              };
            };
          };
        };
      };
      # ZFS mirror disks - use variables for disk paths
      sda = zfsDisk diskA;
      sdb = zfsDisk diskB;
      sdc = zfsDisk diskC;
    };
    zpool = {
      ocean = {
        type = "zpool";
        mode = "mirror";
        # Workaround: cannot import 'zroot': I/O error in disko tests
        # options.cachefile = "none";
        rootFsOptions = {
          compression = "zstd";
          "com.sun:auto-snapshot" = "false";
          mountpoint = "none";
        };
        postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^ocean@blank$' || zfs snapshot ocean@blank";
        datasets = {
          tank = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/tank";
            options."com.sun:auto-snapshot" = "true";
          };
        };
      };
    };
  };
}
