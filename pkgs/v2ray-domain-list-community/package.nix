# 构建逻辑直接用 nixpkgs 里的 v2ray-domain-list-community，这里只把版本和哈希换成
# sources.json 记录的。上游那个文件把版本写死在内部、没有开放参数，所以只能从它调用的
# fetchFromGitHub 和 buildGoModule 上换掉，它对这两个函数各只调用一次。
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
  # rev 和 tag 上游只会给其中一个，两个同时传给 fetchFromGitHub 会报错
  fetchFromGitHub =
    args:
    fetchFromGitHub (removeAttrs args [ "rev" "tag" ] // { rev = source.version; inherit (source) hash; });

  pkgsBuildBuild = pkgsBuildBuild // {
    buildGoModule = args: pkgsBuildBuild.buildGoModule (args // { inherit (source) version vendorHash; });
  };
}
