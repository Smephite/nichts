# which default packages to use for the system
{pkgs, ...}: {
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    ganttproject-bin
    texliveFull
    texlab
    zathura
    openocd
    minicom

    tesseract
    poppler-utils

    claude-code
    zotero-mcp
  ];
}
