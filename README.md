# blockr.admiral

blockr.admiral provides interactive blocks for clinical data derivations using the [admiral](https://pharmaverse.github.io/admiral/) package. Transform SDTM data into ADaM datasets through a visual pipeline.

## Overview

blockr.admiral is part of the [blockr](https://blockr-org.github.io/blockr.site/) ecosystem. It wraps admiral's `derive_*` functions in visual blocks with guided argument configuration: searchable function selection, adaptive inputs, and rich descriptions.

## Installation

```r
# install.packages("pak")
pak::pak("blockr-org/blockr.admiral")
```

## Getting Started

```r
library(blockr.core)
library(blockr.admiral)

# Single block: parse dates from SDTM DM
serve(
  new_admiral_block(
    state = list(
      fn = "derive_vars_dt",
      args = list(new_vars_prefix = "RFST", dtc = "RFSTDTC")
    )
  ),
  data = list(data = pharmaversesdtm::dm)
)
```

## Available Blocks

| Block | Inputs | Description |
|-------|--------|-------------|
| Admiral Derivation | 1 | Apply any single-input `derive_*` function |
| Admiral Merge | 2 | Merge variables from a second dataset |

### Supported Functions (v1)

**Simple Derivations:** `derive_var_chg`, `derive_var_pchg`, `derive_var_trtdurd`, `derive_var_age_years`, `derive_var_analysis_ratio`

**Dates & Times:** `derive_vars_dt`, `derive_vars_dtm`, `derive_vars_dtm_to_dt`, `derive_vars_dtm_to_tm`, `derive_vars_dy`

**Duration:** `derive_vars_duration`

**Flags:** `derive_var_extreme_flag`, `derive_var_anrind`, `derive_var_obs_number`

**Baseline:** `derive_var_base`

**Merge:** `derive_vars_merged`

## SDTM to ADSL Pipeline

Build an ADSL dataset step by step, with each derivation as a separate block:

```r
library(blockr.core)
library(blockr.admiral)
library(blockr.dplyr)
library(blockr.dock)
library(blockr.dag)

serve(
  new_dock_board(
    blocks = c(
      dm = new_dataset_block(dataset = "dm", package = "pharmaversesdtm"),
      prep = new_mutate_block(state = list(
        mutations = list(
          list(name = "TRT01P", expr = "ARM"),
          list(name = "TRT01A", expr = "ACTARM")
        )
      )),
      parse_rfst = new_admiral_block(state = list(
        fn = "derive_vars_dt",
        args = list(new_vars_prefix = "RFST", dtc = "RFSTDTC")
      )),
      trtdurd = new_admiral_block(state = list(
        fn = "derive_var_trtdurd",
        args = list(start_date = "RFSTDT", end_date = "RFENDT")
      ))
    ),
    links = list(
      list(from = "dm", to = "prep", input = "data"),
      list(from = "prep", to = "parse_rfst", input = "data"),
      list(from = "parse_rfst", to = "trtdurd", input = "data")
    ),
    extensions = new_dag_extension()
  )
)
```

See `inst/examples/sdtm-to-adsl.R` for a complete pipeline with merge blocks.
