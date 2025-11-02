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
        makeSrc = src: pkgs.buildNpmPackage {
          inherit src;
          name = "cache";
          dontNpmBuild = true;
          dontNpmInstall = true;
          npmDeps = pkgs.importNpmLock { npmRoot = ./sequencelib; };
          npmConfigHook = pkgs.importNpmLock.npmConfigHook;
          nodejs = node;
          SIDEBAR_OUTPUT = "${sequences}/sidebar.json";
          SEQUENCELIB_LEAN_INFO = "${sequencelib-lean-info}/sequencelib_lean_info.json";
          buildInputs = [ myPython pkgs.perl ];
          buildPhase = ''
            patchShebangs --build src/components
            mkdir -p $out/public_html
            npx astro build
            mv .astro .vite $out
            ${pkgs.rsync}/bin/rsync -a dist/ $out/public_html
          '';
        };
        filteredSrc = builtins.path {
          name = "filtered-src";
          path = ./sequencelib;
          filter = path: type: type != "directory" || baseNameOf path != "content";
        };
        makeCache = (makeSrc filteredSrc).overrideAttrs (final: prev: {
          buildPhase = ''
            ${pkgs.perl}/bin/perl -i -0pe \
              's/sidebar: \[.*?\],\n *social/sidebar: [],\n      social/s' \
              astro.config.mjs
          '' + prev.buildPhase;
        });
        makeFull = makeSrc ./sequencelib;
        buildBlock = block: pkgs.buildNpmPackage {
          name = "block-${block}";
          src = filteredSrc;
          dontNpmBuild = true;
          dontNpmInstall = true;
          npmDeps = pkgs.importNpmLock { npmRoot = ./sequencelib; };
          npmConfigHook = pkgs.importNpmLock.npmConfigHook;
          nodejs = node;
          SIDEBAR_OUTPUT = "${sequences}/sidebar.json";
          SEQUENCELIB_LEAN_INFO = "${sequencelib-lean-info}/sequencelib_lean_info.json";
          buildInputs = [ myPython ];
          buildPhase = ''
            ${pkgs.perl}/bin/perl -i -0pe \
              's/sidebar: \[.*?\],\n *social/sidebar: [{label: "Sequences", items: sequencesConfig}],\n      social/s' \
              astro.config.mjs
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
            npmDeps = pkgs.importNpmLock { npmRoot = ./sequencelib; };
            npmConfigHook = pkgs.importNpmLock.npmConfigHook;
            nodejs = node;
            buildPhase = ''
              mkdir -p $out
              ${pkgs.rsync}/bin/rsync -a --chmod=ug+rw ${makeFull}/public_html $out
              ${pkgs.rsync}/bin/rsync -a -L --chmod=ug+rw ${bs}/ $out/public_html
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
          inherit sequences makeCache makeFull;
          blocks = buildForBlocks [ "A000" "A001" "A002" ];
        };

        devShell = shell {
          name = "sequencelib-site";
          packages = with pkgs; [
            importNpmLock.hooks.linkNodeModulesHook
            node
          ];
          npmDeps = pkgs.importNpmLock.buildNodeModules {
            npmRoot = ./sequencelib;
            nodejs = node;
          };
          buildInputs = with pkgs; [
            myPython
            go-task
            node
          ] ++ lib.optional stdenv.isDarwin apple-sdk_14;
        };
      }
    );
}
