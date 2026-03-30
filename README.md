# cudatoolkit2

R packages that provide CUDA toolkit binaries by downloading pre-built libraries from PyPI at install time. Source packages are lightweight — all CUDA components are fetched during installation.

## Installation

```r
# Install the remotes package if needed
install.packages("remotes")

# Install a specific CUDA version
remotes::install_github("mlverse/cudatoolkit/cuda12.6")
remotes::install_github("mlverse/cudatoolkit/cuda12.8")
remotes::install_github("mlverse/cudatoolkit/cuda13.2")
```

### Installing specific components

By default, all components are installed. Set the `CUDA_COMPONENTS` environment variable to install only what you need:

```r
Sys.setenv(CUDA_COMPONENTS = "runtime,cublas,cudnn")
remotes::install_github("mlverse/cudatoolkit/cuda12.8")
```

You can also override a component's pinned version:

```r
Sys.setenv(CUDA_COMPONENTS = "runtime,cublas,cudnn@9.10.0.56")
remotes::install_github("mlverse/cudatoolkit/cuda12.8")
```

### Overriding platform detection

Platform is auto-detected (Linux x86_64, Linux aarch64, Windows). To override:

```r
Sys.setenv(CUDA_PLATFORM = "linux-x64")  # or "linux-arm64", "windows-x64"
remotes::install_github("mlverse/cudatoolkit/cuda12.8")
```

## Usage

```r
library(cuda12.8)

# Path to shared libraries (*.so / *.dll)
lib_path()

# Path to component headers
include_path("cudnn")

# Path to component binaries (e.g., nvcc, ptxas)
bin_path("nvcc")

# Path to a component's installation root
cuda_path("runtime")
```

## Available components

runtime, cublas, cudnn, cupti, nvrtc, cufft, cusolver, cusparse, nvjitlink, nccl, nvshmem, nvcc

Note: nccl and nvshmem are Linux-only and are skipped on Windows.

## Supported platforms

- Linux x86_64
- Linux aarch64
- Windows x86_64

macOS is not supported (no CUDA).

## Development

The repo uses a `shared/` directory for files common to all CUDA versions. Version-specific configuration lives in each `cuda*/inst/` directory.

### Updating component versions

1. Edit `cuda*/inst/cuda-version.env` with new toolkit/package versions.
2. Run `./resolve.sh` to regenerate `inst/components.tsv` from PyPI.
3. Run `./sync.sh` to copy shared files and regenerate DESCRIPTION files.
4. Commit and push.

### Adding a new CUDA version

1. Create a new directory: `mkdir -p cuda{X.Y}/inst`
2. Add `cuda{X.Y}/inst/cuda-version.env` with the version info:
   ```
   CUDA_MINOR="X.Y"
   CUDA_MAJOR="X"
   TOOLKIT_VERSION="X.Y.Z"
   PKG_VERSION="1.0.0"
   CUDNN_VERSION="..."
   NCCL_VERSION="..."
   NVSHMEM_VERSION="..."
   ```
3. Run `./resolve.sh` and `./sync.sh`.
4. Commit and push.

### Editing shared files

Edit files in `shared/` (configure, NAMESPACE, R/paths.R, LICENSE, DESCRIPTION.template), then run `./sync.sh` to propagate changes to all packages.
