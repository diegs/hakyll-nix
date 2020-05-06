let
  sources = import ./nix/sources.nix;
  all-hies = import (fetchTarball "https://github.com/Infinisil/all-hies/tarball/master") {};
in { compiler ? "ghc882", pkgs ? import sources.nixpkgs { } }:
let
  inherit (pkgs.lib.trivial) flip pipe;
  inherit (pkgs.haskell.lib) appendPatch appendConfigureFlags;

  haskellPackages = pkgs.haskell.packages.${compiler}.override {
    overrides = new: old: {
      # time-compat = pkgs.haskell.lib.dontCheck old.time-compat;
      hakyll =
        pipe (new.callPackage ./hakyll.nix { }) [
          (flip appendPatch ./hakyll.patch)
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
        pkgs.cabal-install
        # pkgs.ghcid
        # pkgs.hlint
        (all-hies.selection { selector = p: { ${compiler} = builtins.getAttr compiler p;}; })
        # pkgs.ormolu
        # pkgs.niv
        # hakyll
      ];
      withHoogle = true;
    };
  }
