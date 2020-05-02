let
  sources = import ./nix/sources.nix;
in { compiler ? "ghc883", pkgs ? import sources.nixpkgs { } }:
let
  inherit (pkgs.lib.trivial) flip pipe;
  inherit (pkgs.haskell.lib) appendPatch appendConfigureFlags;

  haskellPackages = pkgs.haskell.packages.${compiler}.override {
    overrides = new: old: {
      hakyll =
        pipe old.hakyll [
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
        pkgs.ghcid
        pkgs.ormolu
        pkgs.niv
      ];
      withHoogle = true;
    };
  }
