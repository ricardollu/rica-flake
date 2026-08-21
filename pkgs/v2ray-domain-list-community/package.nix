{
  lib,
  fetchFromGitHub,
  pkgsBuildBuild,
  v2ray-domain-list-community,
}:

let
  source = lib.importJSON ./sources.json;
in
v2ray-domain-list-community.override {
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
