# Run the SDTM → ADSL board against LOCAL source checkouts (your latest
# uncommitted changes to any blockr package). This is the pkgload::load_all()
# counterpart of the shipped, library()-based inst/examples/sdtm-to-adsl.R: it
# just flips the loader and sources it, so the two can never drift.
#
# Run from an R session at the workspace root:
#   source("blockr.admiral/dev/sdtm-to-adsl.R")
#
# (End users without the source checkouts run the shipped copy instead:
#   source(system.file("examples/sdtm-to-adsl.R", package = "blockr.admiral")))

options(shiny.port = 3838, shiny.host = "0.0.0.0")

dev_local <- TRUE
source("blockr.admiral/inst/examples/sdtm-to-adsl.R")
