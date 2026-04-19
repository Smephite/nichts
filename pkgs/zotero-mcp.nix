{
  buildPythonPackage,
  fetchPypi,
  lib,
  hatchling,
  installShellFiles,
  pyzotero,
  mcp,
  python-dotenv,
  pydantic,
  requests,
  fastmcp,
  unidecode,
  markitdown,
  # semantic extras
  withSemantic ? false,
  chromadb,
  sentence-transformers,
  openai,
  google-genai,
  tiktoken,
  # pdf extras
  withPdf ? false,
  pymupdf,
  ebooklib,
  # scite extras
  withScite ? false,
}:
buildPythonPackage rec {
  pname = "zotero-mcp-server";
  version = "0.2.2";
  pyproject = true;

  src = fetchPypi {
    inherit version;
    pname = "zotero_mcp_server";
    hash = "sha256-jN82mAqWS8xEvlqLU9Y5OD26EeJKIBIKvio3Vn6lNbA=";
  };

  build-system = [hatchling];

  nativeBuildInputs = [installShellFiles];

  dependencies =
    [
      pyzotero
      mcp
      python-dotenv
      pydantic
      requests
      fastmcp
      unidecode
      markitdown
    ]
    ++ lib.optionals withSemantic [
      chromadb
      sentence-transformers
      openai
      google-genai
      tiktoken
    ]
    ++ lib.optionals withPdf [
      pymupdf
      ebooklib
    ]
    ++ lib.optionals withScite [
      requests
    ];

  pythonImportsCheck = ["zotero_mcp"];

  postPatch = ''
    patch -p1 < ${./semantic_search.patch}
  '';

  postInstall = ''
    installShellCompletion --fish ${./zotero-mcp.fish}
  '';

  meta = {
    description = "A Model Context Protocol server for Zotero";
    homepage = "https://github.com/54yyyu/zotero-mcp";
    license = lib.licenses.mit;
    maintainers = [];
    mainProgram = "zotero-mcp";
  };
}
