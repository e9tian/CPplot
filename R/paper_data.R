paper_cp_treatment_vars <- c(
  abortion = "repeal",
  adult_servicesHot = "hot",
  adult_servicesReg = "reg",
  adult_servicesUnsafe = "unsafe",
  black_politicians = "treat_out",
  cavities_smoking = "secondhand.smoking.exposure",
  ccdrug = "male",
  rhc = "treatment.swang"
)

paper_cp_descriptions <- c(
  abortion = "Observational CP-plot intermediate data for the abortion application.",
  adult_servicesHot = "Observational CP-plot intermediate data for adult services (hot).",
  adult_servicesReg = "Observational CP-plot intermediate data for adult services (reg).",
  adult_servicesUnsafe = "Observational CP-plot intermediate data for adult services (unsafe).",
  black_politicians = "Observational CP-plot intermediate data for the black politicians application.",
  cavities_smoking = "Observational CP-plot intermediate data for the cavities and smoking application.",
  ccdrug = "Observational CP-plot intermediate data for the ccdrug application.",
  rhc = "Observational CP-plot intermediate data for the RHC application."
)

paper_data_dir <- function() {
  system.file("extdata/paper", package = "CPplot", mustWork = TRUE)
}

paper_datasets <- function() {
  observational <- data.frame(
    name = names(paper_cp_treatment_vars),
    type = "observational_cp",
    treatment_column = unname(paper_cp_treatment_vars),
    loader = paste0("load_paper_cp_data(\"", names(paper_cp_treatment_vars), "\")"),
    description = unname(paper_cp_descriptions),
    stringsAsFactors = FALSE
  )

  local_iv <- data.frame(
    name = "401k",
    type = "local_cp_iv",
    treatment_column = "Z",
    loader = "load_paper_401k_data()",
    description = "Unit-level modeled conditional Wald estimates for the 401(k) local CP plot.",
    stringsAsFactors = FALSE
  )

  rbind(observational, local_iv)
}

load_paper_rdata <- function(file) {
  env <- new.env(parent = emptyenv())
  load(file, envir = env)
  objs <- as.list(env)

  if ("a" %in% names(objs) && is.data.frame(objs[["a"]])) {
    return(objs[["a"]])
  }

  dfs <- Filter(is.data.frame, objs)
  for (df in dfs) {
    if (all(c("propensity_scores", "tau_hat") %in% names(df))) {
      return(df)
    }
  }

  if (length(dfs) > 0L) {
    return(dfs[[1L]])
  }

  stop("No data frame found in ", file, call. = FALSE)
}

load_paper_cp_data <- function(setting) {
  settings <- names(paper_cp_treatment_vars)
  if (!is.character(setting) || length(setting) != 1L) {
    stop("setting must be one of: ", paste(settings, collapse = ", "), call. = FALSE)
  }
  if (!setting %in% settings) {
    stop("Unknown setting: ", setting, ". Available settings: ", paste(settings, collapse = ", "), call. = FALSE)
  }

  file <- file.path(paper_data_dir(), "res_data", paste0(setting, "_data.RData"))
  if (!file.exists(file)) {
    stop("Cannot find bundled paper data file: ", file, call. = FALSE)
  }

  df <- load_paper_rdata(file)
  required <- c("propensity_scores", "tau_hat", paper_cp_treatment_vars[[setting]])
  if (!all(required %in% names(df))) {
    stop("Bundled data for ", setting, " is missing required columns: ", paste(required, collapse = ", "), call. = FALSE)
  }

  attr(df, "setting") <- setting
  attr(df, "treatment_column") <- paper_cp_treatment_vars[[setting]]
  attr(df, "source") <- file
  df
}

load_paper_401k_data <- function() {
  file <- file.path(paper_data_dir(), "tab_401k_unit_conditional_wald.csv")
  if (!file.exists(file)) {
    stop("Cannot find bundled 401(k) data file: ", file, call. = FALSE)
  }

  df <- utils::read.csv(file)
  required <- c("ehat", "Z", "delta_d", "tau_c_hat")
  if (!all(required %in% names(df))) {
    stop("Bundled 401(k) data is missing required columns: ", paste(required, collapse = ", "), call. = FALSE)
  }
  names(df)[names(df) == "ehat"] <- "e_hat"

  attr(df, "setting") <- "401k"
  attr(df, "source") <- file
  df
}
