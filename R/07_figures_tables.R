# ============================================================
# TFM_ERC_transcriptomica
# Script: R/07_figures_tables.R
# Propósito:
#   - Consolidar figuras/tablas finales para manuscrito UAX
#   - Sin re-calcular análisis: solo compila y resume outputs
# ============================================================

suppressPackageStartupMessages({
  library(yaml)
  library(fs)
  library(glue)
  library(data.table)
})

stop_pipeline <- function(msg) stop(glue('❌ FINAL PACK ERROR: {msg}'), call. = FALSE)

PATHS <- yaml::read_yaml('config/paths.yml')

dir_create(PATHS$results$tables, recurse = TRUE)
dir_create(PATHS$results$figures, recurse = TRUE)

# --------- 1) Tablas DE ---------
de_all <- file.path(PATHS$results$tables, 'DE_all_genes.tsv')
de_sig <- file.path(PATHS$results$tables, 'DE_significant_genes.tsv')
if (!file.exists(de_all)) stop_pipeline('Falta DE_all_genes.tsv (corre R/05_de.R)')

tt_all <- fread(de_all)
if (!all(c('gene','logFC','adj.P.Val','P.Value') %in% names(tt_all))) stop_pipeline('DE_all_genes.tsv no tiene columnas esperadas')

# Top20 global por adj.P.Val
top20 <- tt_all[order(adj.P.Val)][1:20]
fwrite(top20, file.path(PATHS$results$tables, 'TFM_Top20_DE.tsv'), sep='\t')

# Top20 UP y DOWN
top20_up <- tt_all[order(adj.P.Val)][logFC > 0][1:20]
top20_dn <- tt_all[order(adj.P.Val)][logFC < 0][1:20]
fwrite(top20_up, file.path(PATHS$results$tables, 'TFM_Top20_UP.tsv'), sep='\t')
fwrite(top20_dn, file.path(PATHS$results$tables, 'TFM_Top20_DOWN.tsv'), sep='\t')

# --------- 2) Tablas GO (BP) ---------
go_bp <- file.path(PATHS$results$enrichment, 'GO_BP.tsv')
if (!file.exists(go_bp)) stop_pipeline('Falta GO_BP.tsv (corre R/06_enrichment.R)')
go <- fread(go_bp)

# Top15 GO BP por p.adjust (si existe contenido)
if (nrow(go) > 0 && ('p.adjust' %in% names(go))) {
  go_top <- go[order(p.adjust)][1:min(15, .N)]
} else {
  go_top <- data.table()
}
fwrite(go_top, file.path(PATHS$results$tables, 'TFM_GO_BP_Top15.tsv'), sep='\t')

# --------- 3) QC summary ---------
# resumen simple: conteo muestras por grupo + n genes/probes
ss <- fread(file.path(PATHS$data$processed, 'sample_sheet_aligned.tsv'))
exprp <- readRDS(file.path(PATHS$data$processed, 'exprs_probes_norm.rds'))
exprg <- readRDS(file.path(PATHS$data$processed, 'exprs_genes_norm.rds'))

qc_sum <- data.table(
  metric = c('n_samples','n_probes','n_genes','n_control','n_ckd'),
  value  = c(
    nrow(ss),
    nrow(exprp),
    nrow(exprg),
    sum(ss$group=='Control'),
    sum(ss$group=='CKD')
  )
)
fwrite(qc_sum, file.path(PATHS$results$tables, 'TFM_QC_summary.tsv'), sep='\t')

# --------- 4) Figuras finales (copias renombradas) ---------
copy_safe <- function(from, to) {
  if (!file.exists(from)) stop_pipeline(glue('Falta figura: {from}'))
  file.copy(from, to, overwrite = TRUE)
}

copy_safe(file.path(PATHS$results$exploratory, 'pca_PC1_PC2.png'), file.path(PATHS$results$figures, 'TFM_PCA.png'))
copy_safe(file.path(PATHS$results$figures, 'volcano_CKD_vs_Control.png'), file.path(PATHS$results$figures, 'TFM_Volcano.png'))
copy_safe(file.path(PATHS$results$figures, 'heatmap_top30.png'), file.path(PATHS$results$figures, 'TFM_Heatmap_Top30.png'))
copy_safe(file.path(PATHS$results$figures, 'dotplot_GO_BP.png'), file.path(PATHS$results$figures, 'TFM_GO_BP_Dotplot.png'))

message('✅ PACK FINAL LISTO (tablas + figuras para manuscrito)')
