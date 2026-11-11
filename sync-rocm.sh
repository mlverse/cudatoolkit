#!/bin/sh

# Copies shared-rocm/ into every rocm*/ package directory and generates its
# DESCRIPTION from DESCRIPTION.template. Run after editing any shared file.

set -e

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

for pkg_dir in "$SCRIPT_DIR"/rocm*/; do
  [ -d "$pkg_dir/inst" ] || continue
  version_env="$pkg_dir/inst/rocm-version.env"
  [ -f "$version_env" ] || continue

  unset ROCM_MINOR ROCM_MAJOR ROCM_PATCH ROCM_PREFIX ROCM_APT_BASE ROCM_APT_SUITE PKG_VERSION
  . "$version_env"

  echo "==> syncing ${pkg_dir}"

  mkdir -p "$pkg_dir/R"
  cp "$SCRIPT_DIR/shared-rocm/configure" "$pkg_dir/configure"
  cp "$SCRIPT_DIR/shared-rocm/NAMESPACE" "$pkg_dir/NAMESPACE"
  cp "$SCRIPT_DIR/shared-rocm/LICENSE" "$pkg_dir/LICENSE"
  cp "$SCRIPT_DIR/shared-rocm/R/paths.R" "$pkg_dir/R/paths.R"
  chmod +x "$pkg_dir/configure"

  sed -e "s/{{ROCM_MINOR}}/${ROCM_MINOR}/g" \
      -e "s/{{PKG_VERSION}}/${PKG_VERSION}/g" \
      "$SCRIPT_DIR/shared-rocm/DESCRIPTION.template" > "$pkg_dir/DESCRIPTION"
done
