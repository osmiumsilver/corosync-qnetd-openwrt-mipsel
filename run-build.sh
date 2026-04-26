#!/bin/bash
set -e

mkdir -p sdk-state/build_dir sdk-state/feeds sdk-state/dl output

docker run --rm --init \
  -v "$(pwd):/build" \
  -v "$(pwd)/sdk-state/build_dir:/opt/sdk/build_dir" \
  -v "$(pwd)/sdk-state/dl:/opt/sdk/dl" \
  -v "$(pwd)/sdk-state/feeds:/opt/sdk/feeds" \
  openwrt-corosync bash /build/build.sh \
  | tee output/build.log
