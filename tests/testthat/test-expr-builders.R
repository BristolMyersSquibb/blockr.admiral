# Unit tests for admiral expression builder

eval_bquoted <- function(expr, df, name = "data") {
  resolved <- do.call(
    bquote,
    list(expr, stats::setNames(list(as.name(name)), name))
  )
  eval(
    resolved,
    envir = stats::setNames(list(df), name)
  )
}

# --- Passthrough ---

test_that("make_admiral_expr returns passthrough for NULL fn", {
  expr <- make_admiral_expr(NULL, list())
  result <- eval_bquoted(expr, mtcars)
  expect_equal(result, mtcars)
})

test_that("make_admiral_expr returns passthrough for empty string fn", {
  expr <- make_admiral_expr("", list())
  result <- eval_bquoted(expr, mtcars)
  expect_equal(result, mtcars)
})

# --- Zero-arg functions ---

test_that("make_admiral_expr handles derive_var_chg (zero args)", {
  expr <- make_admiral_expr("derive_var_chg", list())
  expect_type(expr, "language")
  deparsed <- deparse(expr)
  expect_true(grepl("derive_var_chg", deparsed))
})

test_that("make_admiral_expr handles derive_var_pchg (zero args)", {
  expr <- make_admiral_expr("derive_var_pchg", list())
  deparsed <- deparse(expr)
  expect_true(grepl("derive_var_pchg", deparsed))
})

# --- Column arguments ---

test_that("make_admiral_expr handles column args as symbols", {
  expr <- make_admiral_expr("derive_vars_dt", list(
    new_vars_prefix = "RFST",
    dtc = "RFSTDTC"
  ))
  deparsed <- paste(deparse(expr), collapse = " ")
  expect_true(grepl("new_vars_prefix = \"RFST\"", deparsed))
  expect_true(grepl("dtc = RFSTDTC", deparsed))
  # dtc should be unquoted (symbol), not a string
  expect_false(grepl("dtc = \"RFSTDTC\"", deparsed))
})

# --- Column-list arguments ---

test_that("make_admiral_expr wraps column-list in exprs()", {
  expr <- make_admiral_expr("derive_var_extreme_flag", list(
    by_vars = list("USUBJID", "PARAMCD"),
    order = list("AVISITN"),
    new_var = "ABLFL",
    mode = "last"
  ))
  deparsed <- paste(deparse(expr), collapse = " ")
  expect_true(grepl("exprs\\(USUBJID", deparsed))
  expect_true(grepl("PARAMCD", deparsed))
  expect_true(grepl("mode = \"last\"", deparsed))
})

# --- Enum arguments ---

test_that("make_admiral_expr handles enum args as strings", {
  expr <- make_admiral_expr("derive_var_extreme_flag", list(
    by_vars = list("USUBJID"),
    order = list("AVAL"),
    new_var = "FIRST_FL",
    mode = "first"
  ))
  deparsed <- paste(deparse(expr), collapse = " ")
  expect_true(grepl("mode = \"first\"", deparsed))
})

# --- Default skipping ---

test_that("make_admiral_expr skips default values", {
  # derive_vars_dt: date_imputation default is "first"
  expr <- make_admiral_expr("derive_vars_dt", list(
    new_vars_prefix = "AST",
    dtc = "AESTDTC",
    date_imputation = "first"
  ))
  deparsed <- paste(deparse(expr), collapse = " ")
  # Should NOT contain date_imputation since it matches default
  expect_false(grepl("date_imputation", deparsed))
})

test_that("make_admiral_expr includes non-default values", {
  expr <- make_admiral_expr("derive_vars_dt", list(
    new_vars_prefix = "AST",
    dtc = "AESTDTC",
    date_imputation = "last"
  ))
  deparsed <- paste(deparse(expr), collapse = " ")
  expect_true(grepl("date_imputation = \"last\"", deparsed))
})

# --- Boolean arguments ---

test_that("make_admiral_expr handles boolean args", {
  expr <- make_admiral_expr("derive_vars_duration", list(
    new_var = "TRTDUR",
    start_date = "TRTSDT",
    end_date = "TRTEDT",
    add_one = FALSE
  ))
  deparsed <- paste(deparse(expr), collapse = " ")
  expect_true(grepl("add_one = FALSE", deparsed))
})

# --- End-to-end with real data ---

test_that("derive_vars_dt works end-to-end with safetyData", {
  skip_if_not_installed("safetyData")
  expr <- make_admiral_expr("derive_vars_dt", list(
    new_vars_prefix = "RFST",
    dtc = "RFSTDTC"
  ))
  result <- eval_bquoted(expr, safetyData::sdtm_dm)
  expect_true("RFSTDT" %in% colnames(result))
  expect_s3_class(result$RFSTDT, "Date")
})

test_that("derive_var_trtdurd works end-to-end", {
  skip_if_not_installed("safetyData")
  # First parse dates, then compute duration
  dm <- safetyData::sdtm_dm
  dm <- eval_bquoted(
    make_admiral_expr("derive_vars_dt", list(
      new_vars_prefix = "RFST", dtc = "RFSTDTC"
    )),
    dm
  )
  dm <- eval_bquoted(
    make_admiral_expr("derive_vars_dt", list(
      new_vars_prefix = "RFEN", dtc = "RFENDTC"
    )),
    dm
  )
  result <- eval_bquoted(
    make_admiral_expr("derive_var_trtdurd", list(
      start_date = "RFSTDT", end_date = "RFENDT"
    )),
    dm
  )
  expect_true("TRTDURD" %in% colnames(result))
  expect_true(is.numeric(result$TRTDURD))
})
