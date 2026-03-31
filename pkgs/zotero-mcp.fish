# Fish shell completions for zotero-mcp

set -l subcommands serve setup update-db db-status db-inspect update version setup-info

# Disable file completions globally
complete -c zotero-mcp -f

# Top-level subcommands
complete -c zotero-mcp -n "not __fish_seen_subcommand_from $subcommands" -a serve       -d "Run the MCP server"
complete -c zotero-mcp -n "not __fish_seen_subcommand_from $subcommands" -a setup       -d "Configure zotero-mcp"
complete -c zotero-mcp -n "not __fish_seen_subcommand_from $subcommands" -a update-db   -d "Update semantic search database"
complete -c zotero-mcp -n "not __fish_seen_subcommand_from $subcommands" -a db-status   -d "Show semantic search database status"
complete -c zotero-mcp -n "not __fish_seen_subcommand_from $subcommands" -a db-inspect  -d "Inspect indexed documents or aggregate stats"
complete -c zotero-mcp -n "not __fish_seen_subcommand_from $subcommands" -a update      -d "Update zotero-mcp to latest version"
complete -c zotero-mcp -n "not __fish_seen_subcommand_from $subcommands" -a version     -d "Print version information"
complete -c zotero-mcp -n "not __fish_seen_subcommand_from $subcommands" -a setup-info  -d "Show installation path and config info"

# serve
complete -c zotero-mcp -n "__fish_seen_subcommand_from serve" -l transport -d "Transport to use" -a "stdio streamable-http sse" -r
complete -c zotero-mcp -n "__fish_seen_subcommand_from serve" -l host      -d "Host to bind to (SSE transport)" -r
complete -c zotero-mcp -n "__fish_seen_subcommand_from serve" -l port      -d "Port to bind to (SSE transport)" -r

# setup
complete -c zotero-mcp -n "__fish_seen_subcommand_from setup" -l no-local            -d "Use Zotero Web API instead of local API"
complete -c zotero-mcp -n "__fish_seen_subcommand_from setup" -l api-key             -d "Zotero API key (web API)" -r
complete -c zotero-mcp -n "__fish_seen_subcommand_from setup" -l library-id          -d "Zotero library ID (web API)" -r
complete -c zotero-mcp -n "__fish_seen_subcommand_from setup" -l library-type        -d "Zotero library type" -a "user group" -r
complete -c zotero-mcp -n "__fish_seen_subcommand_from setup" -l no-claude           -d "Skip Claude Desktop config"
complete -c zotero-mcp -n "__fish_seen_subcommand_from setup" -l config-path         -d "Path to Claude Desktop config file" -r -F
complete -c zotero-mcp -n "__fish_seen_subcommand_from setup" -l skip-semantic-search -d "Skip semantic search configuration"
complete -c zotero-mcp -n "__fish_seen_subcommand_from setup" -l semantic-config-only -d "Only configure semantic search"

# update-db
complete -c zotero-mcp -n "__fish_seen_subcommand_from update-db" -l force-rebuild  -d "Force complete rebuild of the database"
complete -c zotero-mcp -n "__fish_seen_subcommand_from update-db" -l limit          -d "Limit number of items to process" -r
complete -c zotero-mcp -n "__fish_seen_subcommand_from update-db" -l fulltext        -d "Extract fulltext from local Zotero database"
complete -c zotero-mcp -n "__fish_seen_subcommand_from update-db" -l config-path    -d "Path to semantic search config file" -r -F
complete -c zotero-mcp -n "__fish_seen_subcommand_from update-db" -l db-path        -d "Path to zotero.sqlite" -r -F

# db-status
complete -c zotero-mcp -n "__fish_seen_subcommand_from db-status" -l config-path -d "Path to semantic search config file" -r -F

# db-inspect
complete -c zotero-mcp -n "__fish_seen_subcommand_from db-inspect" -l limit          -d "How many records to show (default: 20)" -r
complete -c zotero-mcp -n "__fish_seen_subcommand_from db-inspect" -l filter         -d "Substring to match in title or creators" -r
complete -c zotero-mcp -n "__fish_seen_subcommand_from db-inspect" -l show-documents -d "Show beginning of stored document text"
complete -c zotero-mcp -n "__fish_seen_subcommand_from db-inspect" -l stats          -d "Show aggregate stats"
complete -c zotero-mcp -n "__fish_seen_subcommand_from db-inspect" -l config-path   -d "Path to semantic search config file" -r -F

# update
complete -c zotero-mcp -n "__fish_seen_subcommand_from update" -l check-only -d "Only check for updates without installing"
complete -c zotero-mcp -n "__fish_seen_subcommand_from update" -l force      -d "Force update even if already up to date"
complete -c zotero-mcp -n "__fish_seen_subcommand_from update" -l method     -d "Override installation method" -a "pip uv conda pipx" -r
