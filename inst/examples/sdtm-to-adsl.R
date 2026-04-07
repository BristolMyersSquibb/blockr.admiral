# Demo: SDTM DM → ADSL derivation pipeline
#
# Comprehensive demo showing a chained admiral pipeline in blockr.dock.
# Each block is one derivation step with visible intermediate results.
#
# Uses blockr.dm to load SDTM data, blockr.dplyr for prep, then
# admiral blocks for the ADaM derivation steps.
#
# Prerequisites: safetyData, blockr.dock, blockr.dplyr, blockr.dm
#
# Run with: Rscript inst/examples/sdtm-to-adsl.R

library(blockr.core)
library(blockr.admiral)
library(blockr.dplyr)
library(blockr.dm)
library(blockr.dock)

options(shiny.port = 3838, shiny.host = "0.0.0.0")

serve(
  new_dock_board(
    blocks = c(
      # === Data loading (blockr.dm) ===
      sdtm = new_dm_example_block(dataset = "safetydata_adam"),
      dm_table = new_dm_pull_block(table = "dm"),

      # === Prep: add treatment variables (blockr.dplyr) ===
      prep = new_mutate_block(state = list(
        mutations = list(
          list(name = "TRT01P", expr = "ARM"),
          list(name = "TRT01A", expr = "ACTARM")
        )
      )),

      # === Admiral derivation pipeline ===

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

      # Step 3: Treatment duration
      trtdurd = new_admiral_block(state = list(
        fn = "derive_var_trtdurd",
        args = list(start_date = "RFSTDT", end_date = "RFENDT")
      )),

      # Step 4: Study days
      studyday = new_admiral_block(state = list(
        fn = "derive_vars_dy",
        args = list(reference_date = "RFSTDT")
      )),

      # Step 5: Sequence number
      aseq = new_admiral_block(state = list(
        fn = "derive_var_obs_number",
        args = list()
      ))
    ),
    links = list(
      list(from = "sdtm", to = "dm_table", input = "data"),
      list(from = "dm_table", to = "prep", input = "data"),
      list(from = "prep", to = "parse_rfst", input = "data"),
      list(from = "parse_rfst", to = "parse_rfen", input = "data"),
      list(from = "parse_rfen", to = "trtdurd", input = "data"),
      list(from = "trtdurd", to = "studyday", input = "data"),
      list(from = "studyday", to = "aseq", input = "data")
    )
  )
)
