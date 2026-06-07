# ============================================================
# scripts/export_session_info.R
# Exporta información del entorno para reproducibilidad
# ============================================================

suppressPackageStartupMessages({
  library(fs)
  library(yaml)
  library(glue)
})

PATHS <- yaml::read_yaml('config/paths.yml')
dir_create(PATHS$logs, recurse = TRUE)

stamp <- format(Sys.time(), '%Y%m%d_%H%M%S')
out <- file.path(PATHS$logs, paste0('sessionInfo_', stamp, '.txt'))

zz <- file(out, open = 'wt')
sink(zz)
cat('TFM_ERC_transcriptomica - sessionInfo\n')
cat('Timestamp: ', stamp, '\n\n', sep='')
cat('R.version:\n')
print(R.version)
cat('\nPlatform:\n')
cat(R.version$platform, '\n')
cat('\nSession info:\n')
print(sessionInfo())
sink()
close(zz)

cat('✅ sessionInfo guardado en: ', out, '\n', sep='')
