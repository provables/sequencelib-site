{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    shell-utils.url = "github:waltermoreira/shell-utils";
    sequencelib-lean-info = {
      url = "git+ssh://git@provables.wetdog.digital/users/git/sequencelib-lean-info.git";
      flake = false;
    };
  };
  outputs = { nixpkgs, flake-utils, shell-utils, sequencelib-lean-info, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        shell = shell-utils.myShell.${system};
        node = pkgs.nodejs_24;
        myPython = pkgs.python313.withPackages (ps: [
          ps.ipython
          ps.jinja2
          ps.networkx
        ]);
        sequences = pkgs.stdenv.mkDerivation {
          name = "sequences";
          src = ./sequencelib/scripts;
          SEQUENCELIB_LEAN_INFO = "${sequencelib-lean-info}/sequencelib_lean_info.json";
          buildInputs = [ myPython ];
          buildPhase = ''
            mkdir -p $out/sequences
            export OUTPUT_DIR=$out/sequences
            export SIDEBAR_OUTPUT=$out/sidebar.json
            ./render.py
          '';
        };
        site = pkgs.buildNpmPackage {
          OUTPUT_DIR = "${sequences}/sequences";
          SIDEBAR_OUTPUT = "${sequences}/sidebar.json";
          SEQUENCELIB_LEAN_INFO = "${sequencelib-lean-info}/sequencelib_lean_info.json";
          NODE_OPTIONS="--max-old-space-size=16364";
          name = "site";
          src = ./sequencelib;
          dontNpmBuild = true;
          dontNpmInstall = true;
          npmDepsHash = "sha256-yCVRCt6fTc/zJy2jHRdWZsu9T3oQnL8h9/RI8ZeMfk4=";
          nodejs = node;
          buildPhase = ''
            export PATH=${pkgs.rsync}/bin:$PATH
            mkdir -p $out/public_html
            export DIST=$out/public_html
            ${myPython}/bin/python3 ./scripts/build.py
          '';
        };
      in
      {
        packages = {
          default = site;
          inherit sequences;
        };

        devShell = shell {
          name = "sequencelib-site";
          buildInputs = with pkgs; [
            myPython
            go-task
            node
          ] ++ lib.optional stdenv.isDarwin apple-sdk_14;
        };
      }
    );
}
