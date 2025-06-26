{
  description = "Nix build helper for NuttX project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    semver.url = "github:cynerd/nixsemver";
  };

  outputs = {
    self,
    nixpkgs,
    semver,
  }: let
    inherit (nixpkgs.lib) genAttrs systems;
    forSystems = genAttrs systems.flakeExposed;
    inherit (semver.lib) changelog;

    name = "template";
    version = changelog.currentRelease ./CHANGELOG.md self.sourceInfo;
    src = {
      src = ./.;
      GIT_REV = self.shortRev or self.dirtyShortRev or "dirty";
      inherit version;
      inherit (self) lastModified;
    };
  in {
    overlays.default = final: _: {
      "${name}" = final.pkgsBuildBuild.callPackage ./nuttx {
        inherit name src;
      };
    };

    packages = forSystems (system: {
      default = self.legacyPackages.${system}."${name}";
    });
    legacyPackages =
      forSystems (system:
        nixpkgs.legacyPackages.${system}.extend self.overlays.default);

    devShells = forSystems (system: {
      default = with self.legacyPackages.${system};
        mkShell {
          packages = [
            qemu
            # Linters and formaters
            clang-tools_18
            muon
            shellcheck
            shfmt
            editorconfig-checker
          ];
          inputsFrom = [
            self.packages.${system}.default
          ];
        };
    });

    formatter = forSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
  };
}
