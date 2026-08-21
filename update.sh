#!/usr/bin/env bash
# 把 pkgs/*/sources.json 指向各自上游的最新版本，最后构建一次确认可用。
set -euo pipefail

cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

github=(curl -sSfL)
if [[ -n ${GITHUB_TOKEN:-} ]]; then
  github+=(-H "Authorization: Bearer $GITHUB_TOKEN")
fi

edit_sources() {
  local file=$1 tmp
  shift
  tmp=$(mktemp)
  jq "$@" "$file" >"$tmp"
  mv "$tmp" "$file"
}

update_github_release() {
  local name=$1 repo=$2
  local sources=pkgs/$name/sources.json
  local latest current hash log vendor_hash

  latest=$("${github[@]}" "https://api.github.com/repos/$repo/releases/latest" | jq -r .tag_name)
  current=$(jq -r .version "$sources")
  if [[ $latest == "$current" ]]; then
    echo "$name: 已经是 $current"
    return
  fi
  echo "$name: $current -> $latest"

  hash=$(nix flake prefetch --json "github:$repo/$latest" | jq -r .hash)
  edit_sources "$sources" --arg version "$latest" --arg hash "$hash" '.version = $version | .hash = $hash'

  # go.mod 很少变，vendorHash 只在旧值失效时从构建失败信息里读出新值。
  if ! log=$(nix build --no-link ".#$name.generator.goModules" 2>&1); then
    vendor_hash=$(awk '/got:/ { hash = $NF } END { print hash }' <<<"$log")
    if [[ -z $vendor_hash ]]; then
      echo "$log" >&2
      exit 1
    fi
    echo "$name: vendorHash $vendor_hash"
    edit_sources "$sources" --arg vendorHash "$vendor_hash" '.vendorHash = $vendorHash'
  fi
}

update_github_release v2ray-domain-list-community v2fly/domain-list-community
update_github_release v2ray-geoip v2fly/geoip

# db-ip 每月发一版，没有查询接口，只能拿当月的地址去试，还没发就退回上个月。
dbip_current=$(jq -r .version pkgs/dbip-country-lite/sources.json)
dbip_month=
for months_ago in 0 1; do
  month=$(date -u -d "$(date -u +%Y-%m-01) -$months_ago month" +%Y-%m)
  url="https://download.db-ip.com/free/dbip-country-lite-$month.mmdb.gz"
  if curl -sfI -o /dev/null "$url"; then
    dbip_month=$month
    break
  fi
done
if [[ -z $dbip_month ]]; then
  echo "dbip-country-lite: 最近两个月的下载地址都取不到" >&2
  exit 1
fi
if [[ $dbip_month == "$dbip_current" ]]; then
  echo "dbip-country-lite: 已经是 $dbip_current"
else
  echo "dbip-country-lite: $dbip_current -> $dbip_month"
  dbip_hash=$(nix store prefetch-file --json "$url" | jq -r .hash)
  edit_sources pkgs/dbip-country-lite/sources.json \
    --arg version "$dbip_month" --arg hash "$dbip_hash" '.version = $version | .hash = $hash'
fi

nix build --no-link .#v2ray-domain-list-community .#v2ray-geoip .#dbip-country-lite
