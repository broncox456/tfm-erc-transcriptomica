# ============================================================
# scripts/run_pipeline.R (ROBUSTO)
# Ejecuta pipeline completo + exporta sessionInfo + snapshot renv
# Log seguro: sink + conexión con cleanup garantizado
# ============================================================

suppressPackageStartupMessages({
  library(yaml)
  library(fs)
  library(glue)
})

PATHS <- yaml::read_yaml('config/paths.yml')
dir_create(PATHS$logs, recurse = TRUE)

stamp <- format(Sys.time(), '%Y%m%d_%H%M%S')
logfile <- file.path(PATHS$logs, paste0('pipeline_', stamp, '.log'))

# Abrir conexión de log
zz <- file(logfile, open = 'wt')

# Cleanup SIEMPRE (aunque falle algo)
on.exit({
  # cerrar sinks de message/output si están activos
  while (sink.number(type = 'message') > 0) sink(NULL, type = 'message')
  while (sink.number(type = 'output')  > 0) sink(NULL, type = 'output')

  # cerrar conexión si sigue válida
  try(if (isOpen(zz)) close(zz), silent = TRUE)
}, add = TRUE)

# Activar sinks
sink(zz, type = 'output')
sink(zz, type = 'message')

cat('TFM_ERC_transcriptomica - RUN PIPELINE\n')
cat('Timestamp: ', stamp, '\n', sep = '')
cat('Workdir: ', getwd(), '\n\n', sep = '')

# Ejecutar en orden con control de error
run_step <- function(path) {
  cat('\n--- RUN: ', path, ' ---\n', sep='')
  source(path, local = new.env(parent = globalenv()))
  cat('--- OK: ', path, ' ---\n', sep='')
}

tryCatch({
  run_step('scripts/01_validate.R')
  run_step('scripts/00_install.R')

  run_step('R/01_download.R')
  run_step('R/02_metadata.R')
  run_step('R/03_normalize.R')
  run_step('R/04_qc.R')
  run_step('R/05_de.R')
  run_step('R/06_enrichment.R')
  run_step('R/07_figures_tables.R')

  run_step('scripts/export_session_info.R')
  run_step('scripts/snapshot_renv.R')

  cat('\n✅ PIPELINE COMPLETO\n')
}, error = function(e) {
  cat('\n❌ PIPELINE FALLÓ: ', conditionMessage(e), '\n', sep='')
  stop(e)
})

# salir a consola (los sinks se cierran por on.exit)
cat('\n✅ Log guardado en: ', logfile, '\n', sep='')
