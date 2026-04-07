#' @keywords internal
"_PACKAGE"

#' @import blockr.core
#' @import shiny
#' @importFrom jsonlite fromJSON
#' @importFrom htmltools tags tagList HTML div htmlDependency
#' @importFrom admiral derive_var_chg
#' @importFrom rlang exprs
NULL

# Suppress R CMD check NOTE for .(data) placeholder in bquoted expressions
utils::globalVariables("data")

