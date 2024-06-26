#' @title A print method for twowayfeweights objects
#' @name print.twowayfeweights
#' @description Printed display of twowayfeweights objects.
#' @param x A twowayfeweights object.
#' @param ... Currently ignored.
#' @inherit twowayfeweights examples
#' @export
print.twowayfeweights = function(x, ...) {

  other_treats = !is.null(x$other_treatments)

  treat = "ATT"

  assumption = if (x$type %in% c("feTR", "fdTR")) {
    "Under the common trends assumption,\n"
  } else if (x$type %in% c("feS", "fdS")) {
    "Under the common trends, treatment monotonicity, and if groups' treatment effect does not change over time,\n"
  } else "BLANK"

  if (other_treats) {
    assumption_string = paste(
      assumption,
      sprintf("the TWFE coefficient beta, equal to %.4f, estimates the sum of several terms.\n\n", x$beta),
      sprintf("The first term is a weighted sum of %d %ss.", x$nr_plus + x$nr_minus, treat), 
      sep = ""
    )
  } else {
    assumption_string = paste(
      assumption,
      sprintf("the TWFE coefficient beta, equal to %.4f, estimates a weighted sum of %d %ss.", x$beta, x$nr_plus + x$nr_minus, treat), 
      sep = ""
    )
  } 

  weight_string = sprintf(
    "%d %ss receive a positive weight, and %d receive a negative weight.",
    x$nr_plus,
    treat,
    x$nr_minus
  )
  if (x$tot_cells > x$nr_plus + x$nr_minus) {
    weight_string = sprintf("%s\n%d (g,t) cells receive the treatment, but the %ss of %d cells receive a weight equal to zero.", weight_string, x$tot_cells, treat,x$tot_cells - (x$nr_plus + x$nr_minus))
  }

  tot_weights = x$nr_plus + x$nr_minus
  tot_sums = round(x$sum_plus + x$sum_minus, 4)

  # cat("\n")
  # cat(cli::rule())
  cat("\n")
  cat(assumption_string)
  cat("\n")
  cat(weight_string)
  cat("\n")
  cat("\n")

  tmat = cbind(
    c(x$nr_plus, x$nr_minus, tot_weights),
    c(round(x$sum_plus, 4), round(x$sum_minus, 4), tot_sums)
  )
  ## Rather use custom print method defined below
  # colnames(tmat) = c(paste0(treat, "s"), paste0("\U03A3", " weights"))
  # rownames(tmat) = c("Positive weights", "Negative weights", "Total")
  # cat(paste0("Treat. var: ", x$params$D), "\n")
  # print(tmat, quote = FALSE, print.gap = 2L, right = TRUE)
  print_treat_matrix(tmat = tmat, tvar = x$params$D, ttype = treat)


  # print other treatments
  if (other_treats) {
    for (otvar in x$other_treatments) {

      ox = x[[otvar]]

      otot_weights = ox$nr_plus + ox$nr_minus
      otot_sums = round(ox$sum_plus + ox$sum_minus, 4)

      otmat = cbind(
        c(ox$nr_plus, ox$nr_minus, otot_weights),
        c(round(ox$sum_plus, 4), round(ox$sum_minus, 4), otot_sums)
      )

      oassumption_string = sprintf("The next term is a weighted sum of %d %ss.", ox$nr_plus + ox$nr_minus, treat)
      oweight_string = sprintf(
        "%d %ss receive a positive weight, and %d receive a negative weight.",
        ox$nr_plus,
        treat,
        ox$nr_minus
      )
      if (ox$tot_cells > ox$nr_plus + ox$nr_minus) {
        oweight_string = sprintf("%s\n%d (g,t) cells receive the treatment, but the %ss of %d cells receive a weight equal to zero.", oweight_string, ox$tot_cells, treat,ox$tot_cells - (ox$nr_plus + ox$nr_minus))
      }

      cat("\n\n")
      cat(oassumption_string)
      cat("\n")
      cat(oweight_string)
      cat("\n\n")
      print_treat_matrix(tmat = otmat, tvar = otvar, ttype = treat, otreat = TRUE)

    }
  }

  # print summary measures
  if (isTRUE(x$summary_measures)) {
    subscr = substr(x$type, 1, 2)
    cat("\n\n")
    cat(cli::style_bold("Summary Measures:"))
    cat("\n")
    cat(sprintf("  TWFE Coefficient (\U03B2_%s): %.4f", subscr, x$beta))
    if (!is.null(x$sensibility)) {
      cat("\n")
      cat(sprintf("  min \U03C3(\U0394) compatible with \U03B2_%s and \U0394_TR = 0: %.4f", subscr, x$sensibility))
      if (!is.null(x$sensibility2) && x$sum_minus < 0) {
        cat("\n")
        cat(sprintf("  min \U03C3(\U0394) compatible with treatment effect of opposite sign than \U03B2_%s in all (g,t) cells: %.4f", subscr, x$sensibility2))
      }
      cat("\n")
      cat("  Reference: Corollary 1, de Chaisemartin, C and D'Haultfoeuille, X (2020a)")
    }
  }

  #print random weights
  if (!is.null(x$random_weights)) {
    cat("\n\n")
    cat(cli::style_bold("Regression of variables possibly correlated with the treatment effect on the weights:"))
    cat("\n")
    print(x$mat)
  }

  cat("\n\n")
  cat(cli::style_italic("The development of this package was funded by the European Union (ERC, REALLYCREDIBLE,GA N. 101043899)."))
  cat("\n\n")

  return(invisible(x))
}


## Custom print print method for treatment matrix
print_treat_matrix = function(tmat, tvar, ttype, otreat = FALSE) {

  # Prep matrix (add row and column headers)
  tmat = cbind(
    c("Positive weights", "Negative weights", "Total"),
    tmat
  )

  if (otreat) {
    tstring = paste0("Other treat.: ", gsub("^OT_", "", tvar))
  } else {
    tstring = paste0("Treat. var: ", tvar)
  }

  tmat = rbind(
    c(
      tstring,
      paste0(ttype, "s"),
      paste0("\U03A3", " weights")
    ),
    tmat
  )

  # Calculate the width for each column
  col_widths = apply(tmat, 2, function(x) max(nchar(x)))

  # Function to format a single row based on column widths
  format_row = function(row) {
    formatted_elements = mapply(function(x, width, idx) {
      if (idx == 1) {
        sprintf("%-*s", width, x)  # Left-align the first column
      } else {
        sprintf("%*s", width, x)   # Right-align all other columns
      }
    }, row, col_widths, seq_along(row))
    paste(formatted_elements, collapse = "    ")
  }

  # Create the header and separator line
  header = format_row(tmat[1, ])
  bold_header = cli::style_bold(header)
  # Calculate the separator line width
  separator_line_width = nchar(header)

  # Print separator line before header
  cat(cli::rule(width = separator_line_width), "\n")
  # Print the bold header
  cat(bold_header, "\n")
  # Print separator line after header
  cat(cli::rule(width = separator_line_width), "\n")

  # Print the body of the matrix except the last row
  for (i in 2:(nrow(tmat) - 1)) {
    cat(format_row(tmat[i, ]), "\n")
  }

  # Print separator line before last row
  cat(cli::rule(width = separator_line_width), "\n")
  # Print the last row
  cat(format_row(tmat[nrow(tmat), ]), "\n")
  # Print separator line after last row
  cat(cli::rule(width = separator_line_width))

}