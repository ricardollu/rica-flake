# 同 v2ray-domain-list-community，只换版本和哈希。
# 输出的数据来自 dbip-country-lite，这里换成本仓库那个更新的版本；sources.json 记录的
# 版本只是生成器 v2fly/geoip 本身。
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
    fetchFromGitHub (removeAttrs args [ "rev" "tag" ] // { rev = source.version; inherit (source) hash; });

  pkgsBuildBuild = pkgsBuildBuild // {
    buildGoModule = args: pkgsBuildBuild.buildGoModule (args // { inherit (source) version vendorHash; });
  };
}
