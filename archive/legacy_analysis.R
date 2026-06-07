
# ---- 0) CONFIG: elige dónde crear el proyecto ----
# Cambia esta ruta a una carpeta que exista en tu PC:
base_dir <- "C:/Users/Usuario/Desktop/TFM CAAR UAX" 

project_name <- "TFM_ERC_transcriptomica"
project_root <- file.path(base_dir, project_name)

# ---- 1) Crear estructura de carpetas ----
dir.create(project_root, recursive = TRUE, showWarnings = FALSE)

dirs <- c(
  "config",
  "data/raw", "data/meta", "data/processed", "data/cache",
  "notebooks",
  "R/utils",
  "scripts",
  "results/qc", "results/de", "results/go", "results/figures", "results/tables",
  "logs",
  "docs",
  "annexes"
)

for (d in dirs) dir.create(file.path(project_root, d), recursive = TRUE, showWarnings = FALSE)

# ---- 2) Función helper para escribir archivos ----
write_file <- function(rel_path, content) {
  path <- file.path(project_root, rel_path)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(content, con = path, useBytes = TRUE)
}

# ---- 3) Archivos base ----

# 3.1 .gitignore (FINAL, seguro)
write_file(".gitignore", c(
  "# R environment",
  ".Rhistory",
  ".RData",
  ".Rproj.user/",
  "",
  "# renv (no versionar librerías locales; sí versionar renv.lock)",
  "renv/library/",
  "renv/local/",
  "renv/staging/",
  "",
  "# Data pesada (NO versionar)",
  "data/raw/",
  "data/processed/",
  "data/cache/",
  "",
  "# Logs (NO versionar)",
  "logs/",
  "",
  "# Notebooks / IDE",
  ".ipynb_checkpoints/",
  ".vscode/",
  "",
  "# OS",
  ".DS_Store",
  "Thumbs.db"
))

# 3.2 README.md (mínimo)
write_file("README.md", c(
  "# TFM_ERC_transcriptomica (GEO) — Pipeline reproducible",
  "",
  "## Ejecución",
  "```bash",
  "Rscript scripts/run_pipeline.R",
  "```",
  "",
  "## Salidas principales",
  "- QC: `results/qc/`",
  "- Diferencial: `results/de/`",
  "- Enriquecimiento: `results/go/`",
  "- Figuras finales: `results/figures/`",
  "- Tablas finales: `results/tables/`",
  "",
  "## Reproducibilidad",
  "- Dependencias: `renv.lock`",
  "- Evidencia del entorno: `logs/session_*.txt`",
  "- Log de ejecución: `logs/pipeline_*.log`"
))

# 3.3 CITATION.bib (plantilla)
write_file("CITATION.bib", c(
  "% Añade aquí citas clave del dataset GEO y paquetes principales",
  "% Ejemplo (rellenar luego):",
  "% @misc{GEO_GSE104954, title={GSE104954}, howpublished={Gene Expression Omnibus (GEO)} }"
))

# 3.4 LICENSE (MIT simple)
write_file("LICENSE", c(
  "MIT License",
  "",
  "Copyright (c) 2026 Cristian Arias",
  "",
  "Permission is hereby granted, free of charge, to any person obtaining a copy",
  "of this software and associated documentation files (the \"Software\"), to deal",
  "in the Software without restriction, including without limitation the rights",
  "to use, copy, modify, merge, publish, distribute, sublicense, and/or sell",
  "copies of the Software, and to permit persons to whom the Software is",
  "furnished to do so, subject to the following conditions:",
  "",
  "The above copyright notice and this permission notice shall be included in all",
  "copies or substantial portions of the Software.",
  "",
  "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR",
  "IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,",
  "FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE",
  "AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER",
  "LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,",
  "OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE",
  "SOFTWARE."
))

# 3.5 config/paths.yml
write_file("config/paths.yml", c(
  "project_root: \".\"",
  "",
  "data:",
  "  raw: \"data/raw\"",
  "  meta: \"data/meta\"",
  "  processed: \"data/processed\"",
  "  cache: \"data/cache\"",
  "",
  "results:",
  "  qc: \"results/qc\"",
  "  de: \"results/de\"",
  "  go: \"results/go\"",
  "  figures: \"results/figures\"",
  "  tables: \"results/tables\"",
  "",
  "logs: \"logs\"",
  "annexes: \"annexes\"",
  "docs: \"docs\""
))

# 3.6 config/params.yml (dataset provisional)
write_file("config/params.yml", c(
  "dataset:",
  "  gse: \"GSE66494\"",
  "  platform: \"GPL570\"",
  "",
  "analysis:",
  "  contrast: \"CKD_vs_Control\"",
  "  fdr: 0.05",
  "  logfc: 1.0",
  "",
  "project:",
  "  seed: 123",
  "  author: \"Cristian Arias\""
))

# ---- 4) scripts: 00_install.R (renv) ----
write_file("scripts/00_install.R", c(
  "# ============================================================",
  "# Script: scripts/00_install.R",
  "# Propósito: Inicializar o restaurar dependencias con renv",
  "# ============================================================",
  "",
  "if (!requireNamespace(\"renv\", quietly = TRUE)) {",
  "  install.packages(\"renv\")",
  "}",
  "",
  "if (file.exists(\"renv.lock\")) {",
  "  renv::restore(prompt = FALSE)",
  "} else {",
  "  renv::init(bare = TRUE)",
  "}"
))

# ---- 5) scripts: 01_validate.R (valida YAML + crea carpetas) ----
write_file("scripts/01_validate.R", c(
  "# ============================================================",
  "# Script: scripts/01_validate.R",
  "# Propósito:",
  "#   - Validar archivos YAML",
  "#   - Crear estructura de carpetas si no existe",
  "# ============================================================",
  "",
  "suppressPackageStartupMessages({",
  "  library(yaml)",
  "  library(fs)",
  "  library(glue)",
  "})",
  "",
  "stop_pipeline <- function(msg) {",
  "  stop(glue(\"❌ VALIDATION ERROR: {msg}\"), call. = FALSE)",
  "}",
  "",
  "check_file <- function(path) {",
  "  if (!file_exists(path)) stop_pipeline(glue(\"Archivo requerido NO encontrado: {path}\"))",
  "}",
  "",
  "create_dir_safe <- function(path) {",
  "  if (!dir_exists(path)) dir_create(path, recurse = TRUE)",
  "}",
  "",
  "check_file(\"config/paths.yml\")",
  "check_file(\"config/params.yml\")",
  "",
  "paths_cfg  <- yaml::read_yaml(\"config/paths.yml\")",
  "params_cfg <- yaml::read_yaml(\"config/params.yml\")",
  "",
  "if (is.null(params_cfg$dataset$gse) || params_cfg$dataset$gse == \"\") {",
  "  stop_pipeline(\"dataset.gse no está definido en config/params.yml\")",
  "}",
  "message(glue(\"✔ Dataset definido: {params_cfg$dataset$gse}\"))",
  "",
  "create_dir_safe(paths_cfg$data$raw)",
  "create_dir_safe(paths_cfg$data$meta)",
  "create_dir_safe(paths_cfg$data$processed)",
  "create_dir_safe(paths_cfg$data$cache)",
  "",
  "create_dir_safe(paths_cfg$results$qc)",
  "create_dir_safe(paths_cfg$results$de)",
  "create_dir_safe(paths_cfg$results$go)",
  "create_dir_safe(paths_cfg$results$figures)",
  "create_dir_safe(paths_cfg$results$tables)",
  "",
  "create_dir_safe(paths_cfg$logs)",
  "create_dir_safe(paths_cfg$annexes)",
  "create_dir_safe(paths_cfg$docs)",
  "",
  "message(\"✅ VALIDACIÓN COMPLETA: estructura y configuración correctas\")"
))

# ---- 6) scripts: export_info.R (sessionInfo) ----
write_file("scripts/export_info.R", c(
  "# ============================================================",
  "# Script: scripts/export_info.R",
  "# Propósito: Exportar sessionInfo() para reproducibilidad",
  "# ============================================================",
  "",
  "timestamp <- format(Sys.time(), \"%Y%m%d_%H%M\")",
  "out_file <- file.path(\"logs\", paste0(\"session_\", timestamp, \".txt\"))",
  "",
  "dir.create(\"logs\", showWarnings = FALSE, recursive = TRUE)",
  "",
  "sink(out_file)",
  "cat(\"TFM_ERC_transcriptomica - Reproducibilidad\\n\")",
  "cat(\"Timestamp: \", timestamp, \"\\n\\n\", sep = \"\")",
  "cat(\"R version:\\n\")",
  "print(R.version.string)",
  "cat(\"\\nSession info:\\n\")",
  "print(sessionInfo())",
  "sink()",
  "",
  "message(\"OK: sessionInfo exportado a \", out_file)"
))

# ---- 7) scripts: run_pipeline.R (maestro) ----
write_file("scripts/run_pipeline.R", c(
  "#!/usr/bin/env Rscript",
  "cat(\"TFM Pipeline - Transcriptómica ERC (GEO)\\n\")",
  "",
  "# Orden fijo",
  "source(\"scripts/00_install.R\")",
  "source(\"scripts/01_validate.R\")",
  "",
  "source(\"R/00_setup.R\")",
  "",
  "# Etapas (mañana las implementamos una por una):",
  "source(\"R/01_download.R\")",
  "source(\"R/02_metadata.R\")",
  "source(\"R/03_normalize.R\")",
  "source(\"R/04_qc.R\")",
  "source(\"R/05_de.R\")",
  "source(\"R/06_enrichment.R\")",
  "",
  "source(\"scripts/export_info.R\")",
  "",
  "cat(\"✅ PIPELINE COMPLETO\\n\")"
))

# ---- 8) R/00_setup.R (carga configs) ----
write_file("R/00_setup.R", c(
  "# ============================================================",
  "# Script: R/00_setup.R",
  "# Propósito: Cargar configs y preparar entorno",
  "# ============================================================",
  "",
  "suppressPackageStartupMessages({",
  "  library(yaml)",
  "  library(fs)",
  "  library(glue)",
  "})",
  "",
  "PATHS  <- yaml::read_yaml(\"config/paths.yml\")",
  "PARAMS <- yaml::read_yaml(\"config/params.yml\")",
  "",
  "set.seed(PARAMS$project$seed %||% 123)",
  "",
  "`%||%` <- function(a, b) if (!is.null(a)) a else b",
  "",
  "# Crear carpetas (doble seguridad)",
  "create_dir_safe <- function(path) {",
  "  if (!fs::dir_exists(path)) fs::dir_create(path, recurse = TRUE)",
  "}",
  "",
  "create_dir_safe(PATHS$data$raw)",
  "create_dir_safe(PATHS$data$meta)",
  "create_dir_safe(PATHS$data$processed)",
  "create_dir_safe(PATHS$data$cache)",
  "",
  "create_dir_safe(PATHS$results$qc)",
  "create_dir_safe(PATHS$results$de)",
  "create_dir_safe(PATHS$results$go)",
  "create_dir_safe(PATHS$results$figures)",
  "create_dir_safe(PATHS$results$tables)",
  "",
  "create_dir_safe(PATHS$logs)",
  "create_dir_safe(PATHS$annexes)",
  "create_dir_safe(PATHS$docs)",
  "",
  "message(glue(\"OK: Setup cargado. Dataset: {PARAMS$dataset$gse}\"))"
))

# ---- 9) Placeholders de etapas (para que run_pipeline no falle hoy) ----
# Mañana reemplazamos estos placeholders por implementación real.
placeholders <- list(
  "R/01_download.R"      = "message('SKIP: 01_download.R aún no implementado (mañana)')",
  "R/02_metadata.R"      = "message('SKIP: 02_metadata.R aún no implementado (mañana)')",
  "R/03_normalize.R"     = "message('SKIP: 03_normalize.R aún no implementado (mañana)')",
  "R/04_qc.R"            = "message('SKIP: 04_qc.R aún no implementado (mañana)')",
  "R/05_de.R"            = "message('SKIP: 05_de.R aún no implementado (mañana)')",
  "R/06_enrichment.R"    = "message('SKIP: 06_enrichment.R aún no implementado (mañana)')"
)

for (f in names(placeholders)) write_file(f, placeholders[[f]])

# ---- 10) Mensaje final ----
cat("✅ Proyecto creado en:\n", project_root, "\n", sep = "")
cat("Siguiente: abre esa carpeta en RStudio y ejecuta:\n")
cat("  source('scripts/01_validate.R')\n")
cat("  source('scripts/00_install.R')\n")

