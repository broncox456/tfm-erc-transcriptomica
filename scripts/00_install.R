# ============================================================
# Script: scripts/00_install.R
# Propósito: Inicializar o restaurar dependencias con renv
# ============================================================

if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv")
}

if (file.exists("renv.lock")) {
  renv::restore(prompt = FALSE)
} else {
  renv::init(bare = TRUE)
}
