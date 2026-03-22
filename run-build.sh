#!/bin/bash
set -e

mkdir -p sdk-state/build_dir sdk-state/staging_dir sdk-state/dl output

docker run --rm \
  -v "$(pwd):/build" \
  -v "$(pwd)/sdk-state/build_dir:/opt/sdk/build_dir" \
  -v "$(pwd)/sdk-state/staging_dir:/opt/sdk/staging_dir/target-aarch64_generic_musl" \
  -v "$(pwd)/sdk-state/dl:/opt/sdk/dl" \
  openwrt-corosync bash /build/build.sh \
  > output/build.log 2>&1
