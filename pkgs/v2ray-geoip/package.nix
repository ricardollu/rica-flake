{
  lib,
  fetchFromGitHub,
  pkgsBuildBuild,
  dbip-country-lite,
  v2ray-geoip,
}:

let
  source = lib.importJSON ./sources.json;
in
v2ray-geoip.override {
  inherit dbip-country-lite;

  fetchFromGitHub =
    args:
    fetchFromGitHub (
      args
      // (if args ? tag then { tag = source.version; } else { rev = source.version; })
      // { inherit (source) hash; }
    );

  pkgsBuildBuild = pkgsBuildBuild // {
    buildGoModule = args: pkgsBuildBuild.buildGoModule (args // { inherit (source) version vendorHash; });
  };
}
