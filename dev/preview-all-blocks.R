# Preview: Admiral derive blocks with SDTM data
#
# Full SDTM DM → ADSL pipeline demonstrating:
# - Single-input admiral blocks (derive_vars_dt, derive_var_trtdurd, etc.)
# - Two-input admiral join block (derive_vars_merged with EX data)
# - Mix with blockr.dplyr (mutate for prep)

library(blockr.core)
pkgload::load_all("blockr.admiral")
library(blockr.dplyr)
library(blockr.dock)
library(blockr.dag)
library(blockr.ai)

options(shiny.port = 3838, shiny.host = "0.0.0.0")

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
