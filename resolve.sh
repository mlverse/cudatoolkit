#!/bin/sh
# Resolves component versions from PyPI and generates inst/components.tsv
# for each cuda*/ package directory. Run this when updating toolkit versions.

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

for pkg_dir in "$SCRIPT_DIR"/cuda*/; do
  [ -d "$pkg_dir" ] || continue
  pkg=$(basename "$pkg_dir")

  # Read version info
  . "$pkg_dir/inst/cuda-version.env"
  echo "=== Resolving ${pkg} (toolkit ${TOOLKIT_VERSION}) ==="

  # Fetch cuda-toolkit metadata from PyPI
  curl -sL "https://pypi.org/pypi/cuda-toolkit/${TOOLKIT_VERSION}/json" -o /tmp/toolkit.json

  printf 'component\tpypi_package\tversion\twheel_subdir\textract\tlinux_only\n' > "$pkg_dir/inst/components.tsv"

  if [ "$CUDA_MAJOR" = "12" ]; then
    PYPI_SUFFIX="_cu12"
    TOOLKIT_COMPONENTS="
    runtime   nvidia_cuda_runtime${PYPI_SUFFIX}  cuda_runtime  lib,include no
    cublas    nvidia_cublas${PYPI_SUFFIX}         cublas         lib,include no
    cupti     nvidia_cuda_cupti${PYPI_SUFFIX}     cuda_cupti     lib,include no
    nvrtc     nvidia_cuda_nvrtc${PYPI_SUFFIX}     cuda_nvrtc     lib,include no
    cufft     nvidia_cufft${PYPI_SUFFIX}          cufft          lib,include no
    cusolver  nvidia_cusolver${PYPI_SUFFIX}       cusolver       lib,include no
    cusparse  nvidia_cusparse${PYPI_SUFFIX}       cusparse       lib,include no
    nvjitlink nvidia_nvjitlink${PYPI_SUFFIX}      nvjitlink      lib,include no
    nvcc      nvidia_cuda_nvcc${PYPI_SUFFIX}      cuda_nvcc      bin,include,nvvm no
    "
    CUDNN_PKG="nvidia_cudnn${PYPI_SUFFIX}"
    NCCL_PKG="nvidia_nccl${PYPI_SUFFIX}"
    NVSHMEM_PKG="nvidia_nvshmem${PYPI_SUFFIX}"
    CUDNN_SUBDIR="cudnn"
    NCCL_SUBDIR="nccl"
    NVSHMEM_SUBDIR="nvshmem"
  else
    PYPI_SUFFIX=""
    WHEEL_SUBDIR="cu${CUDA_MAJOR}"
    TOOLKIT_COMPONENTS="
    runtime   nvidia_cuda_runtime      ${WHEEL_SUBDIR}  lib,include no
    cublas    nvidia_cublas             ${WHEEL_SUBDIR}  lib,include no
    cupti     nvidia_cuda_cupti         ${WHEEL_SUBDIR}  lib,include no
    nvrtc     nvidia_cuda_nvrtc         ${WHEEL_SUBDIR}  lib,include no
    cufft     nvidia_cufft              ${WHEEL_SUBDIR}  lib,include no
    cusolver  nvidia_cusolver           ${WHEEL_SUBDIR}  lib,include no
    cusparse  nvidia_cusparse           ${WHEEL_SUBDIR}  lib,include no
    nvjitlink nvidia_nvjitlink          ${WHEEL_SUBDIR}  lib,include no
    nvcc      nvidia_cuda_nvcc          ${WHEEL_SUBDIR}  bin,include,nvvm no
    "
    CUDNN_PKG="nvidia_cudnn_cu${CUDA_MAJOR}"
    NCCL_PKG="nvidia_nccl_cu${CUDA_MAJOR}"
    NVSHMEM_PKG="nvidia_nvshmem_cu${CUDA_MAJOR}"
    CUDNN_SUBDIR="cudnn"
    NCCL_SUBDIR="nccl"
    NVSHMEM_SUBDIR="nvshmem"
  fi

  # Extract pinned versions from cuda-toolkit metadata
  grep -oE 'nvidia-[a-z-]+(-cu[0-9]+)?==[0-9.]+\.\*' /tmp/toolkit.json \
    | sed 's/\.\*$//' \
    | sed 's/-/_/g' \
    | sed 's/==/=/' \
    | sort -u > /tmp/versions.txt

  echo "$TOOLKIT_COMPONENTS" | while read -r comp pkg subdir extract linux_only; do
    [ -z "$comp" ] && continue
    ver=$(grep "^${pkg}=" /tmp/versions.txt | head -1 | cut -d= -f2)
    if [ -n "$ver" ]; then
      printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$comp" "$pkg" "$ver" "$subdir" "$extract" "$linux_only" >> "$pkg_dir/inst/components.tsv"
    fi
  done

  # Append extra components
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "cudnn" "$CUDNN_PKG" "$CUDNN_VERSION" "$CUDNN_SUBDIR" "lib,include" "no" >> "$pkg_dir/inst/components.tsv"
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "nccl" "$NCCL_PKG" "$NCCL_VERSION" "$NCCL_SUBDIR" "lib,include" "yes" >> "$pkg_dir/inst/components.tsv"
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "nvshmem" "$NVSHMEM_PKG" "$NVSHMEM_VERSION" "$NVSHMEM_SUBDIR" "lib,include" "yes" >> "$pkg_dir/inst/components.tsv"

  echo "  Components:"
  cat "$pkg_dir/inst/components.tsv"
  echo ""
done

echo "=== All versions resolved ==="
