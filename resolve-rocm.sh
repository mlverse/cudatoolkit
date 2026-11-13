#!/bin/sh

# Regenerates rocm*/inst/components.tsv from the repo.radeon.com apt index.
# Run from the repository root (or anywhere; paths are resolved relative to
# this script). Requires curl/wget and gzip.
#
# The pinned versions come from the apt index of the configured suite, so
# update ROCM_APT_SUITE when targeting a different Ubuntu release.

set -e

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# component        deb package          extract
COMPONENTS='
core              rocm-core            lib,include,share
runtime           hip-runtime-amd      lib,include,share
hsa-runtime       hsa-rocr             lib,include,share
hsa-dev           hsa-rocr-dev         lib,include
comgr             comgr                lib,include
hip-dev           hip-dev              lib,include,bin,share
device-libs       rocm-device-libs     lib,include,amdgcn
rocblas           rocblas              lib
rocblas-dev       rocblas-dev          lib,include
hipblas           hipblas              lib
hipblas-dev       hipblas-dev          lib,include
hipblas-common    hipblas-common-dev   lib,include
hipblaslt         hipblaslt            lib
hipblaslt-dev     hipblaslt-dev        lib,include
hipfft            hipfft               lib
hipfft-dev        hipfft-dev           lib,include
hipsparse         hipsparse            lib
hipsparse-dev     hipsparse-dev        lib,include
hipsolver         hipsolver            lib
hipsolver-dev     hipsolver-dev        lib,include
rocrand           rocrand              lib
rocrand-dev       rocrand-dev          lib,include
hiprand           hiprand              lib
hiprand-dev       hiprand-dev          lib,include
rccl              rccl                 lib
rccl-dev          rccl-dev             lib,include
miopen            miopen-hip           lib
miopen-dev        miopen-hip-dev       lib,include
rocthrust-dev     rocthrust-dev        include
hipcub-dev        hipcub-dev           include
rocprim-dev       rocprim-dev          include
rocminfo          rocminfo             bin
'

download_file() {
  url="$1"; dest="$2"
  if command -v curl > /dev/null 2>&1; then
    curl -fsSL -o "$dest" "$url"
  elif command -v wget > /dev/null 2>&1; then
    wget -q -O "$dest" "$url"
  else
    echo "ERROR: Neither curl nor wget found." >&2
    exit 1
  fi
}

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

for pkg_dir in "$SCRIPT_DIR"/rocm*/; do
  [ -d "$pkg_dir/inst" ] || continue
  version_env="$pkg_dir/inst/rocm-version.env"
  [ -f "$version_env" ] || continue

  unset ROCM_MINOR ROCM_MAJOR ROCM_PATCH ROCM_PREFIX ROCM_APT_BASE ROCM_APT_SUITE PKG_VERSION
  . "$version_env"

  index_gz="${TMPDIR}/Packages-${ROCM_MINOR}.gz"
  index_txt="${TMPDIR}/Packages-${ROCM_MINOR}"
  url="${ROCM_APT_BASE}/dists/${ROCM_APT_SUITE}/main/binary-amd64/Packages.gz"

  echo "==> ${pkg_dir} (ROCm ${ROCM_MINOR}, suite ${ROCM_APT_SUITE})"
  echo "    ${url}"
  download_file "$url" "$index_gz"
  gzip -dc "$index_gz" > "$index_txt"

  out="$pkg_dir/inst/components.tsv"
  printf 'component\tdeb_package\tversion\tfilename\textract\tlinux_only\n' > "$out"

  echo "$COMPONENTS" | while read -r component deb extract; do
    [ -z "$component" ] && continue

    row=$(awk -v pkg="$deb" '
      BEGIN { RS = ""; FS = "\n" }
      {
        p = ""; v = ""; f = ""
        for (i = 1; i <= NF; i++) {
          if ($i ~ /^Package: /)  p = substr($i, 10)
          if ($i ~ /^Version: /)  v = substr($i, 10)
          if ($i ~ /^Filename: /) f = substr($i, 11)
        }
        if (p == pkg) { print v "\t" f; exit }
      }
    ' "$index_txt")

    if [ -z "$row" ]; then
      echo "    ERROR: package '${deb}' not found in the index." >&2
      exit 1
    fi

    ver=$(printf '%s' "$row" | cut -f1)
    filename=$(printf '%s' "$row" | cut -f2)
    printf '%s\t%s\t%s\t%s\t%s\tyes\n' \
      "$component" "$deb" "$ver" "$filename" "$extract" >> "$out"
    echo "    ${component}: ${deb} ${ver}"
  done
done
