% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/add_p.R
\name{add_p.tbl_summary}
\alias{add_p.tbl_summary}
\title{Adds p-values to summary tables}
\usage{
\method{add_p}{tbl_summary}(
  x,
  test = NULL,
  pvalue_fun = NULL,
  group = NULL,
  include = everything(),
  test.args = NULL,
  exclude = NULL,
  ...
)
}
\arguments{
\item{x}{Object with class \code{tbl_summary} from the \link{tbl_summary} function}

\item{test}{List of formulas specifying statistical tests to perform for each
variable,
e.g. \code{list(all_continuous() ~ "t.test", all_categorical() ~ "fisher.test")}.
Common tests include \code{"t.test"}, \code{"aov"}, \code{"wilcox.test"}, \code{"kruskal.test"},
\code{"chisq.test"}, \code{"fisher.test"}, and \code{"lme4"} (for clustered data). See \link{tests}
for details, more tests, and instruction for implementing a custom test.

Tests default to \code{"kruskal.test"} for continuous variables (\code{"wilcox.test"}
when "\code{by}" variable has two levels), \code{"chisq.test.no.correct"} for
categorical variables with all expected cell counts >=5, and \code{"fisher.test"}
for categorical variables with any expected cell count <5.}

\item{pvalue_fun}{Function to round and format p-values.
Default is \link{style_pvalue}.
The function must have a numeric vector input (the numeric, exact p-value),
and return a string that is the rounded/formatted p-value (e.g.
\code{pvalue_fun = function(x) style_pvalue(x, digits = 2)} or equivalently,
\code{purrr::partial(style_pvalue, digits = 2)}).}

\item{group}{Column name (unquoted or quoted) of an ID or grouping variable.
The column can be used to calculate p-values with correlated data.
Default is \code{NULL}. See \link{tests} for methods that utilize the \verb{group=} argument.}

\item{include}{Variables to include in output. Input may be a vector of
quoted variable names, unquoted variable names, or tidyselect select helper
functions. Default is \code{everything()}.}

\item{test.args}{List of formulas containing additional arguments to pass to
tests that accept arguments. For example, add an argument for all t-tests,
use \code{test.args = all_tests("t.test") ~ list(var.equal = TRUE)}}

\item{exclude}{DEPRECATED}

\item{...}{Not used}
}
\value{
A \code{tbl_summary} object
}
\description{
Adds p-values to tables created by \code{tbl_summary} by comparing values across groups.
}
\section{Example Output}{

\if{html}{Example 1}

\if{html}{\figure{add_p_ex1.png}{options: width=60\%}}

\if{html}{Example 2}

\if{html}{\figure{add_p_ex2.png}{options: width=60\%}}
}

\examples{
# Example 1 ----------------------------------
add_p_ex1 <-
  trial[c("age", "grade", "trt")] \%>\%
  tbl_summary(by = trt) \%>\%
  add_p()

# Example 2 ----------------------------------
add_p_ex2 <-
  trial \%>\%
  select(trt, age, marker) \%>\%
  tbl_summary(by = trt, missing = "no") \%>\%
  add_p(
    # perform t-test for all variables
    test = everything() ~ "t.test",
    # assume equal variance in the t-test
    test.args = all_tests("t.test") ~ list(var.equal = TRUE)
  )
}
\seealso{
See tbl_summary \href{http://www.danieldsjoberg.com/gtsummary/articles/tbl_summary.html}{vignette} for detailed examples

Review \link[=syntax]{list, formula, and selector syntax} used throughout gtsummary

Other tbl_summary tools: 
\code{\link{add_ci}()},
\code{\link{add_n.tbl_summary}()},
\code{\link{add_overall}()},
\code{\link{add_q}()},
\code{\link{add_stat_label}()},
\code{\link{bold_italicize_labels_levels}},
\code{\link{inline_text.tbl_summary}()},
\code{\link{inline_text.tbl_survfit}()},
\code{\link{modify}},
\code{\link{separate_p_footnotes}()},
\code{\link{tbl_custom_summary}()},
\code{\link{tbl_merge}()},
\code{\link{tbl_split}()},
\code{\link{tbl_stack}()},
\code{\link{tbl_strata}()},
\code{\link{tbl_summary}()}
}
\author{
Daniel D. Sjoberg, Emily C. Zabor
}
\concept{tbl_summary tools}
