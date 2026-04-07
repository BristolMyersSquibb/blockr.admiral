#' Register admiral blocks
#' @noRd
register_admiral_blocks <- function() {
  blockr.core::register_blocks(
    c("new_admiral_block", "new_admiral_join_block"),
    name = c("Admiral Derivation", "Admiral Merge"),
    description = c(
      "Apply an admiral derive_* function to transform clinical data",
      "Merge variables from a second dataset using admiral"
    ),
    category = c("transform", "transform"),
    package = utils::packageName(),
    overwrite = TRUE
  )
}
