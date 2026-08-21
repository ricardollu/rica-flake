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
    in
    {
      # nixpkgs 里的原包一律从 prev 取，用 final 会和这里定义的同名属性互相引用成死循环。
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

      packages = nixpkgs.lib.genAttrs systems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
        in
        {
          inherit (pkgs)
            v2ray-domain-list-community
            v2ray-geoip
            dbip-country-lite
            ;
        }
      );
    };
}
