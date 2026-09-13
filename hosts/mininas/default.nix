# hosts/mininas/default.nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix        # The file you scp'd from the NAS
    ../../modules/base/default.nix     # SSH, Firewall, etc.
    ../../modules/common/tailscale.nix # VPN
    ../../modules/common/network-tools.nix
  ];

  networking.hostName = "mininas";

  # Enable diagnostic tools for the health check
  my.networkTools.enable = true;
  my.tailscale.enable = true;

  environment.systemPackages = with pkgs; [
    smartmontools
    tmux
    pciutils
    usbutils
  ];

  # Re-use your 'peter' user settings from the router or workstation
  # (Adjust this to match your existing user block in gw-r86s-router/default.nix)
  users.users.peter = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
       "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICozYQT8O5X3hEKU7toJho+r66As0qaCt3nYXR0gRU0j"
       # ... add your other keys here
    ];
  };

  system.stateVersion = "26.05"; 
}
