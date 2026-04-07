#' Admiral Derivation Block (single input)
#'
#' Universal block for admiral derive_* functions that operate on a single
#' dataset. Select a function from the catalog, configure its arguments,
#' and the block constructs and executes the call.
#'
#' For merge/join functions that need a second dataset, use
#' [new_admiral_join_block()] instead.
#'
#' @param state List with `fn` (function name) and `args` (named list of
#'   argument values).
#' @param ... Additional arguments forwarded to [blockr.core::new_transform_block()]
#'
#' @export
new_admiral_block <- function(
  state = list(fn = NULL, args = list()),
  ...
) {
  blockr.core::new_transform_block(
    server = function(id, data) {
      moduleServer(id, function(input, output, session) {
        ns <- session$ns
        r_state <- reactiveVal(state)

        self_write <- new.env(parent = emptyenv())
        self_write$active <- FALSE

        # Send catalog (single-input functions only)
        observe({
          catalog <- get_admiral_catalog()
          single <- Filter(function(x) !isTRUE(x$needs_dataset_add), catalog)
          session$sendCustomMessage("admiral-catalog",
            list(id = ns("admiral_input"), catalog = single))
        }, priority = 100)

        # Send column names when data changes
        observeEvent(data(), {
          session$sendCustomMessage("admiral-columns",
            list(id = ns("admiral_input"), columns = colnames(data())))
        })

        # JS -> R
        observeEvent(input$admiral_input, {
          self_write$active <- TRUE
          r_state(input$admiral_input)
          self_write$active <- FALSE
        })

        # R -> JS
        observeEvent(r_state(), {
          if (!self_write$active) {
            session$sendCustomMessage("admiral-block-update",
              list(id = ns("admiral_input"), state = r_state()))
          }
        })

        list(
          expr = reactive({
            s <- r_state()
            make_admiral_expr(s$fn, s$args %||% list(), has_add = FALSE)
          }),
          state = list(state = r_state)
        )
      })
    },
    ui = function(id) {
      tagList(
        blockr_core_js_dep(),
        blockr_blocks_css_dep(),
        blockr_select_dep(),
        blockr_select_rich_dep(),
        admiral_block_dep(),
        div(class = "block-container",
          div(id = NS(id, "admiral_input"),
              class = "admiral-block-container"))
      )
    },
    class = "admiral_block",
    expr_type = "bquoted",
    external_ctrl = TRUE,
    allow_empty_state = "state",
    ...
  )
}

#' Admiral Merge/Join Block (two inputs)
#'
#' Block for admiral derive_* functions that merge data from a second dataset
#' (e.g., [admiral::derive_vars_merged()]). Takes two data inputs: the primary
#' dataset and the additional dataset to merge from.
#'
#' For single-input functions, use [new_admiral_block()] instead.
#'
#' @param state List with `fn` (function name) and `args` (named list of
#'   argument values).
#' @param ... Additional arguments forwarded to [blockr.core::new_transform_block()]
#'
#' @export
new_admiral_join_block <- function(
  state = list(fn = NULL, args = list()),
  ...
) {
  blockr.core::new_transform_block(
    server = function(id, data, dataset_add) {
      moduleServer(id, function(input, output, session) {
        ns <- session$ns
        r_state <- reactiveVal(state)

        self_write <- new.env(parent = emptyenv())
        self_write$active <- FALSE

        # Send catalog (join functions only)
        observe({
          catalog <- get_admiral_catalog()
          joins <- Filter(function(x) isTRUE(x$needs_dataset_add), catalog)
          session$sendCustomMessage("admiral-catalog",
            list(id = ns("admiral_input"), catalog = joins))
        }, priority = 100)

        # Send column names from both datasets
        observeEvent(data(), {
          session$sendCustomMessage("admiral-columns",
            list(id = ns("admiral_input"), columns = colnames(data())))
        })

        observeEvent(dataset_add(), {
          session$sendCustomMessage("admiral-columns-add",
            list(id = ns("admiral_input"), columns = colnames(dataset_add())))
        })

        # JS -> R
        observeEvent(input$admiral_input, {
          self_write$active <- TRUE
          r_state(input$admiral_input)
          self_write$active <- FALSE
        })

        # R -> JS
        observeEvent(r_state(), {
          if (!self_write$active) {
            session$sendCustomMessage("admiral-block-update",
              list(id = ns("admiral_input"), state = r_state()))
          }
        })

        list(
          expr = reactive({
            s <- r_state()
            make_admiral_expr(s$fn, s$args %||% list(), has_add = TRUE)
          }),
          state = list(state = r_state)
        )
      })
    },
    ui = function(id) {
      tagList(
        blockr_core_js_dep(),
        blockr_blocks_css_dep(),
        blockr_select_dep(),
        blockr_select_rich_dep(),
        admiral_block_dep(),
        div(class = "block-container",
          div(id = NS(id, "admiral_input"),
              class = "admiral-block-container"))
      )
    },
    class = "admiral_join_block",
    expr_type = "bquoted",
    external_ctrl = TRUE,
    allow_empty_state = "state",
    ...
  )
}
