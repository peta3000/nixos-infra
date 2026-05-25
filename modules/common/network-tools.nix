{ pkgs, lib, config, ... }:

{
  options.my.networkTools = {
    enable = lib.mkEnableOption "network diagnostic tools";
  };

  config = lib.mkIf config.my.networkTools.enable {
    environment.systemPackages = with pkgs; [
      # Basic network tools
      nettools      # arp, netstat, route
      iproute2      # ip command (modern replacement)
      bind.dnsutils # dig, nslookup, host
      
      # Network testing & debugging
      mtr          # better traceroute
      iperf3       # bandwidth testing
      tcpdump      # packet capture
      nmap         # network scanning
      socat        # network debugging
      
      # HTTP/web tools
      curl wget    # web requests
      
      # Hardware tools
      ethtool      # ethernet settings
      
      # Analysis (CLI versions)
      wireshark-cli # tshark, etc.

      # Custom diagnostic scripts (bundled from the repo)
      (pkgs.writeShellScriptBin "test-firewall" (builtins.readFile ../../test-firewall.sh))
      (pkgs.writeShellScriptBin "test-sqm" (builtins.readFile ../../test-sqm.sh))

      # Custom DHCP lease viewer
      (pkgs.writeShellScriptBin "show-leases" ''
        printf "%-19s %-17s %-15s %-20s %s\n" "Expires" "MAC Address" "IP Address" "Hostname" "Client ID"
        printf "%s\n" "--------------------------------------------------------------------------------------------------"
        if [ ! -f /var/lib/dnsmasq/dnsmasq.leases ]; then
          echo "No leases file found at /var/lib/dnsmasq/dnsmasq.leases"
          exit 0
        fi
        while read -r expires mac ip host cid; do
          if [ "$expires" -eq 0 ]; then
            date_str="Static/Infinite"
          else
            date_str=$(date -d "@$expires" "+%Y-%m-%d %H:%M:%S")
          fi
          printf "%-19s %-17s %-15s %-20s %s\n" "$date_str" "$mac" "$ip" "$host" "$cid"
        done < /var/lib/dnsmasq/dnsmasq.leases
      '')
    ];
  };
}
