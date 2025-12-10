{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    nylon-wg
    glusterfs
    jq
    openssl
  ];
}
