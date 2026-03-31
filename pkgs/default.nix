{
  pkgs,
  withSemantic ? true,
  withPdf ? true,
  withScite ? true,
}:

{
  pyzotero = pkgs.python3Packages.callPackage ./pyzotero.nix { };
  zotero-mcp = pkgs.python3Packages.callPackage ./zotero-mcp.nix {
    pyzotero = pkgs.pyzotero;
    inherit withSemantic withPdf withScite;
  };
}
