{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    shell-utils.url = "github:waltermoreira/shell-utils";
    sequencelib-lean-info = {
      url = "git+ssh://git@provables.wetdog.digital/users/git/sequencelib-lean-info";
      flake = false;
    };
  };
  outputs = { nixpkgs, flake-utils, shell-utils, sequencelib-lean-info, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        shell = shell-utils.myShell.${system};
        node = pkgs.nodejs_24;
        myPython = pkgs.python313.withPackages (ps: [ ps.ipython ps.jinja2 ]);
        site = pkgs.buildNpmPackage {
          SEQUENCELIB_LEAN_INFO = "${sequencelib-lean-info}/lean_oeis_info.json";
          name = "site";
          src = ./sequencelib;
          npmDepsHash = "sha256-yCVRCt6fTc/zJy2jHRdWZsu9T3oQnL8h9/RI8ZeMfk4=";
          nodejs = node;
          buildInputs = with pkgs; [ myPython ];
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
