#' Combine terms in a regression model
#'
#' The function combines terms from a regression model, and replaces the terms
#' with a single row in the output table.  The p-value is calculated using
#' [stats::anova()].
#'
#' @param x a `tbl_regression` object
#' @param formula_update formula update passed to the [stats::update].
#' This updated formula is used to construct a reduced model, and is
#' subsequently passed to [stats::anova()] to calculate the p-value for the
#' group of removed terms.  See the [stats::update] help file for proper syntax.
#' function's `formula.=` argument
#' @param label Option string argument labeling the combined rows
#' @param ... Additional arguments passed to [stats::anova]
#' @inheritParams add_global_p
#' @author Daniel D. Sjoberg
#' @family tbl_regression tools
#' @seealso Review [list, formula, and selector syntax][syntax] used throughout gtsummary
#' @return `tbl_regression` object
#' @export
#'
#' @examples
#' \donttest{
#' # Example 1 ----------------------------------
#' # Logistic Regression Example, LRT p-value
#' combine_terms_ex1 <-
#'   glm(
#'     response ~ marker + I(marker^2) + grade,
#'     trial[c("response", "marker", "grade")] %>% na.omit(), # keep complete cases only!
#'     family = binomial
#'   ) %>%
#'   tbl_regression(label = grade ~ "Grade", exponentiate = TRUE) %>%
#'   # collapse non-linear terms to a single row in output using anova
#'   combine_terms(
#'     formula_update = . ~ . - marker - I(marker^2),
#'     label = "Marker (non-linear terms)",
#'     test = "LRT"
#'   )
#' }
#' @section Example Output:
#' \if{html}{Example 1}
#'
#' \if{html}{\figure{combine_terms_ex1.png}{options: width=45\%}}

combine_terms <- function(x, formula_update, label = NULL, quiet = NULL, ...) {
  assert_package("survival", "combine_terms()") # required for survreg() models
  updated_call_list <- c(x$call_list, list(combine_terms = match.call()))
  # setting defaults -----------------------------------------------------------
  quiet <- quiet %||% get_theme_element("pkgwide-lgl:quiet") %||% FALSE

  # checking input -------------------------------------------------------------
  if (!inherits(x, "tbl_regression")) {
    stop("`x` input must be class `tbl_regression`", call. = FALSE)
  }

  if (!is.null(label) && !rlang::is_string(label)) {
    stop(paste(
      "`label` argument must be a string of length one."
    ), call. = FALSE)
  }

  # creating updated model object ----------------------------------------------
  expr_update <-
    rlang::expr(stats::update(x$model_obj, formula. = !!formula_update)) %>%
    deparse() %>%
    paste(collapse = "") %>%
    stringr::str_squish()
  if (quiet == FALSE) {
    rlang::inform(glue("combine_terms: Creating a reduced model with\n  `reduced_model <- {expr_update}`"))
  }
  reduced_model <- stats::update(x$model_obj, formula. = formula_update)
  tryCatch(
    {
      expr_anova <-
        rlang::expr(stats::anova(x$model_obj, reduced_model, !!!list(...))) %>%
        deparse() %>%
        paste(collapse = "") %>%
        stringr::str_squish()
      if (quiet == FALSE) {
        rlang::inform(glue(
          "combine_terms: Calculating p-value comparing full and reduced models with\n",
          "  `{expr_anova}`"
        ))
      }

      anova <- stats::anova(x$model_obj, reduced_model, ...)
    },
    error = function(e) {
      err_msg <-
        paste(
          "There was error calculating the p-value in the",
          "'anova()' function.\n",
          "There are two common causes for an error during the calculation:\n",
          "1. The model type is not supported by 'anova()'.\n",
          "2. The number of observations used to estimate the full and reduced",
          "models is different.\n\n",
          as.character(e)
        )
      stop(err_msg, call. = FALSE)
    }
  )
  # extracting p-value from anova object ---------------------------------------
  df_anova <- as_tibble(anova) %>%
    select(starts_with("Pr(>"), starts_with("P(>"))
  # if no column was selected, print error
  if (ncol(df_anova) == 0) {
    stop(paste(
      "The output from `anova()` did not contain a p-value.\n",
      "A common source of this error is not specifying the `test=` argument.\n",
      "For example, to get the LRT p-value for a logistic regression estimated with `glm()`,\n",
      "include the argument `test = \"LRT\"` in the `combine_terms()` call."
    ), call. = FALSE)
  }

  anova_p <- df_anova %>%
    slice(n()) %>%
    pull()

  # if no p-value returned in p-value column
  if (is.na(anova_p)) {
    stop("The output from `anova()` did not contain a p-value.", call. = FALSE)
  }

  # tbl'ing the new model object -----------------------------------------------
  new_model_tbl <-
    rlang::call2(
      "tbl_regression",
      x = reduced_model, # updated model object
      label = x$inputs$label,
      exponentiate = x$inputs$exponentiate,
      include = rlang::expr(intersect(any_of(!!x$inputs$include), everything())),
      show_single_row = rlang::expr(intersect(any_of(!!x$inputs$show_single_row), everything())),
      conf.level = x$inputs$conf.level,
      intercept = x$inputs$intercept,
      estimate_fun = x$inputs$estimate_fun,
      pvalue_fun = x$inputs$pvalue_fun,
      tidy_fun = x$inputs$tidy_fun
    ) %>%
    eval()

  # updating original tbl object -----------------------------------------------
  # adding p-value column, if it is not already there
  if (!"p.value" %in% names(x$table_body)) {
    # adding p.value to table_body
    x$table_body <- mutate(x$table_body, p.value = NA_real_)
    x <-
      modify_table_styling(
        x,
        columns = "p.value",
        label = "**p-value**",
        hide = FALSE,
        fmt_fun = x$inputs$pvalue_fun %||% getOption("gtsummary.pvalue_fun", default = style_pvalue)
      )
  }
  # replacing the combined rows with a single row
  table_body <-
    x$table_body %>%
    left_join(
      new_model_tbl$table_body %>%
        select(
          .data$variable, .data$var_type, .data$reference_row,
          .data$row_type, .data$label
        ) %>%
        mutate(collapse_row = FALSE),
      by = c("variable", "var_type", "row_type", "reference_row", "label")
    ) %>%
    # marking rows on tbl that will be reduced to a single row
    mutate(collapse_row = ifelse(is.na(.data$collapse_row), TRUE, .data$collapse_row)) %>%
    group_by(.data$collapse_row) %>%
    filter(.data$collapse_row == FALSE |
      (dplyr::row_number() == 1 & .data$collapse_row == TRUE)) %>%
    # updating column values for collapsed rows
    mutate_at(
      vars(.data$estimate, .data$conf.low, .data$conf.high, .data$ci),
      ~ ifelse(.data$collapse_row == TRUE, NA, .)
    ) %>%
    mutate(
      p.value = ifelse(.data$collapse_row == TRUE, !!anova_p, .data$p.value),
      row_type = ifelse(.data$collapse_row == TRUE, "label", .data$row_type)
    ) %>%
    ungroup()

  # adding variable label, if specified ----------------------------------------
  if (!is.null(label)) {
    table_body <-
      table_body %>%
      mutate(label = ifelse(.data$collapse_row == TRUE, !!label, .data$label))
  }

  # writing over the table_body in x -------------------------------------------
  x$table_body <-
    table_body %>%
    select(-.data$collapse_row)

  # returning updated tbl object -----------------------------------------------
  x$call_list <- updated_call_list
  x
}
