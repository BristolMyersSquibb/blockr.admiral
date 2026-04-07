#' HTML dependencies for the admiral block
#'
#' @importFrom htmltools htmlDependency tagList
#' @noRd
NULL

#' @noRd
blockr_core_js_dep <- function() {
  htmltools::htmlDependency(
    name = "blockr-core-js",
    version = utils::packageVersion("blockr.admiral"),
    src = system.file("js", package = "blockr.admiral"),
    script = "blockr-core.js"
  )
}

#' @noRd
blockr_blocks_css_dep <- function() {
  htmltools::htmlDependency(
    name = "blockr-blocks-css",
    version = utils::packageVersion("blockr.admiral"),
    src = system.file("css", package = "blockr.admiral"),
    stylesheet = "blockr-blocks.css"
  )
}

#' @noRd
blockr_select_dep <- function() {
  htmltools::tagList(
    blockr_core_js_dep(),
    htmltools::htmlDependency(
      name = "blockr-select-js",
      version = utils::packageVersion("blockr.admiral"),
      src = system.file("js", package = "blockr.admiral"),
      script = "blockr-select.js"
    ),
    htmltools::htmlDependency(
      name = "blockr-select-css",
      version = utils::packageVersion("blockr.admiral"),
      src = system.file("css", package = "blockr.admiral"),
      stylesheet = "blockr-select.css"
    )
  )
}

#' @noRd
blockr_select_rich_dep <- function() {
  htmltools::tagList(
    blockr_core_js_dep(),
    htmltools::htmlDependency(
      name = "blockr-select-rich-js",
      version = utils::packageVersion("blockr.admiral"),
      src = system.file("js", package = "blockr.admiral"),
      script = "blockr-select-rich.js"
    ),
    htmltools::htmlDependency(
      name = "blockr-select-rich-css",
      version = utils::packageVersion("blockr.admiral"),
      src = system.file("css", package = "blockr.admiral"),
      stylesheet = "blockr-select-rich.css"
    )
  )
}

#' @noRd
admiral_block_dep <- function() {
  htmltools::tagList(
    htmltools::htmlDependency(
      name = "admiral-block-js",
      version = utils::packageVersion("blockr.admiral"),
      src = system.file("js", package = "blockr.admiral"),
      script = "admiral-block.js"
    ),
    htmltools::htmlDependency(
      name = "admiral-block-css",
      version = utils::packageVersion("blockr.admiral"),
      src = system.file("css", package = "blockr.admiral"),
      stylesheet = "admiral-block.css"
    )
  )
}
