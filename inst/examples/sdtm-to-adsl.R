# SDTM DM → ADSL derivation pipeline — a chained admiral pipeline in blockr.dock,
# each block one derivation step with visible intermediate results. Prep DM with
# blockr.dplyr, then admiral blocks for the ADaM steps, plus a merge that joins
# EX (exposure) into the main pipeline. Run with:
#
#   source(system.file("examples/sdtm-to-adsl.R", package = "blockr.admiral"))

# ---- Package loading (dual: installed vs local source) ---------------------
# `dev_local = FALSE` (the default, and what ships) attaches the INSTALLED
# packages with library(). Set it to TRUE -- or source this file from the
# dev/sdtm-to-adsl.R wrapper -- to load every blockr package from its LOCAL
# source checkout with pkgload::load_all(). One board, two loaders, no drift.
if (!exists("dev_local")) dev_local <- FALSE

blockr_pkgs <- c(
  "blockr.core",
  "blockr.admiral",   # admiral derivation blocks (derive_vars_*, merge, seq)
  "blockr.dplyr",
  "blockr.dock",
  "blockr.dag",
  "blockr.ai"
)

for (pkg in blockr_pkgs) {
  if (dev_local) pkgload::load_all(pkg, quiet = TRUE)
  else library(pkg, character.only = TRUE)
}

# SDTM source tables (dm, ex) come from pharmaversesdtm via new_dataset_block().
library(pharmaversesdtm)   # SDTM example domains (dm, ex)

serve(
  new_dock_board(
    blocks = c(
      # === Data sources ===
      dm = new_dataset_block(dataset = "dm", package = "pharmaversesdtm"),
      ex = new_dataset_block(dataset = "ex", package = "pharmaversesdtm"),

      # === Prep DM: add treatment variables ===
      prep = new_mutate_block(
        mutations = list(
          list(name = "TRT01P", expr = "ARM"),
          list(name = "TRT01A", expr = "ACTARM")
        )
      ),

      # === Prep EX: parse exposure start dates ===
      ex_dates = new_admiral_block(state = list(
        fn = "derive_vars_dtm",
        args = list(new_vars_prefix = "EXST", dtc = "EXSTDTC")
      )),

      # === Main pipeline ===

      # Step 1: Parse reference start date
      parse_rfst = new_admiral_block(state = list(
        fn = "derive_vars_dt",
        args = list(new_vars_prefix = "RFST", dtc = "RFSTDTC")
      )),

      # Step 2: Parse reference end date
      parse_rfen = new_admiral_block(state = list(
        fn = "derive_vars_dt",
        args = list(new_vars_prefix = "RFEN", dtc = "RFENDTC")
      )),

      # Step 3: Merge first treatment date from EX
      merge_trt = new_admiral_join_block(state = list(
        fn = "derive_vars_merged",
        args = list(
          by_vars = list("STUDYID", "USUBJID"),
          new_vars = "TRTSDTM = EXSTDTM",
          order = "EXSTDTM, EXSEQ",
          mode = "first"
        )
      )),

      # Step 4: Treatment duration
      trtdurd = new_admiral_block(state = list(
        fn = "derive_var_trtdurd",
        args = list(start_date = "RFSTDT", end_date = "RFENDT")
      )),

      # Step 5: Study days
      studyday = new_admiral_block(state = list(
        fn = "derive_vars_dy",
        args = list(reference_date = "RFSTDT", source_vars = "RFSTDT, RFENDT")
      )),

      # Step 6: Sequence number
      aseq = new_admiral_block(state = list(
        fn = "derive_var_obs_number",
        args = list()
      ))
    ),
    links = list(
      # DM prep pipeline
      list(from = "dm", to = "prep", input = "data"),
      list(from = "prep", to = "parse_rfst", input = "data"),
      list(from = "parse_rfst", to = "parse_rfen", input = "data"),

      # EX prep (separate branch)
      list(from = "ex", to = "ex_dates", input = "data"),

      # Merge: DM pipeline + EX dates → merge_trt (two inputs)
      list(from = "parse_rfen", to = "merge_trt", input = "data"),
      list(from = "ex_dates", to = "merge_trt", input = "dataset_add"),

      # Continue pipeline after merge
      list(from = "merge_trt", to = "trtdurd", input = "data"),
      list(from = "trtdurd", to = "studyday", input = "data"),
      list(from = "studyday", to = "aseq", input = "data")
    ),
    extensions = new_dag_extension()
  ),
  plugins = custom_plugins(c(ai_ctrl_block()))
)
