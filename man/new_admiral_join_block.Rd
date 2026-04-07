\name{new_admiral_join_block}
\alias{new_admiral_join_block}
\title{Admiral Merge Block}
\usage{
new_admiral_join_block(state = list(fn = NULL, args = list()), ...)
}
\arguments{
\item{state}{List with \code{fn} (function name) and \code{args} (named list of argument values).}
\item{...}{Additional arguments forwarded to \code{blockr.core::new_transform_block()}.}
}
\description{
Block for admiral derive_* functions that merge data from a second dataset.
Takes two data inputs: the primary dataset and the additional dataset to merge from.
}
