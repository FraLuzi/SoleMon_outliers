# Species-specific abundance–weight outlier screening
#
# Purpose:
#   Screen catch records for potential inconsistencies in the relationship
#   between abundance (N) and total wet weight (W), separately by species.
#   Flagged records require verification against original field documentation
#   and expert review; this script does not correct or delete any data.
#
# Input:
#   An Excel file containing, at minimum, one column each for species code,
#   abundance, total wet weight, survey, and station.
#
# Output:
#   - all screened records with fitted values, residuals, and outlier flags
#   - records flagged as potential outliers only
#   - species-level model summary
#   - diagnostic plots for each eligible species
#
# Required packages:
#   install.packages(c("readxl", "dplyr", "ggplot2", "writexl","rstudioapi"))

library(readxl)
library(dplyr)
library(ggplot2)
library(writexl)
library(rstudioapi)
# -----------------------------------------------------------------------------
# 1. USER SETTINGS
# -----------------------------------------------------------------------------
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
input_file <- "../data/input_files.xlsx"
sheet_name <- 1
output_dir <- "../output"

# Replace these strings with the exact column names in your input file.
col_species <- "Code" #Species name or code
col_abundance <- "Numb"
col_weight <- "W(kg)"
col_survey <- "Survey" #the campaign from which the data comes
col_station <- "Station" #sampling point

# A species must have at least this number of complete records to be modelled.
min_records <- 6

# Potential outliers are defined using internally studentised residuals.
residual_threshold <- 3 #Cook, R. D. & Weisberg, S. Residuals and Influence in Regression. (New York: Chapman and Hall, 1982).

# -----------------------------------------------------------------------------
# 2. INPUT CHECKS AND DATA PREPARATION
# -----------------------------------------------------------------------------
dir.create(output_dir, showWarnings = FALSE)
dir.create(file.path(output_dir, "plots"), showWarnings = FALSE)

raw_data <- read_excel(input_file, sheet = sheet_name)

data_catch <- raw_data %>%
  transmute(
    Code = as.character(.data[[col_species]]),
    Numb = as.numeric(.data[[col_abundance]]),
    Weight_kg = as.numeric(.data[[col_weight]]),
    Survey = as.character(.data[[col_survey]]),
    Station = as.character(.data[[col_station]])
  ) %>%
  filter(
    !is.na(Code), Code != "",
    !is.na(Numb), Numb > 0,
    !is.na(Weight_kg), Weight_kg > 0
  )
# -----------------------------------------------------------------------------
# 3. SPECIES-SPECIFIC MODELS AND OUTLIER SCREENING
# -----------------------------------------------------------------------------

screened_records <- list()
model_summary <- list()

for (specie in sort(unique(data_catch$Code))) {
  
  data_sp <- data_catch %>%
    filter(Code == specie) %>%
    mutate(mean_W = Weight_kg / Numb)
  
  if (nrow(data_sp) < min_records) next
  
  model <- lm(log(Weight_kg) ~ log(Numb), data = data_sp)
  text_vals <- c(
    a = exp(model$coefficients[1]),
    b = model$coefficients[2],
    r = summary(model)$adj.r.squared
  )
  
  text_vals <- round(text_vals, 4)
  
  text <- paste0(
    "a = ", text_vals[1],
    "  b = ", text_vals[2],
    " r2 = ", text_vals[3])
  x_text <- min(data_sp$Numb)
  y_text <- max(data_sp$Weight_kg)
  
  data_sp <- data_sp %>%
    mutate(
      fitted_logW = fitted(model),
      predicted_Wkg = exp(fitted_logW),
      residual_logW = residuals(model),
      std_res = rstandard(model),
      Outlier = ifelse(abs(std_res) > residual_threshold, "YES", "NO")
    )
  
  screened_records[[specie]] <- data_sp
  
  model_summary[[specie]] <- tibble(
    Code = specie,
    n_records = nrow(data_sp),
    intercept = coef(model)[1],
    slope = coef(model)[2],
    adjusted_R2 = summary(model)$adj.r.squared,
    n_outliers = sum(data_sp$Outlier == "YES")
  )
  
  nw_plot <- ggplot(data_sp, aes(Numb, Weight_kg)) +
    geom_point(aes(colour = Outlier)) +
    geom_line(aes(y = predicted_Wkg), colour = "blue", linewidth = 1) +
    ggtitle(specie) +
    theme(plot.title = element_text(hjust = 0.5)) +
    xlab("N") +
    ylab("W (kg)") +
    annotate("text",
             x = x_text,
             y = y_text,
             label = text,
             size = 5,
             hjust = 0,
             vjust = 2)
  
  # boxplot peso medio
  w_boxplot <- ggplot(data_sp, aes(x = specie, y = mean_W)) +
    geom_boxplot() +
    geom_jitter(aes(colour = Outlier)) +
    ylab("Mean W (kg)") +
    ggtitle(specie) +
    theme(plot.title = element_text(hjust = 0.5))
  
  final_plot <- ggarrange(
    nw_plot,
    w_boxplot,
    common.legend = TRUE,
    legend = "right"
  )
  
  ggsave(
    filename = file.path(output_dir, "plots", paste0(specie, "_NW.png")),
    plot = final_plot,
    width = 18,
    height = 13,
    units = "cm",
    dpi = 300
  )
}

# -----------------------------------------------------------------------------
# 4. EXPORTS
# -----------------------------------------------------------------------------

screened_records <- bind_rows(screened_records)
model_summary <- bind_rows(model_summary)
potential_outliers <- screened_records %>%
  filter(Outlier == "YES")

write_xlsx(screened_records,
           file.path(output_dir, "all_screened_records.xlsx"))

write_xlsx(potential_outliers,
           file.path(output_dir, "potential_outliers.xlsx"))

write_xlsx(model_summary,
           file.path(output_dir, "species_model_summary.xlsx"))

cat("Screening completed.\n")
cat("Screened records:", nrow(screened_records), "\n")
cat("Potential outliers:", nrow(potential_outliers), "\n")

