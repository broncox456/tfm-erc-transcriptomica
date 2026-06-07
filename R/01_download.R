# ============================================================
# TFM_ERC_transcriptomica
# Script: R/01_download.R
# Propósito: Descargar GSE desde GEO y guardar raw + metadata
# ============================================================

suppressPackageStartupMessages({
  library(yaml)
  library(fs)
  library(glue)
  library(GEOquery)
  library(data.table)
  library(Biobase)
})

PATHS  <- yaml::read_yaml('config/paths.yml')
PARAMS <- yaml::read_yaml('config/params.yml')

gse_id <- PARAMS$dataset$gse
if (is.null(gse_id) || gse_id == '') stop('dataset.gse está vacío en config/params.yml')

out_rds <- file.path(PATHS$data$raw, paste0(gse_id, '_GEO.rds'))
out_meta_tsv <- file.path(PATHS$data$meta, paste0(gse_id, '_geo_metadata_raw.tsv'))

dir_create(PATHS$data$raw, recurse = TRUE)
dir_create(PATHS$data$meta, recurse = TRUE)

message(glue('📥 Descargando {gse_id} desde GEO... (puede tardar unos minutos)'))

gse <- GEOquery::getGEO(gse_id, GSEMatrix = TRUE)

saveRDS(gse, out_rds)
message(glue('✅ Guardado objeto GEO: {out_rds}'))

extract_pd <- function(eset, platform_name) {
  pd <- as.data.frame(Biobase::pData(eset))
  pd$._platform <- platform_name
  pd$._sample_id <- rownames(pd)
  pd
}

meta_list <- list()

if (inherits(gse, 'ExpressionSet')) {
  meta_list[[1]] <- extract_pd(gse, platform_name = 'unknown')
} else {
  for (i in seq_along(gse)) {
    eset <- gse[[i]]
    gpl <- tryCatch(Biobase::annotation(eset), error = function(e) NA_character_)
    gpl <- ifelse(is.na(gpl) || gpl == '', paste0('platform_', i), gpl)
    meta_list[[i]] <- extract_pd(eset, platform_name = gpl)
  }
}

meta_raw <- data.table::rbindlist(meta_list, fill = TRUE)
data.table::fwrite(meta_raw, out_meta_tsv, sep='\t')

message(glue('✅ Guardada metadata cruda: {out_meta_tsv}'))
message('✅ DESCARGA COMPLETA')
