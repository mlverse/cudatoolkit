# Read component names from the installed components.tsv
.read_components <- function() {
  tsv <- system.file("components.tsv", package = utils::packageName(), mustWork = TRUE)
  df <- utils::read.delim(tsv, stringsAsFactors = FALSE)
  stats::setNames(df$component, df$component)
}

# Lazily cached component map
.component_env <- new.env(parent = emptyenv())

.component_name <- function(component) {
  if (is.null(.component_env$map)) {
    .component_env$map <- .read_components()
  }
  known <- .component_env$map[[component]]
  if (is.null(known)) {
    stop(sprintf(
      "Unknown ROCm component: '%s'. Available: %s",
      component, paste(names(.component_env$map), collapse = ", ")
    ))
  }
  known
}

#' Path to a ROCm component installation
#'
#' @param component Component name (e.g., "runtime", "rocblas", "hipsparse").
#' @return A character string with the path to the installed component files.
#' @export
rocm_path <- function(component) {
  system.file(file.path("rocm", .component_name(component)),
              package = utils::packageName(), mustWork = TRUE)
}

#' Path to the shared library directory
#'
#' All ROCm component libraries are installed into a single shared directory.
#'
#' @return A character string with the path to the lib directory.
#' @export
lib_path <- function() {
  system.file("lib", package = utils::packageName(), mustWork = TRUE)
}

#' Path to the ROCm headers
#'
#' All component headers are merged into a single include root, mirroring
#' \code{/opt/rocm/include}. Header directories are namespaced by component
#' (e.g., \code{hip/}, \code{rocblas/}).
#'
#' @param component Optional component name. If supplied, it is validated
#'   against the installed components but the returned path is the shared
#'   include root.
#' @return A character string with the path to the include directory.
#' @export
include_path <- function(component = NULL) {
  if (!is.null(component)) {
    .component_name(component)
  }
  system.file("include", package = utils::packageName(), mustWork = TRUE)
}

#' Path to a ROCm component's binaries
#'
#' @param component Component name (e.g., "rocminfo").
#' @return A character string with the path to the bin directory.
#' @export
bin_path <- function(component) {
  file.path(rocm_path(component), "bin")
}

#' Path to the shared library directory
#'
#' Alias for \code{\link{lib_path}}. All ROCm component libraries are in a
#' single directory, so this simply returns that path.
#'
#' @return A character vector of length one with the library path.
#' @export
all_lib_paths <- function() {
  lib_path()
}
