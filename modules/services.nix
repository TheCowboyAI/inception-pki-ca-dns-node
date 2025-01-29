{ lib, ... }:
{
  ## Many services also provide an option to open the required firewall ports automatically.
  ## For example, the media server Jellyfin offers the option services.jellyfin.openFirewall = true; which will open the required TCP ports.
  ## All ports will be opened from networking.nix so that we have a consistent setup !!!
  services = {

    ## Enable QEMU GuestAgent for Proxmox - kvm
    qemuGuest.enable = lib.mkDefault true;

    ## SSH server enabled with keys, no passwords
    openssh = {
      enable = true;
      settings = {
        #PermitRootLogin = lib.mkForce "yes";
        #PasswordAuthentication = lib.mkForce true;
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "prohibit-password"; # "yes", "without-password", "prohibit-password", "forced-commands-only", "no"
      };
    };

    ## https://wiki.nixos.org/wiki/Prometheus
    prometheus = {
      enable = true;
      enableAgentMode = true;
      globalConfig.scrape_interval = "1m";

      exporters.node = {
        enable = true;
        port = 9000;
        enabledCollectors = [ "systemd" ];
      };

      # scrapeConfigs = [
      #   {
      #     job_name = "minio-job";
      #     metrics_path = "/minio/v2/metrics/cluster";
      #     static_configs = [{
      #       targets = [ "172.16.0.2:9000" ];
      #     }];
      #   }
      # ];
    };

    ## https://nixos.wiki/wiki/Fail2ban
    fail2ban = {
      enable = true;
      ## Ban IP after 5 failures
      maxretry = 5;
      # ignoreIP = [
      #   ## Whitelist some subnets
      #   "10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16"
      #   "8.8.8.8" # whitelist a specific IP
      #   "nixos.wiki" # resolve the IP via DNS
      # ];
      bantime = "24h"; # Ban IPs for one day on the first ban
      bantime-increment = {
        enable = true; # Enable increment of bantime after each violation
        ## `formula` and `multipliers` cannot be both specified
        formula = "ban.Time * math.exp(float(ban.Count+1)*banFactor)/math.exp(1*banFactor)";
        ## multipliers = "1 2 4 8 16 32 64";
        maxtime = "168h"; # Do not ban for more than 1 week
        overalljails = true; # Calculate the bantime based on all the violations
      };
      # jails = {
      #   ngnix-url-probe.settings = {
      #     enabled = true;
      #     filter = "nginx-url-probe";
      #     logpath = "/var/log/nginx/access.log";
      #     action = ''%(action_)s[blocktype=DROP]
      #             ntfy'';
      #     backend = "auto"; # Do not forget to specify this if your jail uses a log file
      #     maxretry = 5;
      #     findtime = 600;
      #   };
      # };
    };



  };
}
