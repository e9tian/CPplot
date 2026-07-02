slope_sign <- function(x, tol = sqrt(.Machine$double.eps)) {
  out <- rep("not available", length(x))
  ok <- is.finite(x)
  out[ok & x > tol] <- "positive"
  out[ok & x < -tol] <- "negative"
  out[ok & abs(x) <= tol] <- "zero"
  out
}

implication_for_sign <- function(sign, positive, negative, zero) {
  if (identical(sign, "positive")) {
    return(positive)
  }
  if (identical(sign, "negative")) {
    return(negative)
  }
  if (identical(sign, "zero")) {
    return(zero)
  }
  "No implication available"
}

cp_bracketing <- function(slopes, local = FALSE) {
  signs <- slope_sign(slopes$slope)
  if (local) {
    implications <- c(
      implication_for_sign(signs[[1L]], "tau_ATT^c >= tau_ATE^c >= tau_ATC^c", "tau_ATC^c >= tau_ATE^c >= tau_ATT^c", "tau_ATT^c = tau_ATE^c = tau_ATC^c"),
      implication_for_sign(signs[[2L]], "tau_ATT^c >= tau_ATO^c", "tau_ATT^c <= tau_ATO^c", "tau_ATT^c = tau_ATO^c"),
      implication_for_sign(signs[[3L]], "tau_ATO^c >= tau_ATC^c", "tau_ATO^c <= tau_ATC^c", "tau_ATO^c = tau_ATC^c")
    )
  } else {
    implications <- c(
      implication_for_sign(signs[[1L]], "ATT >= ATE >= ATC", "ATC >= ATE >= ATT", "ATT = ATE = ATC"),
      implication_for_sign(signs[[2L]], "ATT >= ATO", "ATT <= ATO", "ATT = ATO"),
      implication_for_sign(signs[[3L]], "ATO >= ATC", "ATO <= ATC", "ATO = ATC")
    )
  }

  data.frame(
    fit = slopes$fit,
    slope = slopes$slope,
    slope_sign = signs,
    implication = implications,
    stringsAsFactors = FALSE
  )
}

cp_bracketing_summary <- function(bracketing, local = FALSE) {
  signs <- bracketing$slope_sign
  if (length(signs) < 3L) {
    return("Bracketing summary unavailable.")
  }

  if (local) {
    if (identical(signs[[2L]], "positive") && identical(signs[[3L]], "positive")) {
      return("The tilted slopes support tau_ATC^c <= tau_ATO^c <= tau_ATT^c.")
    }
    if (identical(signs[[2L]], "negative") && identical(signs[[3L]], "negative")) {
      return("The tilted slopes support tau_ATT^c <= tau_ATO^c <= tau_ATC^c.")
    }
    return("The tilted slopes do not support a single ordering of tau_ATO^c between tau_ATT^c and tau_ATC^c.")
  }

  if (identical(signs[[2L]], "positive") && identical(signs[[3L]], "positive")) {
    return("The tilted slopes support ATC <= ATO <= ATT.")
  }
  if (identical(signs[[2L]], "negative") && identical(signs[[3L]], "negative")) {
    return("The tilted slopes support ATT <= ATO <= ATC.")
  }
  "The tilted slopes do not support a single ordering of ATO between ATT and ATC."
}
