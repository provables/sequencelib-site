{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    shell-utils.url = "github:waltermoreira/shell-utils";
  };
  outputs = { nixpkgs, flake-utils, shell-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        shell = shell-utils.myShell.${system};
        node = pkgs.nodejs_24;
        npmDeps = pkgs.importNpmLock.buildNodeModules {
          npmRoot = ./sequencelib;
          nodejs = node;
        };
        site = pkgs.stdenv.mkDerivation {
          name = "site";
          src = ./sequencelib;
          buildInputs = [ node npmDeps ];
          buildPhase = ''
            ln -s ${npmDeps}/node_modules
            export HOME=$(mktemp -d)
            npm run astro telemetry disable
            npm run build
            mkdir -p $out/public_html
            mv dist/* $out/public_html
          '';
        };
      in
      {
        packages = {
          default = site;
        };

        devShell = shell {
          name = "sequencelib-site";
          buildInputs = with pkgs; [
            go-task
            nodejs_24
          ] ++ lib.optional stdenv.isDarwin apple-sdk_14;
        };
      }
    );
}
