# blockr.admiral

Visual blocks for [admiral](https://pharmaverse.github.io/admiral/) clinical data derivations. Part of the [blockr](https://blockr-org.github.io/blockr.site/) ecosystem.

## Blocks

| Block | Inputs | Functions |
|-------|--------|-----------|
| Admiral Derivation | 1 | 42 single-dataset `derive_*` functions |
| Admiral Merge | 2 | 20 merge/join `derive_*` functions |

All 62 admiral `derive_*` functions are supported, organized into 8 groups: Simple Derivations, Dates & Times, Duration, Flags, Baseline, Merge & Lookup, Parameters, Records.

## Install

```r
pak::pak("blockr-org/blockr.admiral")
```

## Example: SDTM → ADSL

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
        mutations = list(list(name = "TRT01P", expr = "ARM"))
      )),
      dates = new_admiral_block(state = list(
        fn = "derive_vars_dt",
        args = list(new_vars_prefix = "RFST", dtc = "RFSTDTC")
      )),
      dur = new_admiral_block(state = list(
        fn = "derive_var_trtdurd",
        args = list(start_date = "RFSTDT", end_date = "RFENDT")
      ))
    ),
    links = list(
      list(from = "dm", to = "prep", input = "data"),
      list(from = "prep", to = "dates", input = "data"),
      list(from = "dates", to = "dur", input = "data")
    ),
    extensions = new_dag_extension()
  )
)
```

See `inst/examples/sdtm-to-adsl.R` for a full pipeline with merge blocks.

## Catalog maintenance

After updating admiral, run `inst/scripts/update-catalog.R` to check for new, removed, or changed functions.
