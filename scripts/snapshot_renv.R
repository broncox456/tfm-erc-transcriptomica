# ============================================================
# scripts/snapshot_renv.R
# Genera/actualiza renv.lock para reproducibilidad
# ============================================================

suppressPackageStartupMessages({
  library(renv)
})

cat('📌 renv::status() antes de snapshot\n')
print(renv::status())

cat('\n📌 Generando snapshot (renv.lock)...\n')
renv::snapshot(prompt = FALSE)

cat('\n✅ Snapshot completado. renv.lock actualizado.\n')
cat('📌 renv::status() después de snapshot\n')
print(renv::status())
