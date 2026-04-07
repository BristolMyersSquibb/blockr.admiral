#' Admiral function catalog
#'
#' Loads and caches the admiral function catalog from
#' inst/extdata/admiral-functions.json.
#'
#' @noRd

.catalog_env <- new.env(parent = emptyenv())

#' Get the admiral function catalog
#'
#' @return Named list of function definitions with args, types, defaults.
#' @noRd
get_admiral_catalog <- function() {
  if (is.null(.catalog_env$catalog)) {
    path <- system.file("extdata", "admiral-functions.json",
                        package = "blockr.admiral")
    .catalog_env$catalog <- jsonlite::fromJSON(path, simplifyVector = FALSE)
  }
  .catalog_env$catalog
}
