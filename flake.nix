{
  description = "rica flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f {
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ self.overlays.default ];
            };
            upstream = nixpkgs.legacyPackages.${system};
          }
        );
    in
    {
      overlays.default = final: prev: {
        v2ray-domain-list-community = final.callPackage ./pkgs/v2ray-domain-list-community/package.nix {
          inherit (prev) v2ray-domain-list-community;
        };

        dbip-country-lite = final.callPackage ./pkgs/dbip-country-lite/package.nix {
          inherit (prev) dbip-country-lite;
        };

        v2ray-geoip = final.callPackage ./pkgs/v2ray-geoip/package.nix {
          inherit (prev) v2ray-geoip;
        };
      };

      packages = forSystems (
        { pkgs, ... }:
        {
          inherit (pkgs)
            v2ray-domain-list-community
            v2ray-geoip
            dbip-country-lite
            ;
        }
      );

      checks = forSystems (
        { pkgs, upstream }:
        {
          file-layout = pkgs.runCommand "file-layout" { } ''
            list() { (cd "$1" && find . -type f | sort); }
            diff <(list ${upstream.v2ray-domain-list-community}) <(list ${pkgs.v2ray-domain-list-community})
            diff <(list ${upstream.v2ray-geoip}) <(list ${pkgs.v2ray-geoip})
            diff <(list ${upstream.dbip-country-lite}) <(list ${pkgs.dbip-country-lite})
            touch $out
          '';
        }
      );
    };
}
