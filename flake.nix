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
            mkdir -p $out
            export OUTPUT_DIR=$out
            ./render.py
          '';
        };
        site = pkgs.buildNpmPackage {
          SEQUENCELIB_LEAN_INFO = "${sequencelib-lean-info}/sequencelib_lean_info.json";
          NODE_OPTIONS="--max-old-space-size=16364";
          name = "site";
          src = ./sequencelib;
          npmDepsHash = "sha256-yCVRCt6fTc/zJy2jHRdWZsu9T3oQnL8h9/RI8ZeMfk4=";
          nodejs = node;
          buildInputs = with pkgs; [ myPython ];
          preBuild = ''
            rm -rf src/content/docs/sequences
            ln -s ${sequences} src/content/docs/sequences
            ls -l src/content/docs
          '';
          installPhase = ''
            runHook preInstall
            echo "SEQUENCELIB_LEAN_INFO is $SEQUENCELIB_LEAN_INFO"
            mkdir -p $out/public_html
            ${pkgs.rsync}/bin/rsync -a dist/ $out/public_html
            runHook postInstall
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
