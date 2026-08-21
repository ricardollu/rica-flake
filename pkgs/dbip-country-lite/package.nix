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
