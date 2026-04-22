{
  pkgs,
  withSemantic ? true,
  withPdf ? true,
  withScite ? true,
}: {
  pyzotero = pkgs.python3Packages.callPackage ./pyzotero {};
  zotero-mcp = pkgs.python3Packages.callPackage ./zotero-mcp {
    pyzotero = pkgs.pyzotero;
    inherit withSemantic withPdf withScite;
  };
  optolith = pkgs.callPackage ./optolith {};
}
