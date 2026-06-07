# ============================================================
# TFM_ERC_transcriptomica
# Script: R/02_metadata.R (FINAL)
# Dataset: GSE12682 (GPL571)
# Objetivo:
#   - Construir sample_sheet.tsv con grupos defendibles:
#       CKD  = diseased (tubulointerstitial diseased kidney)
#       Control = healthy/normal/donor/reference/etc.
# ============================================================

suppressPackageStartupMessages({
  library(yaml)
  library(data.table)
  library(stringr)
  library(glue)
})

stop_pipeline <- function(msg) stop(glue('❌ METADATA ERROR: {msg}'), call. = FALSE)
now_stamp <- function() format(Sys.time(), '%Y%m%d_%H%M')

clean <- function(x) {
  x <- tolower(as.character(x))
  x[is.na(x)] <- ''
  x <- str_replace_all(x, '[[:punct:]]', ' ')
  str_squish(x)
}

# Detector FINAL: usa términos reales observados en el estudio
detect_group <- function(text_blob) {
  x <- clean(text_blob)

  # Evitar falsos positivos típicos
  x <- str_replace_all(x, 'quality control', '')
  x <- str_squish(x)

  # CASO / ENFERMO: el estudio usa 'diseased'
  # (se mapea a CKD para mantener coherencia con el TFM)
  if (str_detect(x, '\\bdiseased\\b')) return('CKD')

  # CONTROL real
  if (str_detect(x, '\\b(healthy|normal|reference)\\b') ||
      str_detect(x, 'control subject|normal kidney|healthy kidney|living donor|donor|nephrectomy|unused|pre implantation|preimplantation')) {
    return('Control')
  }

  # Fallback enfermedad renal (si apareciera explícito)
  if (str_detect(x, 'ckd|chronic kidney|renal failure|nephropathy|glomerulonephritis|fibrosis|tubulointerstitial')) return('CKD')

  return(NA_character_)
}

# 1) Config
PATHS  <- yaml::read_yaml('config/paths.yml')
PARAMS <- yaml::read_yaml('config/params.yml')
gse_id <- PARAMS$dataset$gse
if (is.null(gse_id) || gse_id == '') stop_pipeline('dataset.gse está vacío en config/params.yml')

meta_raw_path <- file.path(PATHS$data$meta, paste0(gse_id, '_geo_metadata_raw.tsv'))
if (!file.exists(meta_raw_path)) stop_pipeline(glue('No existe metadata cruda: {meta_raw_path}'))

meta <- fread(meta_raw_path)

# 2) Plataforma
platform_counts <- meta[, .N, by = ._platform][order(-N)]
print(platform_counts)
chosen_platform <- platform_counts[1, ._platform]
message(glue('✔ Plataforma seleccionada: {chosen_platform}'))
m <- meta[._platform == chosen_platform]

# 3) Columnas candidatas
char_cols  <- grep('^characteristics', names(m), value = TRUE)
other_cols <- intersect(c('title','source_name_ch1','description'), names(m))
cand_cols  <- unique(c(char_cols, other_cols))
if (length(cand_cols) == 0) stop_pipeline('No hay columnas candidatas para inferir grupo.')

# 4) Construir blob por muestra + clasificar
m[, blob := do.call(paste, c(lapply(.SD, function(z){
  z <- as.character(z); z[is.na(z)] <- ''; z
}), sep=' | ')), .SDcols = cand_cols]

m[, group := vapply(blob, detect_group, character(1))]

# 5) sample sheets
sample_all <- m[, .(
  sample_id = ._sample_id,
  platform  = ._platform,
  group     = group
)]

# Normalizar vacíos a NA (para auditoría correcta)
sample_all[group == '' , group := NA_character_]

out_all <- file.path(PATHS$data$meta, 'sample_sheet_all.tsv')
fwrite(sample_all, out_all, sep='\t')

sample <- sample_all[!is.na(group)]
out_path <- file.path(PATHS$data$meta, 'sample_sheet.tsv')
fwrite(sample, out_path, sep='\t')

message(glue('✅ sample_sheet creado: {out_path}'))
message('📊 Conteo por grupo:')
print(sample[, .N, by = group][order(-N)])
message(glue('📝 Auditoría completa (incluye NA): {out_all}'))

# 6) Validación mínima
n_ckd <- sample[group=='CKD', .N]; if (length(n_ckd)==0) n_ckd <- 0
n_ctl <- sample[group=='Control', .N]; if (length(n_ctl)==0) n_ctl <- 0
if (n_ckd < 10 || n_ctl < 10) {
  message(glue('⚠️ Aviso: tamaños bajos (CKD={n_ckd}, Control={n_ctl}).'))
} else {
  message(glue('✅ Tamaños OK para DE (CKD={n_ckd}, Control={n_ctl}).'))
}

# 7) Actualizar params.yml con backup
bk <- paste0('config/params.yml.bak_', now_stamp())
file.copy('config/params.yml', bk, overwrite = TRUE)
PARAMS$dataset$platform <- chosen_platform
PARAMS$analysis$contrast <- 'CKD_vs_Control'
yaml::write_yaml(PARAMS, 'config/params.yml')
message(glue('🧾 params.yml actualizado (backup: {bk})'))

message('✅ METADATA COMPLETA')
