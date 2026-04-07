# Demo: SDTM DM → ADSL derivation pipeline
#
# Comprehensive demo showing a chained admiral pipeline in blockr.dock.
# Each block is one derivation step with visible intermediate results.
#
# Uses pharmaversesdtm for SDTM data, blockr.dplyr for prep, then
# admiral blocks for the ADaM derivation steps. Includes a merge block
# that joins EX (exposure) data into the main pipeline.
#
# Prerequisites: pharmaversesdtm, blockr.dock, blockr.dplyr, blockr.dag, blockr.ai

library(blockr.core)
pkgload::load_all("blockr.admiral")
library(blockr.dplyr)
library(blockr.dock)
library(blockr.dag)
library(blockr.ai)

serve(
  new_dock_board(
    blocks = c(
      # === Data sources ===
      dm = new_dataset_block(dataset = "dm", package = "pharmaversesdtm"),
      ex = new_dataset_block(dataset = "ex", package = "pharmaversesdtm"),

      # === Prep DM: add treatment variables ===
      prep = new_mutate_block(state = list(
        mutations = list(
          list(name = "TRT01P", expr = "ARM"),
          list(name = "TRT01A", expr = "ACTARM")
        )
      )),

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
