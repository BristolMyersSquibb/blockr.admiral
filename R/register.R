#' Register admiral blocks with blockr
#'
#' @export
#' @importFrom blockr.core register_blocks
register_admiral_blocks <- function() {
  register_blocks(
    c("new_admiral_block", "new_admiral_join_block"),
    name = c(
      "Admiral Derivation",
      "Admiral Merge"
    ),
    description = c(
      paste0(
        "Apply an admiral derive_* function to ",
        "transform clinical data. Parse dates, ",
        "compute durations, flag records, derive ",
        "baseline values. (admiral: derive_var_*, ",
        "derive_vars_*)"
      ),
      paste0(
        "Merge variables from a second dataset using ",
        "admiral. Join SDTM domains or lookup tables ",
        "into the main pipeline. (admiral: ",
        "derive_vars_merged)"
      )
    ),
    category = c("transform", "transform"),
    icon = c("capsule", "intersect"),
    arguments = list(
      # admiral_block (single input):
      structure(
        c(
          state = paste0(
            "Object with: fn (admiral function ",
            "name string, e.g. 'derive_vars_dt'), ",
            "args (named object of argument values)"
          )
        ),
        examples = list(
          state = list(
            fn = "derive_vars_dt",
            args = list(
              new_vars_prefix = "RFST",
              dtc = "RFSTDTC"
            )
          )
        ),
        prompt = paste(
          "Set fn to an admiral derive_* function.",
          "Set args to a named object where keys",
          "are argument names and values match the",
          "argument type.",
          "\n\nAvailable function groups:",
          "- Simple: derive_var_chg,",
          "derive_var_pchg, derive_var_trtdurd,",
          "derive_var_age_years,",
          "derive_var_analysis_ratio",
          "- Dates: derive_vars_dt,",
          "derive_vars_dtm, derive_vars_dtm_to_dt,",
          "derive_vars_dtm_to_tm, derive_vars_dy",
          "- Duration: derive_vars_duration",
          "- Flags: derive_var_extreme_flag,",
          "derive_var_anrind, derive_var_obs_number",
          "- Baseline: derive_var_base",
          "\n\nArgument types:",
          "- Column args (dtc, start_date, etc.):",
          "plain column name string, e.g. 'RFSTDTC'",
          "- Column-list args (by_vars, order):",
          "array of column name strings,",
          "e.g. ['STUDYID', 'USUBJID']",
          "- Enum args (mode, check_type, etc.):",
          "one of the allowed string values",
          "- Boolean args (preserve, add_one):",
          "true or false",
          "- Numeric args: number value",
          "- Text args (new_vars_prefix): string",
          "- Expression args (source_vars,",
          "filter): R expression string that will",
          "be wrapped in rlang::exprs(), e.g.",
          "'RFSTDT, RFENDT'",
          "\n\nOmit args to use admiral defaults.",
          "Zero-arg functions (derive_var_chg,",
          "derive_var_pchg) need only fn, no args."
        )
      ),
      # admiral_join_block (two inputs):
      structure(
        c(
          state = paste0(
            "Object with: fn (admiral merge ",
            "function name string), args (named ",
            "object of argument values)"
          )
        ),
        examples = list(
          state = list(
            fn = "derive_vars_merged",
            args = list(
              by_vars = list("STUDYID", "USUBJID"),
              new_vars = "TRTSDTM = EXSTDTM",
              order = "EXSTDTM, EXSEQ",
              mode = "first"
            )
          )
        ),
        prompt = paste(
          "Set fn to an admiral merge function",
          "(currently: derive_vars_merged).",
          "This block has two data inputs:",
          "the primary dataset and dataset_add",
          "(the table to merge from).",
          "\n\nKey args for derive_vars_merged:",
          "- by_vars: array of join key column",
          "names, e.g. ['STUDYID', 'USUBJID']",
          "- new_vars: R expression string for",
          "columns to add, e.g. 'TRTSDT = EXSTDT'",
          "- order: R expression string for sort",
          "order when multiple matches, e.g.",
          "'EXSTDTM, EXSEQ'",
          "- mode: 'first' or 'last' to pick",
          "which matching record to keep",
          "- filter_add: R expression to filter",
          "the additional dataset before merging",
          "\n\nOmit args to use admiral defaults."
        )
      )
    ),
    package = utils::packageName(),
    overwrite = TRUE
  )
}
