library(R.matlab)
library(readxl)
library(tools)
library(readr)
library(broom)
library(dplyr)
library(xtable)
library(quantreg)

path_MainFolder = r"(D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method\Code\)"


######### (1) Read gross return & g function

path_03 = file.path(path_MainFolder, "03  輸出資料 - 2021 JBF")
file_name = "TTM_30_g_Function_and_Its_Derivatives_1996_2021.xlsx"
file_R_g = file.path(path_03, file_name)
sheet_names = excel_sheets(file_R_g)

gross_return = read_excel(file_R_g, sheet = "gross return", col_names = FALSE)
g_function   = read_excel(file_R_g, sheet = "g", col_names = FALSE)

colnames(gross_return) = "R"
colnames(g_function) = c("b_4", "b_6", "b_8")

rm(path_03, file_name, file_R_g, sheet_names)


######### (2) Read realized return

path_01 = file.path(path_MainFolder, "01  輸出資料")
file_name = "Realized_Return_TTM_30.csv"
file_path = file.path(path_01, file_name)
realized_return = read_csv(file_path)

rm(path_01, file_name, file_path)


######### (3) Read physical PDF and CDF

path_06 = file.path(path_MainFolder, "06  輸出資料")

file_names = c(
  "b_4_AllR_PDF.mat", "b_4_AllR_CDF.mat",
  "b_6_AllR_PDF.mat", "b_6_AllR_CDF.mat",
  "b_8_AllR_PDF.mat", "b_8_AllR_CDF.mat"
)

# Read MATLAB .mat files, transpose the data, and convert them to data frames
mat_data = setNames(lapply(file_names, function(f) {
  mat_raw = readMat(file.path(path_06, f))
  df = as.data.frame(t(mat_raw[[1]]))
  return(df)
  }), 
  gsub("AllR_", "", file_path_sans_ext(file_names)))

# Unpack all list elements in mat_data into separate variables in the global environment
list2env(mat_data, envir = .GlobalEnv)

rm(path_06, file_names)


######### (4) Calculate expected return

calc_expected_return = function(pdf_df, R_vec, range = NULL) {
  # If a range is specified, filter the gross return vector and corresponding PDF
  if (!is.null(range)) {
    idx = which(R_vec >= range[1] & R_vec <= range[2])
    R_sub = R_vec[idx]
    pdf_sub = pdf_df[idx, , drop = FALSE]
  } else {
    R_sub = R_vec
    pdf_sub = pdf_df
  }
  
  # Normalize the PDF across each column (i.e., each month)
  pdf_norm = sweep(pdf_sub, 2, colSums(pdf_sub), "/")
  
  # Compute expected return for each column
  expected_return = colSums(t(t(pdf_norm) * R_sub))
  
  # Return result as a data frame
  return(data.frame(expected_return = expected_return))
}

R_vec = gross_return$R

# Full range
b_4_expected_return_full = calc_expected_return(b_4_PDF, R_vec)
b_6_expected_return_full = calc_expected_return(b_6_PDF, R_vec)
b_8_expected_return_full = calc_expected_return(b_8_PDF, R_vec)

# Core range [0.8, 1.2]
core_range = c(0.8, 1.2)
b_4_expected_return_core = calc_expected_return(b_4_PDF, R_vec, range = core_range)
b_6_expected_return_core = calc_expected_return(b_6_PDF, R_vec, range = core_range)
b_8_expected_return_core = calc_expected_return(b_8_PDF, R_vec, range = core_range)


######### (5) Regression - (A)

reg_data_OLS = data.frame(
  realized_ret = realized_return$realized_ret,
  
  expected_ret_b_4_full = b_4_expected_return_full$expected_return,
  expected_ret_b_6_full = b_6_expected_return_full$expected_return,
  expected_ret_b_8_full = b_8_expected_return_full$expected_return,
  
  expected_ret_b_4_core = b_4_expected_return_core$expected_return,
  expected_ret_b_6_core = b_6_expected_return_core$expected_return,
  expected_ret_b_8_core = b_8_expected_return_core$expected_return
)


OLS_b4_full  = lm(realized_ret ~ expected_ret_b_4_full, data = reg_data_OLS)
OLS_b6_full  = lm(realized_ret ~ expected_ret_b_6_full, data = reg_data_OLS)
OLS_b8_full  = lm(realized_ret ~ expected_ret_b_8_full, data = reg_data_OLS)

OLS_b4_core  = lm(realized_ret ~ expected_ret_b_4_core, data = reg_data_OLS)
OLS_b6_core  = lm(realized_ret ~ expected_ret_b_6_core, data = reg_data_OLS)
OLS_b8_core  = lm(realized_ret ~ expected_ret_b_8_core, data = reg_data_OLS)

# Combine coefficient estimates (alpha, beta) from all regressions
ols_tidy = rbind(
  tidy(OLS_b4_full) |> mutate(b = 4, range = "full"),
  tidy(OLS_b6_full) |> mutate(b = 6, range = "full"),
  tidy(OLS_b8_full) |> mutate(b = 8, range = "full"),
  
  tidy(OLS_b4_core) |> mutate(b = 4, range = "core"),
  tidy(OLS_b6_core) |> mutate(b = 6, range = "core"),
  tidy(OLS_b8_core) |> mutate(b = 8, range = "core")
)

# Combine R-squared and model summary statistics from all regressions
ols_glance = rbind(
  glance(OLS_b4_full) |> mutate(b = 4, range = "full"),
  glance(OLS_b6_full) |> mutate(b = 6, range = "full"),
  glance(OLS_b8_full) |> mutate(b = 8, range = "full"),
  
  glance(OLS_b4_core) |> mutate(b = 4, range = "core"),
  glance(OLS_b6_core) |> mutate(b = 6, range = "core"),
  glance(OLS_b8_core) |> mutate(b = 8, range = "core")
)

coef_tidy = ols_tidy %>%
  filter(term != "(Intercept)") %>%
  mutate(
    stars = case_when(
      p.value < 0.01 ~ "***",
      p.value < 0.05 ~ "**",
      p.value < 0.1  ~ "*",
      TRUE ~ ""
    ),
    coef_label = paste0(sprintf("%.4f", estimate), stars),
    t_label = paste0("(", sprintf("%.2f", statistic), ")"),
    term = "Coefficient"
  )

intercept_tidy = ols_tidy %>%
  filter(term == "(Intercept)") %>%
  mutate(
    coef_label = sprintf("%.4f", estimate),
    t_label = paste0("(", sprintf("%.2f", statistic), ")"),
    term = "Intercept"
  )

r2_row = ols_glance %>%
  mutate(
    coef_label = paste0(sprintf("%.2f", r.squared * 100), "%"),
    t_label = ""
  )

make_wide = function(df) {
  wide = reshape2::dcast(df, term ~ b + range, value.var = "coef_label")
  rownames(wide) = wide$term
  wide$term = NULL
  return(wide)
}

make_wide_t = function(df) {
  wide = reshape2::dcast(df, term ~ b + range, value.var = "t_label")
  rownames(wide) = wide$term
  wide$term = NULL
  return(wide)
}

coef_row = make_wide(coef_tidy)
intercept_row = make_wide(intercept_tidy)
t_row = make_wide_t(coef_tidy)
t_intercept_row = make_wide_t(intercept_tidy)

r2_row_wide = reshape2::dcast(r2_row, b + range ~ "R2", value.var = "coef_label") %>%
  mutate(col = paste0(b, "_", range)) %>%
  select(col, R2) %>%
  tibble::column_to_rownames("col") %>%
  t() %>%
  as.data.frame()

final_table = rbind(
  "Intercept"   = intercept_row,
  " "           = t_intercept_row,
  "Coefficient" = coef_row,
  "  "          = t_row,
  "R2_raw"      = r2_row_wide
)

col_order = c("4_full", "6_full", "8_full", "4_core", "6_core", "8_core")
final_table = final_table[, col_order]

print(
  xtable(final_table, 
         align = c("l", rep("c", ncol(final_table))), 
         sanitize.text.function = identity,
         sanitize.rownames.function = identity)
)


######### (6) Regression - (B)

compute_quantiles_from_cdf = function(cdf_df, R_vec, probs = seq(0.1, 0.9, by = 0.1)) {
  # Number of time periods (columns) in the CDF matrix
  n_months = ncol(cdf_df)
  
  # Initialize a matrix to store quantiles
  q_matrix = matrix(NA, nrow = length(probs), ncol = n_months)
  
  for (j in 1:n_months) {
    # Extract CDF for the current month
    cdf_col = cdf_df[, j]
    
    # Ensure the CDF is non-decreasing (fix small numerical issues)
    cdf_col = cummax(cdf_col)
    
    # Remove duplicated CDF values to avoid errors in approxfun
    keep = !duplicated(cdf_col)
    
    # Create an inverse CDF function using linear interpolation
    # rule = 2 allows extrapolation using the boundary values
    approx_fn = approxfun(cdf_col[keep], R_vec[keep], rule = 2)
    
    # Apply inverse CDF to get quantiles at specified probability levels
    q_matrix[, j] = approx_fn(probs)
  }
  
  # Label columns by month index
  colnames(q_matrix) = paste0("Month_", 1:n_months)
  
  # Label rows by quantile level
  rownames(q_matrix) = paste0(probs)
  
  # Return quantile table as a data frame
  return(as.data.frame(q_matrix))
}

R_vec = gross_return$R
b_4_quantiles = compute_quantiles_from_cdf(b_4_CDF, R_vec)
b_6_quantiles = compute_quantiles_from_cdf(b_6_CDF, R_vec)
b_8_quantiles = compute_quantiles_from_cdf(b_8_CDF, R_vec)



run_quantile_regressions <- function(quantile_df, realized_ret) {
  quantile_names = rownames(quantile_df)
  n_q = length(quantile_names)
  
  result_matrix = matrix(NA, nrow = 5, ncol = n_q)
  rownames(result_matrix) = c("Intercept", "", "Coefficient", "", "$R^2$")
  colnames(result_matrix) = quantile_names
  
  for (i in 1:n_q) {
    x = as.numeric(quantile_df[i, ])
    model = lm(realized_ret ~ x)
    model_summary = tidy(model)
    r2 = glance(model)$r.squared
    
    # Add significance stars based on p-value
    stars <- function(p) {
      if (p < 0.01) return("***")
      else if (p < 0.05) return("**")
      else if (p < 0.1) return("*")
      else return("")
    }
    
    # Format coefficients and t-values
    intercept = sprintf("%.2f", model_summary$estimate[1])
    intercept_t = sprintf("(%.2f)", model_summary$statistic[1])
    
    slope = sprintf("%.2f%s", model_summary$estimate[2], stars(model_summary$p.value[2]))
    slope_t = sprintf("(%.2f)", model_summary$statistic[2])
    
    r2_str = sprintf("%.2f%%", r2 * 100)
    
    # Store results in matrix
    result_matrix[, i] = c(intercept, intercept_t, slope, slope_t, r2_str)
  }
  
  # Return transposed summary as data frame
  return(as.data.frame(result_matrix))
}


realized_ret = realized_return$realized_ret
b_4_table = run_quantile_regressions(b_4_quantiles, realized_ret)
b_6_table = run_quantile_regressions(b_6_quantiles, realized_ret)
b_8_table = run_quantile_regressions(b_8_quantiles, realized_ret)

xtable(b_4_table,
       align = c("l", rep("c", ncol(b_4_table))),
       sanitize.text.function = identity,
       sanitize.rownames.function = identity)

xtable(b_6_table,
       align = c("l", rep("c", ncol(b_6_table))),
       sanitize.text.function = identity,
       sanitize.rownames.function = identity)

xtable(b_8_table,
       align = c("l", rep("c", ncol(b_8_table))),
       sanitize.text.function = identity,
       sanitize.rownames.function = identity)


######### (7) Regression - (C)

run_quantile_regressions <- function(quantile_df, realized_ret, match_tau = TRUE, tau_fixed = 0.5) {
  quantile_names = rownames(quantile_df)
  n_q = length(quantile_names)
  
  result_matrix = matrix(NA, nrow = 5, ncol = n_q)
  rownames(result_matrix) = c("Intercept", "", "Coefficient", "", "$R^2$")
  colnames(result_matrix) = quantile_names
  
  stars <- function(p) {
    if (p < 0.01) return("***")
    else if (p < 0.05) return("**")
    else if (p < 0.1) return("*")
    else return("")
  }
  
  for (i in 1:n_q) {
    x = as.numeric(quantile_df[i, ])
    tau_val = if (match_tau) i / 10 else tau_fixed
    
    model = rq(realized_ret ~ x, tau = tau_val)
    tidy_model = tidy(model, se.type = "nid")
    
    # pseudo R²
    rss_model = sum(abs(residuals(model)))
    rss_null = sum(abs(realized_ret - quantile(realized_ret, tau_val)))
    pseudo_r2 = max(0, 1 - rss_model / rss_null)
    r2_str = sprintf("%.2f%%", pseudo_r2 * 100)
    
    # coefficients
    intercept = sprintf("%.2f", tidy_model$estimate[1])
    intercept_t = sprintf("(%.2f)", tidy_model$statistic[1])
    
    slope = sprintf("%.2f%s", tidy_model$estimate[2], stars(tidy_model$p.value[2]))
    slope_t = sprintf("(%.2f)", tidy_model$statistic[2])
    
    result_matrix[, i] = c(intercept, intercept_t, slope, slope_t, r2_str)
  }
  
  return(as.data.frame(result_matrix))
}


# Run quantile regression C.1 (matching tau)
C1_b4_table = run_quantile_regressions(b_4_quantiles, realized_ret, match_tau = TRUE)
C1_b6_table = run_quantile_regressions(b_6_quantiles, realized_ret, match_tau = TRUE)
C1_b8_table = run_quantile_regressions(b_8_quantiles, realized_ret, match_tau = TRUE)

# Run quantile regression C.2 (fixed tau = 0.5)
C2_b4_table = run_quantile_regressions(b_4_quantiles, realized_ret, match_tau = FALSE, tau_fixed = 0.5)
C2_b6_table = run_quantile_regressions(b_6_quantiles, realized_ret, match_tau = FALSE, tau_fixed = 0.5)
C2_b8_table = run_quantile_regressions(b_8_quantiles, realized_ret, match_tau = FALSE, tau_fixed = 0.5)



escape_percent <- function(x) {
  x <- gsub("%", "\\\\%", x)
  return(x)
}


as_latex_table <- function(df, caption = NULL, label = NULL) {
  df[] <- lapply(df, escape_percent)
  latex_lines <- c("\\resizebox{\\textwidth}{!}{",
                   "\\begin{tabular}{lccccccccc}",
                   "\\toprule",
                   paste0("{} & ", paste(colnames(df), collapse = " & "), " \\\\"),
                   "\\midrule")
  
  for (i in 1:nrow(df)) {
    row_line <- paste(rownames(df)[i], "&", paste(df[i, ], collapse = " & "), "\\\\")
    latex_lines <- c(latex_lines, row_line)
  }
  
  latex_lines <- c(latex_lines, "\\bottomrule", "\\end{tabular}}")
  return(paste(latex_lines, collapse = "\n"))
}

cat(as_latex_table(C1_b4_table), sep = "\n\n")
cat(as_latex_table(C2_b4_table), sep = "\n\n")

cat(as_latex_table(C1_b6_table), sep = "\n\n")
cat(as_latex_table(C2_b6_table), sep = "\n\n")

cat(as_latex_table(C1_b8_table), sep = "\n\n")
cat(as_latex_table(C2_b8_table), sep = "\n\n")






