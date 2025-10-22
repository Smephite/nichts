{pkgs, ...}:
{
  environment.systemPackages = with pkgs; [
    nixfmt
    comma
    glusterfs
  ];
}