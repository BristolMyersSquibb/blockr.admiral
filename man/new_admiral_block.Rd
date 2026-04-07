\name{new_admiral_block}
\alias{new_admiral_block}
\title{Admiral Derivation Block}
\usage{
new_admiral_block(state = list(fn = NULL, args = list()), ...)
}
\arguments{
\item{state}{List with \code{fn} (function name) and \code{args} (named list of argument values).}
\item{...}{Additional arguments forwarded to \code{blockr.core::new_transform_block()}.}
}
\description{
Universal block for admiral derive_* functions that operate on a single dataset.
Select a function from the catalog, configure its arguments, and the block
constructs and executes the call.
}
