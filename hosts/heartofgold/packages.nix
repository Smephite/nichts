# which default packages to use for the system
{pkgs, ...}: {
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    sbctl # secure boot
    bottles

    texliveFull
    texlab
    zathura

    claude-code
    zotero-mcp
    optolith
    optolith-insider
    thedarkaid
  ];
}
