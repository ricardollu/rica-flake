# v2ray-geoip 的数据来源，db-ip 每月发一版。
# 下载地址是上游按 version 拼出来的，overrideAttrs 改掉 version 之后地址会跟着变，
# 所以只需要额外把 fetchurl 的哈希换掉。
{
  lib,
  fetchurl,
  dbip-country-lite,
}:

let
  source = lib.importJSON ./sources.json;
in
(dbip-country-lite.override {
  fetchurl = args: fetchurl (args // { inherit (source) hash; });
}).overrideAttrs
  (_: {
    inherit (source) version;
    # 光改 version 不改 src 会被 nixpkgs 警告，这里 src 是跟着 version 走的，不是漏改
    __intentionallyOverridingVersion = true;
  })
