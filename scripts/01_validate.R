# ============================================================
# Script: scripts/01_validate.R
# Propósito:
#   - Validar archivos YAML
#   - Crear estructura de carpetas si no existe
# ============================================================

suppressPackageStartupMessages({
  library(yaml)
  library(fs)
  library(glue)
})

stop_pipeline <- function(msg) {
  stop(glue("❌ VALIDATION ERROR: {msg}"), call. = FALSE)
}

check_file <- function(path) {
  if (!file_exists(path)) stop_pipeline(glue("Archivo requerido NO encontrado: {path}"))
}

create_dir_safe <- function(path) {
  if (!dir_exists(path)) dir_create(path, recurse = TRUE)
}

check_file("config/paths.yml")
check_file("config/params.yml")

paths_cfg  <- yaml::read_yaml("config/paths.yml")
params_cfg <- yaml::read_yaml("config/params.yml")

if (is.null(params_cfg$dataset$gse) || params_cfg$dataset$gse == "") {
  stop_pipeline("dataset.gse no está definido en config/params.yml")
}
message(glue("✔ Dataset definido: {params_cfg$dataset$gse}"))

create_dir_safe(paths_cfg$data$raw)
create_dir_safe(paths_cfg$data$meta)
create_dir_safe(paths_cfg$data$processed)
create_dir_safe(paths_cfg$data$cache)

create_dir_safe(paths_cfg$results$qc)
create_dir_safe(paths_cfg$results$de)
create_dir_safe(paths_cfg$results$go)
create_dir_safe(paths_cfg$results$figures)
create_dir_safe(paths_cfg$results$tables)

create_dir_safe(paths_cfg$logs)
create_dir_safe(paths_cfg$annexes)
create_dir_safe(paths_cfg$docs)

message("✅ VALIDACIÓN COMPLETA: estructura y configuración correctas")
