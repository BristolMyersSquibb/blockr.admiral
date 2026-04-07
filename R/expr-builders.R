#' Expression builders for the admiral block
#'
#' @name admiral-expr-builders
#' @keywords internal
NULL

#' Build an admiral derive_* expression from function name and arguments
#'
#' @param fn_name Character, the function name (e.g., "derive_vars_dt")
#' @param args Named list of argument values from JS
#' @param has_add Logical, whether dataset_add input is connected
#' @return A bquoted language object
#' @noRd
make_admiral_expr <- function(fn_name, args, has_add = FALSE) {
  if (is.null(fn_name) || !nzchar(fn_name)) {
    return(blockr.core::bbquote(.(data)))
  }

  catalog <- get_admiral_catalog()
  fn_def <- catalog[[fn_name]]
  if (is.null(fn_def)) {
    return(blockr.core::bbquote(.(data)))
  }

  # We build the call as a text string and parse it.
  # This is simpler and more reliable than constructing language objects
  # for complex arguments like exprs().
  parts <- c(paste0("admiral::", fn_name, "(data"))

  if (has_add && isTRUE(fn_def$needs_dataset_add)) {
    parts <- c(parts, "dataset_add = dataset_add")
  }

  for (nm in names(args)) {
    value <- args[[nm]]
    if (is.null(value)) next

    arg_def <- fn_def$args[[nm]]
    if (is.null(arg_def)) next

    # Skip if value matches default
    if (!is.null(arg_def$default) && identical(value, arg_def$default)) next

    arg_str <- switch(arg_def$type,
      column = paste0(nm, " = ", as.character(value)),
      `column-list` = {
        cols <- as.character(unlist(value))
        if (length(cols) == 0L) next
        paste0(nm, " = rlang::exprs(", paste(cols, collapse = ", "), ")")
      },
      enum = paste0(nm, " = \"", as.character(value), "\""),
      boolean = paste0(nm, " = ", if (isTRUE(as.logical(value))) "TRUE" else "FALSE"),
      numeric = {
        n <- suppressWarnings(as.numeric(value))
        if (is.na(n)) next
        paste0(nm, " = ", n)
      },
      text = paste0(nm, " = \"", as.character(value), "\""),
      expr = {
        txt <- as.character(value)
        if (!nzchar(txt)) next
        paste0(nm, " = rlang::exprs(", txt, ")")
      },
      next
    )
    parts <- c(parts, arg_str)
  }

  call_text <- paste(parts, collapse = ", ")
  call_text <- paste0(call_text, ")")

  # Parse and wrap with .(data) placeholder
  expr <- tryCatch(
    parse(text = call_text)[[1]],
    error = function(e) {
      return(quote(.(data)))
    }
  )

  # Replace bare 'data' with .(data) placeholder for bbquote
  expr <- substitute_data_placeholder(expr)

  expr
}

#' Replace bare `data` and `dataset_add` symbols with bbquote placeholders
#' @noRd
substitute_data_placeholder <- function(expr) {
  if (is.name(expr)) {
    if (identical(expr, quote(data))) return(quote(.(data)))
    if (identical(expr, quote(dataset_add))) return(quote(.(dataset_add)))
    return(expr)
  }
  if (is.call(expr)) {
    for (i in seq_along(expr)) {
      # Only substitute first-level direct data args, not nested
      if (i == 2 && identical(expr[[i]], quote(data))) {
        expr[[i]] <- quote(.(data))
      } else if (is.name(expr[[i]]) && identical(expr[[i]], quote(dataset_add))) {
        expr[[i]] <- quote(.(dataset_add))
      }
    }
  }
  expr
}
