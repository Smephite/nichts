{
  buildPythonPackage,
  fetchPypi,
  lib,
  feedparser,
  bibtexparser,
  httpx,
  whenever,
}:

buildPythonPackage rec {
  pname = "pyzotero";
  version = "1.11.0";
  format = "wheel";

  src = fetchPypi {
    inherit pname version;
    format = "wheel";
    dist = "py3";
    python = "py3";
    abi = "none";
    platform = "any";
    hash = "sha256-VDSMczLHnNGs9THyVI/I2MbqMeiemMQgIy2XoZOtlbI=";
  };

  build-system = [ ];

  dependencies = [
    feedparser
    bibtexparser
    httpx
    whenever
  ];

  pythonImportsCheck = [ "pyzotero" ];

  meta = {
    description = "Python wrapper for the Zotero API";
    homepage = "https://github.com/urschrei/pyzotero";
    license = lib.licenses.blueOak100;
    maintainers = [ ];
  };
}
