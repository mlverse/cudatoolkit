# Read component -> wheel_subdir mapping from installed components.tsv
.read_components <- function() {
  tsv <- system.file("components.tsv", package = packageName(), mustWork = TRUE)
  df <- read.delim(tsv, stringsAsFactors = FALSE)
  setNames(df$wheel_subdir, df$component)
}

# Lazily cached component map
.component_subdir_env <- new.env(parent = emptyenv())

.component_subdir <- function(component) {
  if (is.null(.component_subdir_env$map)) {
    .component_subdir_env$map <- .read_components()
  }
  subdir <- .component_subdir_env$map[[component]]
  if (is.null(subdir)) {
    stop(sprintf("Unknown component: '%s'. Available: %s",
                 component, paste(names(.component_subdir_env$map), collapse = ", ")))
  }
  subdir
}

#' Path to a CUDA component installation
#'
#' @param component Component name (e.g., "runtime", "cublas", "cudnn").
#' @return A character string with the path to the installed component files.
#' @export
cuda_path <- function(component) {
  system.file(file.path("nvidia", .component_subdir(component)),
              package = packageName(), mustWork = TRUE)
}

#' Path to the shared library directory
#'
#' All CUDA component libraries are installed into a single shared directory.
#'
#' @return A character string with the path to the lib directory.
#' @export
lib_path <- function() {
  system.file("lib", package = packageName(), mustWork = TRUE)
}

#' Path to a CUDA component's headers
#'
#' @param component Component name (e.g., "runtime", "cublas", "cudnn").
#' @return A character string with the path to the include directory.
#' @export
include_path <- function(component) {
  file.path(cuda_path(component), "include")
}

#' Path to a CUDA component's binaries
#'
#' @param component Component name (e.g., "nvcc").
#' @return A character string with the path to the bin directory.
#' @export
bin_path <- function(component) {
  file.path(cuda_path(component), "bin")
}

#' Path to the shared library directory
#'
#' Alias for \code{\link{lib_path}}. All CUDA component libraries are in a
#' single directory, so this simply returns that path.
#'
#' @return A character vector of length one with the library path.
#' @export
all_lib_paths <- function() {
  lib_path()
}
