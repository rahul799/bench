new_bench_expr <- function(x) {
  names(x) <- auto_name(x)
  structure(x, class = c("bench_expr", "expression"))
}

#' @export
format.bench_expr <- function(x) {
  names(x)
}

#' @export
as.character.bench_expr <- format.bench_expr

#' @export
print.bench_expr <- function(x, ...) {
  x <- unname(unclass(x))
  NextMethod()
}

type_sum.bench_expr <- function(x) {
  "bch:expr"
}

#' @export
`[.bench_expr` <- function(x, i, ...) {
  new_bench_expr(NextMethod("["))
}

#' @export
`[[.bench_expr` <- function(x, i, ...) {
  new_bench_expr(NextMethod("[["))
}


pillar_shaft.bench_expr <- function(x, ...) {
  pillar::new_pillar_shaft_simple(format.bench_expr(x), align = "left", ...)
}

setOldClass(c("bench_expr", "expression"), expression())

auto_name <- function(x) {
  nms <- names(x)

  if (is.null(nms)) {
    nms <- rep("", length(x))
  }
  is_missing <- nms == ""
  nms[is_missing] <- vapply(x[is_missing], deparse_trunc, character(1))

  nms
}
