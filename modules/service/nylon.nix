{
  config,
  lib,
  pkgs,
  self,
  ...
}:

with lib; let
  cfg = config.modules.service.nylon;
  username = config.modules.system.username;
  nylon = pkgs.buildGoModule (finalAttrs: {
    pname = "nylon-wg";
    version = "0.3.2";
    outputs = [
      "out"
    ];
    runtimeInputs = [ pkgs.iproute2 ];
    src = pkgs.fetchFromGitHub {
      owner = "encodeous";
      repo = "nylon";
      tag = "v${finalAttrs.version}";
      hash = "sha256-IH3S96HL6FR9L7vbZLqwMlKCP+EpU5ZoDlO872R9pPM=";
    };
    vendorHash = "sha256-az1Qf01x7Mx7lFdp1zNNCELXQf+7/uWMTKGxSK+TRGE=";
    meta = {
      homepage = "https://github.com/encodeous/nylon";
      description = "Nylon is a Resilient Overlay Network built from WireGuard, designed to be performant, secure, reliable, and most importantly, easy to use.";
      license = lib.licenses.mit;
      mainProgram = "nylon";
      maintainers = with lib.maintainers; [
      ];
    };
  }); 
in {

  options.modules.service.nylon = {
    enable = mkEnableOption "Enable nylon";
    
    centralConfig = mkOption {
      type = types.str;
      default = (self + "/secrets/nylon.central.age");
      description = "Nylon Central config";
    };
    nodeConfig = mkOption {
      type = types.str;
      default = (self + "/secrets/nylon."+config.networking.hostName+".age");
      description = "Nylon Node specific config";
    };
  };


 config = mkIf cfg.enable {
  age.secrets.nylon_central.file = cfg.centralConfig;
  age.secrets.nylon_node.file = cfg.nodeConfig;

  environment.systemPackages = [nylon];

  systemd.services.nylon = {
     description = "Nylon Service";
     serviceConfig = {
       ExecStart = "${nylon}/bin/nylon run -c ${config.age.secrets.nylon_central.path} -n ${config.age.secrets.nylon_node.path}";
       Restart = "on-failure";
     };
      path = [
        pkgs.iproute2
      ];
     wantedBy = [ "multi-user.target" ];
   };

  };

}
