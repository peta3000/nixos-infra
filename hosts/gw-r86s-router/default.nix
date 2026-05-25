{ config, lib, pkgs, ... }:

let
  nets = import ../../lib/networks.nix;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base/default.nix
    ../../modules/router/default.nix
    ../../modules/users/peter/age.nix
    ../../modules/common/network-tools.nix
  ];
 
  # Boot parameters for eMCC
  boot.kernelParams = [ "intremap=off" "irqpoll" ];

  # Basic system configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Use latest kernel for best SQM/CAKE support
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Swapfile configuration (optional - only if needed)
  swapDevices = [
    { device = "/swapfile"; size = 2048; } # 2GB swapfile
  ];
  # Alternative: No swap for router with sufficient RAM
  # swapDevices = [ ];

  networking.hostName = "gw-r86s-router";
  
  # Basic services
  services.openssh.enable = true;
  
  # Router uses a fully custom nftables ruleset
  networking.firewall.enable = false;

  # Choose WAN interface:
  # - testing: enp1s0
  # - production: enp5s0d1
  router.wan.interface = nets.wan.production;

  # Enable SQM with CAKE for bufferbloat control
  router.sqm = {
    enable = true;
    
    # Set these to ~5-10% below your actual ISP speeds
    # This is crucial for SQM to work effectively
    upstreamBandwidth = "900mbit";   # Adjust for your upload speed
    downstreamBandwidth = "900mbit"; # Adjust for your download speed
    
    # Adjust overhead based on your connection type:
    # Ethernet: 14, VLAN: 18, PPPoE: 30, PPPoE+VLAN: 34
    overheadBytes = 18;  # For VLAN tagged connection
    
    queueSize = "1514";  # MTU (1500) + overhead (14)
  };

  # Optional: static addressing on WAN instead of DHCP (uncomment if needed)
  # systemd.network.networks."wan".networkConfig.DHCP = "no";
  # systemd.network.networks."wan".address = [ "192.168.1.179/24" ];
  # systemd.network.networks."wan".routes = [
  #   { routeConfig.Gateway = "192.168.1.1"; }
  # ];
  # networking.nameservers = [ "192.168.1.10" "192.168.1.1" ];
  
  # User configuration .
  users.users.peter = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
  
  # Allow sudo without password for users
  security.sudo.extraRules = [
    {
      users = [ "peter" ];
      commands = [ { command = "ALL"; options = [ "NOPASSWD" ]; } ];
    }
  ];

  # SSH keys for user peter
  users.users.peter.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDEP5rIrh/WIZvCS8Tb4xkLtCDQAxs27Guxnxv0BQLs2iIe0kSmM+xXcvNCMSrmbNAzq6boSJsQ4PIVQCaSxNRrhcFH6Q1pY9y7MvbRqT72V++dQQtVKMkoVh4QQ5aobsml8KQx7QS6fuwEtMCE/8yoJPoyh1rqAqSS7/9MvA72Imr8LNdAkECDVkzrn3T8/gGJ9gEYFJrLpmm+lEzIU27P/x1BUQOpPbPMourkKdhSBgvr3LQCugEfzdUfskO8YCHmB+5KkCBXizpIH3QiN1TuZuPAT0ZacMAM1gZcZtEWr04K7hXdDgPCJzxDjfruoiOSqFvBYtdtECAb8AGicFqVuIGzIdYVP5pxWKwUR0LUXpSUKIqqF3gKc0HvSejxJ8NA79a2BS7ef7Plou4GmkfH+NdDti0iaS7pi6aqUTMVgGOvbDVTJT1L8clIdgLPomHL9kXae9EuiGHFSqpEC42FRFcmj30heWttG/OAo4Msbcs+ArruAskHJFN366rXRZM="
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICozYQT8O5X3hEKU7toJho+r66As0qaCt3nYXR0gRU0j"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKMFYKNEteD8lN4R6n2yfw1oVet2Tb4FVBpP/qcy5h06 peter@pop-os"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDyH25Sswp2z9JA7g0+hLo51tKxORqPTH8t9E/HZcL229ryaRIS/zGxnN6HfmRtHxf3F8QgreROqnU6n8su8yX5ISIXDKpvo+v9iiFdwAZWwB9J0p31PeDQtS7XEgHeWy5UOnkKd9DIPTPI6GkA1BVp0lEUE8Kb0NjI9MUkwK5Zo7BjgjzDGUEa0T4SGnH0uBGyODeOVe5HrSoIRQmejpDFbfVBPR08gn1emWGMf8K0jRQtgDRmT0sCvQ7jEHJjWJMk31OEC6jZgjcBBWdgo+D7nQhBn+6X1ISZ+EXE+WVuB4gj+by5juV7uBIakbbllTux9bPSbH9t3lmQF1ONrrRgaQ5m8yZE3z8CrplCN06OABQMDNvMJiBgEBrbGRAolnmsE8EYzEg8+3c1dPmMsc8oczx5slK3vVdIR8CunQajM+d8+0eIyxA7wD9SFHsbUj4pl/ZxR4do7n4sGoijUp+cyVEgo3sKFKpEv0JNqNdVHSyHpbGQ19iMLsR6piCrVT8= peter@pop-os"
  ];

  # Enable tailscale
  my.tailscale = {
    enable = true;
    tags = [ "tag:router" ];
  };

  # Age test secret
  age.secrets.test-secret = {
    file = ../../secrets/test-secret.age;
    owner = "peter";
    group = "users";
  };

  # Enable Network-Tools
  my.networkTools.enable = true;


  system.stateVersion = "25.11";

}
