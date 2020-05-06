let
  sources = import ./nix/sources.nix;
  all-hies = import (fetchTarball "https://github.com/Infinisil/all-hies/tarball/master") {};
in { compiler ? "ghc882", pkgs ? import sources.nixpkgs { } }:
let
  inherit (pkgs.lib.trivial) flip pipe;
  inherit (pkgs.haskell.lib) appendPatch appendConfigureFlags;

  haskellPackages = pkgs.haskell.packages.${compiler}.override {
    overrides = new: old: {
      hakyll =
        pipe (new.callPackage ./nix/hakyll.nix { }) [
          (flip appendPatch ./nix/hakyll.patch)
          (flip appendConfigureFlags [ "-f" "watchServer" "-f" "previewServer" ])
        ];
        hakyll-nix = new.callCabal2nix "hakyll-nix" ./. { };
        niv = import sources.niv { };
      };
    };

    project = haskellPackages.hakyll-nix;
in
  {
    project = project;
    shell = haskellPackages.shellFor {
      packages = p: with p; [ project ];
      buildInputs = with haskellPackages; [
        cabal-install
        ghcid
        hlint
        (all-hies.selection { selector = p: { ${compiler} = builtins.getAttr compiler p;}; })
        ormolu
        niv.niv
      ];
      withHoogle = true;
    };
  }
