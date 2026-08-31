{...}: {
  programs.git = {
    enable = true;
    lfs.enable = true;
    signing = {
      signByDefault = true;
      format = "ssh";
    };
  };
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        ForwardAgent = false;
        AddKeysToAgent = "yes";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
        UseKeychain = "yes";
      };
    };
  };
  services.ssh-agent = {
    enable = true;
  };
}
