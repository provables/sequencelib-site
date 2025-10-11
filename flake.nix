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
        site = pkgs.buildNpmPackage {
          name = "site";
          src = ./sequencelib;
          npmDepsHash = "sha256-k7wpby8pFhdANuM2AaHS6d3PFH12pkFnlcJSNQNG9HM=";
          nodejs = node;
          installPhase = ''
            runHook preInstall
            mkdir -p $out/public_html
            ${pkgs.rsync}/bin/rsync -a dist/ $out/public_html
            runHook postInstall
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
            node
          ] ++ lib.optional stdenv.isDarwin apple-sdk_14;
        };
      }
    );
}
