{ lib, ... }:
let
  zfsDisk = diskId: {
    type = "disk";
    device = "/dev/sd" + diskId;
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
        sda = zfsDisk "a";
        sdb = zfsDisk "b";
        sdc = zfsDisk "c";
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
            # nix = {
            #   type = "zfs_fs";
            #   options = {
            #     mountpoint = "/home/nix";
            #     atime = "off";
            #     canmount = "on";
            #     "com.sun:auto-snapshot" = "true";
            #   };
            # };
          };
        };
      };
   };
  }
