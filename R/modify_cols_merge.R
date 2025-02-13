#' Modify Column Merging
#'
#' \lifecycle{experimental}
#' Merge two or more columns in a gtsummary table.
#' Use `show_header_names()` to print underlying column names.
#' @param pattern glue syntax string indicating how to merge columns in
#' `x$table_body`. For example, to construct a confidence interval
#' use `"{conf.low}, {conf.high}"`.
#' @inheritParams modify_table_styling
#'
#' @section Details:
#' 1. Calling this function merely records the instructions to merge columns.
#' The actual merging occurs when the gtsummary table is printed or converted
#' with a function like `as_gt()`.
#' 2. Because the column merging is delayed, it is recommended to perform
#' major modifications to the table, such as those with `tbl_merge()` and
#' `tbl_stack()`, before assigning merging instructions. Otherwise,
#' unexpected formatting may occur in the final table.
#'
#' @section Future Updates:
#' There are planned updates to the implementation of this function
#' with respect to the `pattern=` argument.
#' Currently, this function replaces a numeric column with a
#' formatted character column following `pattern=`.
#' Once `gt::cols_merge()` gains the `rows=` argument the
#' implementation will be updated to use it, which will keep
#' numeric columns numeric. For the _vast majority_ of users,
#' _the planned change will be go unnoticed_.
#' @return gtsummary table
#' @export
#'
#' @family Advanced modifiers
#' @examples
#' # Example 1 ----------------------------------
#' modify_cols_merge_ex1 <-
#'   trial %>%
#'   select(age, marker, trt) %>%
#'   tbl_summary(by = trt, missing = "no") %>%
#'   add_p(all_continuous() ~ "t.test",
#'         pvalue_fun = ~style_pvalue(., prepend_p = TRUE)) %>%
#'   modify_fmt_fun(statistic ~ style_sigfig) %>%
#'   modify_cols_merge(pattern = "t = {statistic}; {p.value}") %>%
#'   modify_header(statistic ~ "**t-test**")
#'
#' # Example 2 ----------------------------------
#' modify_cols_merge_ex2 <-
#'   lm(marker ~ age + grade, trial) %>%
#'   tbl_regression() %>%
#'   modify_cols_merge(
#'     pattern = "{estimate} ({ci})",
#'     rows = !is.na(estimate)
#'   )
#' @section Example Output:
#' \if{html}{Example 1}
#'
#' \if{html}{\figure{modify_cols_merge_ex1.png}{options: width=65\%}}
#'
#' \if{html}{Example 2}
#'
#' \if{html}{\figure{modify_cols_merge_ex2.png}{options: width=41\%}}
modify_cols_merge <- function(x, pattern, rows = NULL) {
  # check inputs ---------------------------------------------------------------
  if (!inherits(x, "gtsummary")) abort("`x=` must be class 'gtsummary'")
  if (!rlang::is_string(pattern)) abort("`pattern=` must be a string.")
  updated_call_list <- c(x$call_list, list(modify_column_hide = match.call()))

  # extract columns from pattern -----------------------------------------------
  columns <-
    pattern %>%
    str_extract_all("\\{.*?\\}") %>%
    map(str_remove_all, pattern = "^\\{|\\}$") %>%
    unlist()
  if (length(columns) == 0L) {
    cli::cli_alert_danger("No column names found in {.code modify_cols_merge(pattern=)}")
    cli::cli_ul("Wrap all column names in curly brackets.")
    abort("Error in `pattern=` argument")
  }
  if (!all(columns %in% names(x$table_body))) {
    problem_cols <- columns %>% setdiff(names(x$table_body))
    paste("Some columns specified in {.code modify_cols_merge(pattern=)}",
          "were not found in the table, e.g. {.val {problem_cols}}") %>%
    cli::cli_alert_danger()
    cli::cli_ul("Select from {.val {names(x$table_body)}}.")
    abort("Error in `pattern=` argument")
  }

  # merge columns --------------------------------------------------------------
  x <-
    modify_table_styling(
      x,
      columns = columns[1],
      rows = {{ rows }},
      hide = FALSE,
      cols_merge_pattern = pattern,
    )

  # return gtsummary table -----------------------------------------------------
  x$call_list <- updated_call_list
  x
}
