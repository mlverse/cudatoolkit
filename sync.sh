#!/bin/sh
# Copies shared files into each cuda*/ package directory and generates
# DESCRIPTION from the template using version info in each package's
# inst/cuda-version.env.

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

for pkg_dir in "$SCRIPT_DIR"/cuda*/; do
  [ -d "$pkg_dir" ] || continue
  pkg=$(basename "$pkg_dir")
  echo "=== Syncing ${pkg} ==="

  # Copy shared files
  cp "$SCRIPT_DIR/shared/configure" "$pkg_dir/configure"
  chmod +x "$pkg_dir/configure"
  cp "$SCRIPT_DIR/shared/NAMESPACE" "$pkg_dir/NAMESPACE"
  cp "$SCRIPT_DIR/shared/LICENSE" "$pkg_dir/LICENSE"
  mkdir -p "$pkg_dir/R"
  cp "$SCRIPT_DIR/shared/R/paths.R" "$pkg_dir/R/paths.R"

  # Read version info
  . "$pkg_dir/inst/cuda-version.env"

  # Generate DESCRIPTION from template
  sed -e "s/{{CUDA_MINOR}}/${CUDA_MINOR}/g" \
      -e "s/{{PKG_VERSION}}/${PKG_VERSION}/g" \
      "$SCRIPT_DIR/shared/DESCRIPTION.template" > "$pkg_dir/DESCRIPTION"

  echo "  Done (cuda${CUDA_MINOR} v${PKG_VERSION})"
done

echo ""
echo "=== All packages synced ==="
