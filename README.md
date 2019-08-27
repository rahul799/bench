
<!-- README.md is generated from README.Rmd. Please edit that file -->

# bench

[![CRAN
status](https://www.r-pkg.org/badges/version/bench)](https://cran.r-project.org/package=bench)
[![Travis build
status](https://travis-ci.org/r-lib/bench.svg?branch=master)](https://travis-ci.org/r-lib/bench)
[![AppVeyor build
status](https://ci.appveyor.com/api/projects/status/github/r-lib/bench?branch=master&svg=true)](https://ci.appveyor.com/project/r-lib/bench)
[![Coverage
status](https://codecov.io/gh/r-lib/bench/branch/master/graph/badge.svg)](https://codecov.io/github/r-lib/bench?branch=master)

The goal of bench is to benchmark code, tracking execution time, memory
allocations and garbage collections.

## Installation

You can install the release version from
[CRAN](https://cran.r-project.org/) with:

``` r
install.packages("bench")
```

Or you can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("r-lib/bench")
```

## Features

`bench::mark()` is used to benchmark one or a series of expressions, we
feel it has a number of advantages over [alternatives](#alternatives).

  - Always uses the highest precision APIs available for each operating
    system (often nanoseconds).
  - Tracks memory allocations for each expression.
  - Tracks the number and type of R garbage collections per expression
    iteration.
  - Verifies equality of expression results by default, to avoid
    accidentally benchmarking inequivalent code.
  - Has `bench::press()`, which allows you to easily perform and combine
    benchmarks across a large grid of values.
  - Uses adaptive stopping by default, running each expression for a set
    amount of time rather than for a specific number of iterations.
  - Expressions are run in batches and summary statistics are calculated
    after filtering out iterations with garbage collections. This allows
    you to isolate the performance and effects of garbage collection on
    running time (for more details see [Neal
    2014](https://radfordneal.wordpress.com/2014/02/02/inaccurate-results-from-microbenchmark/)).

The times and memory usage are returned as custom objects which have
human readable formatting for display (e.g. `104ns`) and comparisons
(e.g. `x$mem_alloc > "10MB"`).

There is also full support for plotting with
[ggplot2](http://ggplot2.tidyverse.org/) including custom scales and
formatting.

## Usage

### `bench::mark()`

Benchmarks can be run with `bench::mark()`, which takes one or more
expressions to benchmark against each other.

``` r
library(bench)
set.seed(42)
dat <- data.frame(x = runif(10000, 1, 1000), y=runif(10000, 1, 1000))
```

`bench::mark()` will throw an error if the results are not equivalent,
so you don’t accidentally benchmark inequivalent code.

``` r
bench::mark(
  dat[dat$x > 500, ],
  dat[which(dat$x > 499), ],
  subset(dat, x > 500))
#> Error: Each result must equal the first result:
#>   `[` does not equal `[`Each result must equal the first result:
#>   `dat` does not equal `dat`Each result must equal the first result:
#>   `dat$x > 500` does not equal `which(dat$x > 499)`Each result must equal the first result:
#>   `` does not equal ``
```

Results are easy to interpret, with human readable units.

``` r
bnch <- bench::mark(
  dat[dat$x > 500, ],
  dat[which(dat$x > 500), ],
  subset(dat, x > 500))
bnch
#> # A tibble: 3 x 6
#>   expression                     min   median `itr/sec` mem_alloc `gc/sec`
#>   <bch:expr>                <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
#> 1 dat[dat$x > 500, ]           362us    392us     2365.     377KB     23.8
#> 2 dat[which(dat$x > 500), ]    316us    355us     2628.     260KB     15.3
#> 3 subset(dat, x > 500)         471us    525us     1867.     509KB     24.7
```

By default the summary uses absolute measures, however relative results
can be obtained by using `relative = TRUE` in your call to
`bench::mark()` or calling `summary(relative = TRUE)` on the results.

``` r
summary(bnch, relative = TRUE)
#> # A tibble: 3 x 6
#>   expression                  min median `itr/sec` mem_alloc `gc/sec`
#>   <bch:expr>                <dbl>  <dbl>     <dbl>     <dbl>    <dbl>
#> 1 dat[dat$x > 500, ]         1.15   1.10      1.27      1.45     1.56
#> 2 dat[which(dat$x > 500), ]  1      1         1.41      1        1   
#> 3 subset(dat, x > 500)       1.49   1.48      1         1.96     1.62
```

### `bench::press()`

`bench::press()` is used to run benchmarks against a grid of parameters.
Provide setup and benchmarking code as a single unnamed argument then
define sets of values as named arguments. The full combination of values
will be expanded and the benchmarks are then *pressed* together in the
result. This allows you to benchmark a set of expressions across a wide
variety of input sizes, perform replications and other useful tasks.

``` r
set.seed(42)

create_df <- function(rows, cols) {
  as.data.frame(setNames(
    replicate(cols, runif(rows, 1, 100), simplify = FALSE),
    rep_len(c("x", letters), cols)))
}

results <- bench::press(
  rows = c(1000, 10000),
  cols = c(2, 10),
  {
    dat <- create_df(rows, cols)
    bench::mark(
      min_iterations = 100,
      bracket = dat[dat$x > 500, ],
      which = dat[which(dat$x > 500), ],
      subset = subset(dat, x > 500)
    )
  }
)
#> Running with:
#>    rows  cols
#> 1  1000     2
#> 2 10000     2
#> 3  1000    10
#> 4 10000    10
results
#> # A tibble: 12 x 8
#>    expression  rows  cols      min   median `itr/sec` mem_alloc `gc/sec`
#>    <bch:expr> <dbl> <dbl> <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
#>  1 bracket     1000     2   59.8us   77.8us    10603.   15.84KB     6.34
#>  2 which       1000     2   59.1us  100.5us     9562.    7.91KB     6.63
#>  3 subset      1000     2   93.6us  106.4us     7011.    27.7KB     6.26
#>  4 bracket    10000     2  109.7us  126.9us     6345.  156.46KB    25.8 
#>  5 which      10000     2   98.3us  111.9us     7527.   78.23KB    13.0 
#>  6 subset     10000     2  175.4us  202.5us     4358.  273.79KB    30.5 
#>  7 bracket     1000    10    128us  144.9us     6206.   47.52KB    12.9 
#>  8 which       1000    10  121.8us  136.1us     6234.    7.91KB    10.7 
#>  9 subset      1000    10    171us  191.2us     4381.   59.38KB     8.43
#> 10 bracket    10000    10  228.9us  259.8us     3467.   469.4KB    42.9 
#> 11 which      10000    10  159.2us  173.5us     5262.   78.23KB     8.32
#> 12 subset     10000    10  289.8us  315.9us     2915.  586.73KB    37.2
```

## Plotting

`ggplot2::autoplot()` can be used to generate an informative default
plot. This plot is colored by gc level (0, 1, or 2) and faceted by
parameters (if any). By default it generates a
[beeswarm](https://github.com/eclarke/ggbeeswarm#geom_quasirandom) plot,
however you can also specify other plot types (`jitter`, `ridge`,
`boxplot`, `violin`). See `?autoplot.bench_mark` for full details.

``` r
ggplot2::autoplot(results)
```

<img src="man/figures/README-autoplot-1.png" width="100%" />

You can also produce fully custom plots by un-nesting the results and
working with the data directly.

``` r
library(tidyverse)
results %>%
  unnest(cols = c(time, gc)) %>%
  filter(gc == "none") %>%
  mutate(expression = as.character(expression)) %>%
  ggplot(aes(x = mem_alloc, y = time, color = expression)) +
    geom_point() +
    scale_color_bench_expr(scales::brewer_pal(type = "qual", palette = 3))
```

<img src="man/figures/README-custom-plot-new-1.png" width="100%" />

## `system_time()`

**bench** also includes `system_time()`, a higher precision alternative
to
[system.time()](https://www.rdocumentation.org/packages/base/versions/3.5.0/topics/system.time).

``` r
bench::system_time({ i <- 1; while(i < 1e7) i <- i + 1 })
#> process    real 
#>   4.82s   4.92s
bench::system_time(Sys.sleep(.5))
#> process    real 
#>       0   499ms
```

## Alternatives

  - [rbenchmark](https://cran.r-project.org/package=rbenchmark)
  - [microbenchmark](https://cran.r-project.org/package=microbenchmark)
  - [tictoc](https://cran.r-project.org/package=tictoc)
  - [system.time()](https://www.rdocumentation.org/packages/base/versions/3.5.0/topics/system.time)
