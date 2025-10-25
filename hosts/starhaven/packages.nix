{pkgs, ...}:
{
  environment.systemPackages = with pkgs; [
    # Dev
    nixfmt
    alejandra
    nixd

    # Homlab
    nylon-wg
    glusterfs
  ];
}