{pkgs, ...}: {
  fonts.packages = with pkgs; [
    material-design-icons
    (nerdfonts.override {
      fonts = ["JetBrainsMono" "Iosevka"];
    })
    iosevka
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-emoji
  ];
}
