new_CPplot_result <- function(plot, slopes, data_used, bracketing, bracketing_summary) {
  structure(
    list(
      plot = plot,
      slopes = slopes,
      bracketing = bracketing,
      bracketing_summary = bracketing_summary,
      data_used = data_used
    ),
    class = "CPplot_result"
  )
}

print.CPplot_result <- function(x, ...) {
  print(x$plot)
  invisible(x)
}
