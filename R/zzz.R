.onLoad <- function(libname, pkgname) {
  tryCatch(
    register_admiral_blocks(),
    error = function(e) {
      warning("blockr.admiral: block registration failed: ", conditionMessage(e))
    }
  )
  invisible(NULL)
}
