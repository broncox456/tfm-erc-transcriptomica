required <- c(
  "README.md",
  "renv.lock",
  "CITATION.bib",
  "LICENSE",
  "config/paths.yml",
  "config/params.yml",
  "scripts/run_pipeline.R",
  "scripts/01_validate.R",
  "scripts/export_session_info.R",
  "scripts/snapshot_renv.R",
  "scripts/legacy_analysis.R",
  "results",
  "data",
  "R",
  "logs"
)

audit <- data.frame(
  file = required,
  exists = file.exists(required),
  size_bytes = ifelse(file.exists(required), file.info(required)$size, NA)
)

dir.create("results/tables", recursive = TRUE, showWarnings = FALSE)

write.table(
  audit,
  "results/tables/TFM_reproducibility_audit.tsv",
  sep = "\t",
  row.names = FALSE,
  quote = FALSE
)

print(audit)

if (any(!audit$exists)) {
  warning("Missing required files detected.")
} else {
  message("All required files are present.")
}
