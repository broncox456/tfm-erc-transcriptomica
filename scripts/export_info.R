# ============================================================
# Script: scripts/export_info.R
# Propósito: Exportar sessionInfo() para reproducibilidad
# ============================================================

timestamp <- format(Sys.time(), "%Y%m%d_%H%M")
out_file <- file.path("logs", paste0("session_", timestamp, ".txt"))

dir.create("logs", showWarnings = FALSE, recursive = TRUE)

sink(out_file)
cat("TFM_ERC_transcriptomica - Reproducibilidad\n")
cat("Timestamp: ", timestamp, "\n\n", sep = "")
cat("R version:\n")
print(R.version.string)
cat("\nSession info:\n")
print(sessionInfo())
sink()

message("OK: sessionInfo exportado a ", out_file)
