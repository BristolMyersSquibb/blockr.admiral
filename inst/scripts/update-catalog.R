# Update blockr.admiral function catalog from admiral package
#
# Run this script after updating the admiral package to detect new, removed,
# or changed functions. It compares the current catalog with admiral's exports
# and reports what needs attention.
#
# Usage:
#   Rscript inst/scripts/update-catalog.R
#
# The script does NOT auto-modify the catalog. It reports:
#   - NEW functions not yet in the catalog (need manual type annotation)
#   - REMOVED functions no longer in admiral (should be removed from catalog)
#   - CHANGED signatures (arguments added/removed — need review)
#
# After reviewing the output, manually update inst/extdata/admiral-functions.json.

library(admiral)
library(jsonlite)

cat("blockr.admiral catalog update check\n")
cat("admiral version:", as.character(packageVersion("admiral")), "\n")
cat(strrep("-", 60), "\n\n")

# Load current catalog
catalog_path <- file.path("inst", "extdata", "admiral-functions.json")
if (!file.exists(catalog_path)) {
  catalog_path <- system.file("extdata", "admiral-functions.json",
                              package = "blockr.admiral")
}
stopifnot(file.exists(catalog_path))
catalog <- fromJSON(catalog_path, simplifyVector = FALSE)
cat("Current catalog:", length(catalog), "functions\n")

# Get all derive_* functions from admiral
admiral_fns <- grep("^derive_", ls("package:admiral"), value = TRUE)
cat("Admiral exports:", length(admiral_fns), "derive_* functions\n\n")

# --- Check for NEW functions ---
new_fns <- setdiff(admiral_fns, names(catalog))
if (length(new_fns) > 0) {
  cat("NEW functions (not in catalog):\n")
  for (fn in new_fns) {
    f <- get(fn, envir = asNamespace("admiral"))
    args <- setdiff(names(formals(f)), c("dataset", "..."))
    has_add <- any(c("dataset_add", "dataset_adsl", "dataset_ref") %in%
                     names(formals(f)))
    cat(sprintf("  + %-45s args=%-2d %s\n", fn, length(args),
                if (has_add) "[needs 2nd input]" else ""))
  }
  warning(length(new_fns), " new function(s) need to be added to the catalog")
  cat("\n")
} else {
  cat("No new functions.\n\n")
}

# --- Check for REMOVED functions ---
removed_fns <- setdiff(names(catalog), admiral_fns)
if (length(removed_fns) > 0) {
  cat("REMOVED functions (in catalog but not in admiral):\n")
  for (fn in removed_fns) {
    cat(sprintf("  - %s\n", fn))
  }
  warning(length(removed_fns),
          " function(s) removed from admiral — remove from catalog")
  cat("\n")
} else {
  cat("No removed functions.\n\n")
}

# --- Check for CHANGED signatures ---
common_fns <- intersect(names(catalog), admiral_fns)
changes <- 0
for (fn in common_fns) {
  f <- get(fn, envir = asNamespace("admiral"))
  admiral_args <- setdiff(names(formals(f)),
                          c("dataset", "...", "dataset_add", "dataset_adsl",
                            "dataset_ref", "dataset_merge", "dataset_facm",
                            "source_datasets"))
  catalog_args <- names(catalog[[fn]]$args)

  added <- setdiff(admiral_args, catalog_args)
  removed <- setdiff(catalog_args, admiral_args)

  if (length(added) > 0 || length(removed) > 0) {
    if (changes == 0) cat("CHANGED signatures:\n")
    changes <- changes + 1
    cat(sprintf("  ~ %s\n", fn))
    if (length(added) > 0) {
      cat(sprintf("      added:   %s\n", paste(added, collapse = ", ")))
    }
    if (length(removed) > 0) {
      cat(sprintf("      removed: %s\n", paste(removed, collapse = ", ")))
    }
  }
}
if (changes > 0) {
  warning(changes, " function(s) have changed signatures — review catalog")
  cat("\n")
} else {
  cat("No signature changes.\n\n")
}

# --- Summary ---
cat(strrep("-", 60), "\n")
if (length(new_fns) == 0 && length(removed_fns) == 0 && changes == 0) {
  cat("Catalog is up to date with admiral ", as.character(packageVersion("admiral")),
      "\n", sep = "")
} else {
  total <- length(new_fns) + length(removed_fns) + changes
  cat(total, "issue(s) found. Update inst/extdata/admiral-functions.json.\n")
}
