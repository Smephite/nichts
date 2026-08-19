{
  pkgs,
  inputs,
  ...
}: let
  python-packages = ps:
    with ps; [
      pandas
      numpy
      opencv4
      ipython
      uv
      pyserial
    ];

  # Escape hatch: re-execute a command on the host via self-ssh. Host and
  # sandbox share /home and /scratch, so cwd and paths translate 1:1 — but
  # the host has no /nix, and session env does not cross the boundary.
  on-host = pkgs.writeShellScriptBin "on-host" ''
    if [ $# -eq 0 ]; then
      echo "usage: on-host <command> [args...]" >&2
      exit 2
    fi
    args=""
    for a in "$@"; do args+=" $(printf %q "$a")"; done
    tty_flag=""
    [ -t 0 ] && [ -t 1 ] && tty_flag="-t"
    ssh -q $tty_flag \
      -o BatchMode=yes \
      -o HostbasedAuthentication=no \
      -o StrictHostKeyChecking=accept-new \
      -o ControlMaster=auto \
      -o ControlPath="''${TMPDIR:-/tmp}/on-host-ssh-%r@%h" \
      -o ControlPersist=600 \
      "$(hostname -f)" \
      "cd $(printf %q "$PWD") && PATH=/usr/sepp/bin:\$PATH exec$args"
    rc=$?
    if [ $rc -eq 255 ]; then
      echo "on-host: ssh escape to $(hostname -f) failed — check ~/.ssh and sshd" >&2
    fi
    exit $rc
  '';

  # Run a command inside the sandbox with all nix paths dropped from PATH,
  # so spawned children (sh, make, ...) resolve to host binaries. Needed for
  # SEPP wrappers that LD_PRELOAD host libs (e.g. fs_compiler on rhel8):
  # the nix loader can't resolve their deps and dies on libz.so.1.
  no-nix = pkgs.writeShellScriptBin "no-nix" ''
    if [ $# -eq 0 ]; then
      echo "usage: no-nix <command> [args...]" >&2
      exit 2
    fi
    path=""
    IFS=:
    for p in $PATH; do
      case "$p" in
        /nix/* | */.nix-profile/*) ;;
        *) path="''${path:+$path:}$p" ;;
      esac
    done
    unset IFS
    PATH="$path" exec "$@"
  '';

  # SEPP tools that need setuid helpers on the host (e.g. nested singularity)
  # and therefore cannot run inside the sandbox — shimmed to run via on-host.
  hostRunTools = ["oseda"];
  hostRunShims =
    map (
      tool:
        pkgs.writeShellScriptBin tool ''exec ${on-host}/bin/on-host ${tool} "$@"''
    )
    hostRunTools;
in {
  home.packages = with pkgs;
    [on-host no-nix]
    ++ hostRunShims
    ++ [
    inputs.agenix.packages.${stdenv.hostPlatform.system}.default
    attic-client

    # dev
    nixd
    alejandra
    gnumake
    (python3.withPackages python-packages)
    nodejs
    gcc
    gdb
    cargo
    rustc
    rust-analyzer
    clippy
    nil
    gitlab-ci-local
    glab

    # gui
    zotero
    zed-editor
  ];
}
