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
          ps.more-itertools
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
            ${myPython}/bin/python3 ./render.py
          '';
        };
        a = pkgs.stdenv.mkDerivation {
          name = "a";
          src = ./sequencelib;
          buildPhase = ''
            mkdir -p $out
            echo "a" > $out/a
          '';
        };
        b = pkgs.stdenv.mkDerivation {
          name = "b";
          src = ./sequencelib;
          buildPhase = ''
            mkdir -p $out
            echo "b" > $out/b
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
          buildInputs = [ myPython ];
          buildPhase = ''
            patchShebangs --build src/components
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
          npmDeps = pkgs.importNpmLock { npmRoot = ./sequencelib; };
          npmConfigHook = pkgs.importNpmLock.npmConfigHook;
          nodejs = node;
          SIDEBAR_OUTPUT = "${sequences}/sidebar.json";
          SEQUENCELIB_LEAN_INFO = "${sequencelib-lean-info}/sequencelib_lean_info.json";
          buildInputs = [ myPython ];
          buildPhase = ''
            patchShebangs --build src/components
            ${pkgs.rsync}/bin/rsync -a --chmod=ug+rw ${makeCache}/{.astro,.vite} .
            mkdir -p src/content/docs/sequences $out
            ln -s ${sequences}/sequences/${block} src/content/docs/sequences/${block}
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
        site =
          let
            blocks = builtins.attrNames (pkgs.lib.importJSON "${sequences}/sidebar.json");
          in
          buildForBlocks blocks;
      in
      {
        packages = {
          default = site;
          inherit sequences makeCache;
          inherit a b;
          foo = buildBlock "A001";
          bar = buildBlock "A002";
          baz = buildBlock "A003";
          spam = buildBlock "A004";
          spam5 = buildBlock "A005";
          spam6 = buildBlock "A006";
          spam10 = buildBlock "A010";
          spam11 = buildBlock "A011";
          spam13 = buildBlock "A013";
          spam14 = buildBlock "A014";
          spam15 = buildBlock "A015";
          spam16 = buildBlock "A016";
          spam17 = buildBlock "A017";
          blocks = buildForBlocks [ "A000" "A001" "A002" "A351" ];
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
