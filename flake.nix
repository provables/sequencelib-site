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
        makeCache = pkgs.buildNpmPackage {
          name = "cache";
          src = ./sequencelib;
          dontNpmBuild = true;
          dontNpmInstall = true;
          npmDepsHash = "sha256-yCVRCt6fTc/zJy2jHRdWZsu9T3oQnL8h9/RI8ZeMfk4=";
          nodejs = node;
          SIDEBAR_OUTPUT = "${sequences}/sidebar.json";
          SEQUENCELIB_LEAN_INFO = "${sequencelib-lean-info}/sequencelib_lean_info.json";
          buildPhase = ''
            mkdir -p $out/public_html
            npx astro build
            mv .astro .vite $out
            ${pkgs.rsync}/bin/rsync -a dist/ $out/public_html
          '';
        };
        buildBlock = block: pkgs.buildNpmPackage {
          name = "block-${block}";
          src = ./sequencelib;
          dontNpmBuild = true;
          dontNpmInstall = true;
          npmDepsHash = "sha256-yCVRCt6fTc/zJy2jHRdWZsu9T3oQnL8h9/RI8ZeMfk4=";
          nodejs = node;
          SIDEBAR_OUTPUT = "${sequences}/sidebar.json";
          SEQUENCELIB_LEAN_INFO = "${sequencelib-lean-info}/sequencelib_lean_info.json";
          buildPhase = ''
            ${pkgs.rsync}/bin/rsync -a --chmod=ug+rw ${makeCache}/{.astro,.vite} .
            mkdir -p src/content/docs/sequences $out
            ln -s ${sequences}/sequences/${block} src/content/docs/sequences/${block}
            ${pkgs.gnused}/bin/sed -i -e 's/pagefind: .*,/pagefind: false,/' astro.config.mjs
            npx astro build
            ${pkgs.rsync}/bin/rsync -a dist/${block} $out/
          '';
        };
        buildForBlocks = blocks:
          let
            bs = pkgs.linkFarm "linked" (builtins.map
              (block: { name = block; path = "${buildBlock block}/${block}"; })
              blocks);
          in
          pkgs.buildNpmPackage {
            name = "buildForBlocks";
            src = ./sequencelib;
            dontNpmBuild = true;
            dontNpmInstall = true;
            npmDepsHash = "sha256-yCVRCt6fTc/zJy2jHRdWZsu9T3oQnL8h9/RI8ZeMfk4=";
            nodejs = node;
            buildPhase = ''
              mkdir -p $out
              ${pkgs.rsync}/bin/rsync -a --chmod=ug+rw ${makeCache}/public_html $out
              # ln -s ${bs}/* $out/public_html
              ${pkgs.rsync}/bin/rsync -av -L --chmod=ug+rw ${bs}/ $out/public_html
              npx pagefind --site $out/public_html
            '';
          };
        site = pkgs.buildNpmPackage {
          OUTPUT_DIR = "${sequences}/sequences";
          SIDEBAR_OUTPUT = "${sequences}/sidebar.json";
          SEQUENCELIB_LEAN_INFO = "${sequencelib-lean-info}/sequencelib_lean_info.json";
          NODE_OPTIONS = "--max-old-space-size=16364";
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
          inherit sequences makeCache;
          foo = buildBlock "A001";
          bar = buildBlock "A002";
          blocks = buildForBlocks [ "A001" "A002" ];
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
