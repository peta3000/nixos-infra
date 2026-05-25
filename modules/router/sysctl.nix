{ config, lib, ... }:
{
  # Enable routing
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;

    # Reasonable anti-spoofing defaults (tune later if needed)
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;

    # Add these for high-speed performance without SQM:
    "net.core.default_qdisc" = "fq_codel";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_slow_start_after_idle" = 0;
  };
  
  # Ensure the bbr module is loaded
  boot.kernelModules = [ "tcp_bbr" ];

}
