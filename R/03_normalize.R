# ============================================================
# TFM_ERC_transcriptomica
# Script: R/03_normalize.R
# Dataset: GSE12682 (GPL571)
# Propósito:
#   - Cargar ExpressionSet (GEO)
#   - Normalizar (limma quantile)
#   - Exportar matrices: probes (normalizada) y genes (por SYMBOL)
# ============================================================

suppressPackageStartupMessages({
  library(yaml)
  library(fs)
  library(glue)
  library(data.table)
  library(stringr)
  library(Biobase)
  library(limma)
  library(AnnotationDbi)
  library(hgu133a2.db)
})

stop_pipeline <- function(msg) stop(glue('❌ NORMALIZE ERROR: {msg}'), call. = FALSE)

# 1) Config
PATHS  <- yaml::read_yaml('config/paths.yml')
PARAMS <- yaml::read_yaml('config/params.yml')

gse_id <- PARAMS$dataset$gse
plat   <- PARAMS$dataset$platform
if (is.null(gse_id) || gse_id=='') stop_pipeline('dataset.gse vacío en params.yml')
if (is.null(plat)   || plat=='')   stop_pipeline('dataset.platform vacío en params.yml (corre R/02_metadata.R)')

raw_rds <- file.path(PATHS$data$raw, paste0(gse_id, '_GEO.rds'))
if (!file.exists(raw_rds)) stop_pipeline(glue('No existe: {raw_rds} (corre R/01_download.R)'))

dir_create(PATHS$data$processed, recurse = TRUE)

# 2) Cargar GEO object y extraer ExpressionSet de la plataforma seleccionada
gse_obj <- readRDS(raw_rds)

eset <- NULL
if (inherits(gse_obj, 'ExpressionSet')) {
  eset <- gse_obj
} else if (is.list(gse_obj)) {
  # intentar seleccionar el ESet correcto por annotation() == GPLxxx
  ann <- vapply(gse_obj, function(x) {
    a <- tryCatch(Biobase::annotation(x), error = function(e) NA_character_)
    if (is.na(a) || a=='') NA_character_ else a
  }, character(1))

  idx <- which(ann == plat)
  if (length(idx) == 0) {
    # fallback: si no matchea, tomar el primero
    message('⚠️ No se encontró match exacto por annotation(). Se usará el primer ExpressionSet.')
    idx <- 1
  }
  eset <- gse_obj[[idx[1]]]
} else {
  stop_pipeline('Objeto GEO no reconocido (no ExpressionSet ni lista).')
}

message(glue('✔ ExpressionSet cargado. Platform (annotation): {Biobase::annotation(eset)}'))

# 3) Cargar sample_sheet y alinear columnas
sample_sheet <- data.table::fread(file.path(PATHS$data$meta, 'sample_sheet.tsv'))
if (!all(c('sample_id','group') %in% names(sample_sheet))) stop_pipeline('sample_sheet.tsv debe tener sample_id y group')

expr <- Biobase::exprs(eset)

# mantener solo muestras presentes en exprs
keep_ids <- intersect(colnames(expr), sample_sheet$sample_id)
if (length(keep_ids) < 10) stop_pipeline('Muy pocas muestras coinciden entre exprs y sample_sheet.tsv')

expr <- expr[, keep_ids, drop = FALSE]
sample_sheet <- sample_sheet[sample_id %in% keep_ids]

# reordenar sample_sheet al orden de columnas
setkey(sample_sheet, sample_id)
sample_sheet <- sample_sheet[colnames(expr)]
stopifnot(all(sample_sheet$sample_id == colnames(expr)))

message(glue('✔ Matriz exprs: {nrow(expr)} probes x {ncol(expr)} muestras'))

# 4) Heurística: asegurar escala log2 si viniera en escala lineal
maxv <- max(expr, na.rm = TRUE)
if (maxv > 100) {
  message('⚠️ Valores altos detectados (max>100). Aplicando log2(x+1) antes de normalizar.')
  expr <- log2(expr + 1)
} else {
  message('✔ Escala compatible con log2 (no se aplica transformación).')
}

# 5) Normalización cuantílica (limma) sobre probes
expr_norm <- limma::normalizeBetweenArrays(expr, method = 'quantile')

# 6) Guardar matriz normalizada (probes)
out_probe_rds <- file.path(PATHS$data$processed, 'exprs_probes_norm.rds')
saveRDS(expr_norm, out_probe_rds)
message(glue('✅ Guardado: {out_probe_rds}'))

# 7) Anotar probes -> gene SYMBOL y colapsar a nivel gen (mediana por gen)
probe_ids <- rownames(expr_norm)

annot <- AnnotationDbi::select(
  hgu133a2.db,
  keys = probe_ids,
  columns = c('SYMBOL','ENTREZID'),
  keytype = 'PROBEID'
)

# limpiar
annot <- as.data.table(annot)
annot <- unique(annot)
annot <- annot[!is.na(SYMBOL) & SYMBOL != '']

# unir exprs con SYMBOL
expr_dt <- as.data.table(expr_norm, keep.rownames = 'PROBEID')
expr_annot <- merge(annot[, .(PROBEID, SYMBOL)], expr_dt, by = 'PROBEID', all.x = TRUE)
expr_annot <- expr_annot[!is.na(SYMBOL)]

# colapsar por SYMBOL (mediana por muestra)
cols_samples <- setdiff(names(expr_annot), c('PROBEID','SYMBOL'))
expr_gene <- expr_annot[, lapply(.SD, median, na.rm = TRUE), by = SYMBOL, .SDcols = cols_samples]

# convertir a matrix
expr_gene_mat <- as.matrix(expr_gene[, ..cols_samples])
rownames(expr_gene_mat) <- expr_gene$SYMBOL

out_gene_rds <- file.path(PATHS$data$processed, 'exprs_genes_norm.rds')
saveRDS(expr_gene_mat, out_gene_rds)
message(glue('✅ Guardado: {out_gene_rds}'))

# 8) Guardar sample_sheet alineado (por si luego se modifica)
out_ss <- file.path(PATHS$data$processed, 'sample_sheet_aligned.tsv')
fwrite(sample_sheet, out_ss, sep='\t')
message(glue('✅ Guardado: {out_ss}'))

message('✅ NORMALIZACIÓN COMPLETA')
