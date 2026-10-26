
# Welcome to the Species-specific-abundance-weight-outlier-screening GitHub Page!

This repository hosts the R script used to screen species-specific catch
records for potential inconsistencies in the relationship between
abundance and total weight. It was developed as a quality-control
utility for survey catch data. The script identifies potential outliers
only. It does not automatically correct,remove, or modify records. Every
flagged record must be checked against the original field data sheets
and assessed by personnel familiar with the survey protocol, sampled
taxa, and catch-processing procedures before a decision is made to
correct, retain, or exclude it.

# Requirements

install.packages(c(“readxl”, “dplyr”, “ggplot2”,
“writexl”,“rstudioapi”,“ggpubr”))

# Input file

The input must be an Excel file (.xlsx) containing at least the
following fields:

- **Species identifier**, Species code or other taxon identifier =
  **Code**
- **Abundance**, Total number of individuals in the record = **Numb**
- **Total wet weight**, Total wet weight of the taxon, in kg = **W(kg)**
- **Survey identifier**, Survey, cruise, or sampling-event identifier =
  **Survey**
- **Station identifier**, Sampling-station identifier = **Station**

Example of the input file:

| Survey      | Station | SpeciesSN              | Code    | W(kg) | Numb |
|:------------|:--------|:-----------------------|:--------|------:|-----:|
| SOLEMON2019 | 1       | Melicertus kerathurus# | MELIKER | 0.303 |   18 |
| SOLEMON2019 | 1       | Pecten jacobaeus#      | PECTJAC | 0.140 |    1 |
| SOLEMON2019 | 1       | Sepia officinalis#     | SEPIOFF | 0.307 |    2 |
| SOLEMON2019 | 1       | Squilla mantis#        | SQUIMAN | 0.056 |    1 |
| SOLEMON2019 | 1       | Eledone moschata       | ELEDMOS | 0.514 |    1 |
| SOLEMON2019 | 1       | Melicertus kerathurus# | MELIKER | 0.373 |   24 |

The script includes only records with a non-missing species identifier,
positive abundance, and positive total wet weight. It fits models only
for species represented by at least six eligible records by default

# Set up and run

1.  Download or clone this repository.

2.  Place the R script and the input Excel file in an accessible working
    directory.

3.  Open nw_outlier_screening_general.R in RStudio.

4.  Edit the USER SETTINGS section at the top of the script:

- min_records \<- 6 \# minimum number of records per species

- residual_threshold \<- 3 \# \|internally studentised residual\|
  threshold

- output_dir \<- “output” \# folder where results are saved

5.  Run the complete script.

# Output files

The script creates the folder specified in output_dir, with the
following files:

1.  **all_screened_records.xlsx**, All records included in the
    species-specific regression screening, including predicted weights,
    residuals, internally studentised residuals, and outlier flags
2.  **potential_outliers.xlsx**, Records flagged because the absolute
    internally studentised residual exceeds the selected threshold
3.  **species_model_summary.xlsx**, Number of screened records, model
    coefficients, adjusted R^2, and number of flagged records for each
    species
4.  **plots**, Species-specific abundance–weight diagnostic plots, with
    flagged records highlighted

# Review of flagged records

The output ‘potential_outliers.xlsx’ is a list for review, not a list of
records to delete. For each flagged record:

1.  Check the original paper field sheet completed during sampling.

2.  Correct the digital record if the field sheet shows a transcription
    or data-entry error.

3.  If the digital value matches the field sheet, assess whether the
    number–weight combination is biologically and operationally
    plausible.

4.  Consider the species, likely size composition of the catch,
    aggregations, occasional large individuals, and information recorded
    during the sampling event.

5.  Retain the record if it is supported by the field documentation and
    is plausible; exclude it only if it cannot be validated or is judged
    unreliable for analytical use.

Decisions concerning correction, retention, or exclusion should be
documented during the quality-control process.

# Notes

• This screening method does not replace taxonomic validation,
geographic validation, range checks, or expert review.

• A statistical outlier may be a valid biological observation.

• The script does not alter the original input file.

• For commercial species with individual length measurements, a separate
length–weight quality-control procedure may be more appropriate than an
abundance–weight screening.
