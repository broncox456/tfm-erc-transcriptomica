message("=== VALIDANDO PROYECTO TFM ERC TRANSCRIPTOMICA ===")

required_dirs <- c(
  "R",
  "scripts",
  "results",
  "results/figures",
  "results/tables",
  "docs",
  "logs",
  "config"
)

required_files <- c(
  "README.md",
  "renv.lock",
  "run_pipeline.ps1",
  "audit_final_delivery.ps1",
  "docs/output_traceability.md"
)

required_figures <- c(
  "results/figures/TFM_PCA.png",
  "results/figures/TFM_Volcano.png",
  "results/figures/TFM_Heatmap_Top30.png",
  "results/figures/TFM_GO_BP_Dotplot.png"
)

required_tables <- c(
  "results/tables/DE_all_genes.tsv",
  "results/tables/DE_significant_genes.tsv",
  "results/tables/TFM_Top20_DE.tsv",
  "results/tables/TFM_GO_BP_Top15.tsv",
  "results/tables/TFM_QC_summary.tsv",
  "results/tables/TFM_reproducibility_audit.tsv"
)

missing_dirs <- required_dirs[!dir.exists(required_dirs)]
missing_files <- required_files[!file.exists(required_files)]
missing_figures <- required_figures[!file.exists(required_figures)]
missing_tables <- required_tables[!file.exists(required_tables)]

if (length(missing_dirs) > 0) stop(paste("Missing directories:", paste(missing_dirs, collapse = ", ")))
if (length(missing_files) > 0) stop(paste("Missing files:", paste(missing_files, collapse = ", ")))
if (length(missing_figures) > 0) stop(paste("Missing figures:", paste(missing_figures, collapse = ", ")))
if (length(missing_tables) > 0) stop(paste("Missing tables:", paste(missing_tables, collapse = ", ")))

message("Required directories: OK")
message("Required files: OK")
message("Required figures: OK")
message("Required tables: OK")
message("Project validation completed successfully")
