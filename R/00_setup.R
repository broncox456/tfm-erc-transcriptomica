# ============================================================
# Script: R/00_setup.R
# Propósito: Cargar configs y preparar entorno
# ============================================================

suppressPackageStartupMessages({
  library(yaml)
  library(fs)
  library(glue)
})

PATHS  <- yaml::read_yaml("config/paths.yml")
PARAMS <- yaml::read_yaml("config/params.yml")

set.seed(PARAMS$project$seed %||% 123)

`%||%` <- function(a, b) if (!is.null(a)) a else b

# Crear carpetas (doble seguridad)
create_dir_safe <- function(path) {
  if (!fs::dir_exists(path)) fs::dir_create(path, recurse = TRUE)
}

create_dir_safe(PATHS$data$raw)
create_dir_safe(PATHS$data$meta)
create_dir_safe(PATHS$data$processed)
create_dir_safe(PATHS$data$cache)

create_dir_safe(PATHS$results$qc)
create_dir_safe(PATHS$results$de)
create_dir_safe(PATHS$results$go)
create_dir_safe(PATHS$results$figures)
create_dir_safe(PATHS$results$tables)

create_dir_safe(PATHS$logs)
create_dir_safe(PATHS$annexes)
create_dir_safe(PATHS$docs)

message(glue("OK: Setup cargado. Dataset: {PARAMS$dataset$gse}"))
