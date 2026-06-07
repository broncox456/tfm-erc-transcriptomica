# scripts/12_bibliografia_APA_desde_PubMed.R
suppressPackageStartupMessages({
  if (!requireNamespace('rentrez', quietly=TRUE)) install.packages('rentrez')
  library(rentrez)
})

dir.create('docs', showWarnings=FALSE, recursive=TRUE)

# ---- 1) Query PubMed (ajustable) ----
query_core <- paste0(
  '(',
  '"chronic kidney disease"[Title/Abstract] OR CKD[Title/Abstract] OR ',
  '"diabetic kidney disease"[Title/Abstract] OR ',
  '"kidney fibrosis"[Title/Abstract] OR ',
  '"tubulointerstitial"[Title/Abstract]',
  ') AND (nephrology[Title/Abstract] OR kidney[Title/Abstract])'
)

# ---- 2) Filtro temporal: últimos 5 años ----
year_from <- as.integer(format(Sys.Date(), '%Y')) - 5
year_to   <- as.integer(format(Sys.Date(), '%Y'))
full_query <- paste0(query_core, ' AND (', year_from, ':', year_to, '[dp])')

cat('🔎 PubMed query:\n', full_query, '\n\n')

# ---- 3) Buscar 50 más recientes ----
res <- entrez_search(db='pubmed', term=full_query, retmax=50, sort='pub+date')
if (length(res$ids)==0) stop('No se encontraron resultados en PubMed con este query.', call.=FALSE)

# Guardar PMIDs (trazabilidad)
pmid_path <- 'docs/PMIDs_50.txt'
writeLines(res$ids, pmid_path)
cat('✅ PMIDs guardados en: ', pmid_path, '\n', sep='')

# ---- 4) Descargar MEDLINE ----
med <- entrez_fetch(db='pubmed', id=res$ids, rettype='medline', retmode='text')
med_path <- 'docs/pubmed_50.medline.txt'
writeLines(med, med_path)
cat('✅ MEDLINE guardado en: ', med_path, '\n', sep='')

# ---- 5) Parsear MEDLINE a APA (simple, robusto) ----
lines <- readLines(med_path, warn=FALSE)

# Separar registros por PMID-
starts <- which(grepl('^PMID- ', lines))
ends <- c(starts[-1]-1, length(lines))

get_field <- function(block, tag){
  idx <- which(grepl(paste0('^', tag, '- '), block))
  if (length(idx)==0) return(character(0))
  val <- sub(paste0('^', tag, '- '), '', block[idx])
  # Continuations (lineas con 6 espacios en MEDLINE)
  for (k in seq_along(idx)) {
    i <- idx[k]
    j <- i + 1
    while (j <= length(block) && grepl('^      ', block[j])) {
      val[k] <- paste(val[k], trimws(block[j]))
      j <- j + 1
    }
  }
  val
}

format_authors_apa <- function(au_vec){
  # AU viene como 'Apellido Iniciales'
  if (length(au_vec)==0) return('')
  # Convertir: 'Smith JH' -> 'Smith, J. H.'
  conv <- function(x){
    x <- trimws(x)
    parts <- strsplit(x, ' ', fixed=TRUE)[[1]]
    last <- parts[1]
    ini  <- paste(parts[-1], collapse='')
    # insertar puntos entre iniciales
    ini <- gsub('([A-Z])', '\\1.', ini)
    ini <- gsub('.\.', '.', ini)
    paste0(last, ', ', trimws(ini))
  }
  au <- vapply(au_vec, conv, character(1))
  if (length(au) <= 20) {
    paste(au, collapse=', ')
  } else {
    paste(paste(au[1:19], collapse=', '), ', …, ', au[length(au)], sep='')
  }
}

pick_year <- function(dp){
  # DP suele ser '2024 Mar 12' o '2023'
  if (length(dp)==0) return('n.d.')
  m <- regmatches(dp[1], regexpr('^[0-9]{4}', dp[1]))
  ifelse(nchar(m)==4, m, 'n.d.')
}

clean_title <- function(ti){
  if (length(ti)==0) return('')
  x <- ti[1]
  x <- gsub('\\s+', ' ', x)
  x <- trimws(x)
  # Asegurar punto final
  if (!grepl('[.\\?\\!]$', x)) x <- paste0(x, '.')
  x
}

format_journal <- function(jt){
  if (length(jt)==0) return('')
  x <- jt[1]
  x <- gsub('\\s+', ' ', x)
  trimws(x)
}

format_vol_issue_pages <- function(vi, ip, pg){
  v <- ifelse(length(vi)>0, vi[1], '')
  i <- ifelse(length(ip)>0, ip[1], '')
  p <- ifelse(length(pg)>0, pg[1], '')
  out <- ''
  if (nzchar(v) && nzchar(i)) out <- paste0(v, '(', i, ')')
  if (nzchar(v) && !nzchar(i)) out <- v
  if (!nzchar(v) && nzchar(i)) out <- paste0('(', i, ')')
  if (nzchar(out) && nzchar(p)) out <- paste0(out, ', ', p)
  if (!nzchar(out) && nzchar(p)) out <- p
  out
}

get_doi <- function(block){
  # DOI suele estar en LID- ... [doi]
  lid <- get_field(block, 'LID')
  if (length(lid)==0) return('')
  doi_line <- lid[grepl('\\[doi\\]$', lid)]
  if (length(doi_line)==0) return('')
  # extraer antes del espacio
  sub('\\s+\\[doi\\]$', '', doi_line[1])
}

entries <- character(0)
for (k in seq_along(starts)){
  block <- lines[starts[k]:ends[k]]
  au <- get_field(block, 'AU')
  dp <- get_field(block, 'DP')
  ti <- get_field(block, 'TI')
  jt <- get_field(block, 'JT')
  vi <- get_field(block, 'VI')
  ip <- get_field(block, 'IP')
  pg <- get_field(block, 'PG')
  pm <- sub('^PMID- ', '', get_field(block, 'PMID')[1])
  doi <- get_doi(block)

  authors <- format_authors_apa(au)
  year <- pick_year(dp)
  title <- clean_title(ti)
  journal <- format_journal(jt)
  vip <- format_vol_issue_pages(vi, ip, pg)

  # APA (base): Autores. (Año). Título. Revista, Volumen(Issue), páginas. DOI
  apa <- paste0(
    authors, ' (', year, '). ',
    title, ' ',
    ifelse(nzchar(journal), paste0(journal, ', '), ''),
    vip,
    ifelse(nzchar(vip) && !grepl('[.]$', vip), '.', ''),
    ifelse(nzchar(doi), paste0(' https://doi.org/', doi), ''),
    ifelse(!nzchar(doi), paste0(' PMID: ', pm), '')
  )

  entries <- c(entries, apa)
}

# ---- 6) Guardar bibliografía APA UAX + nota metodológica ----
out_path <- 'docs/bibliografia_APA_UAX.txt'
header <- c(
  'BIBLIOGRAFÍA (APA) — Generada automáticamente desde PubMed (NCBI)',
  paste0('Fecha de extracción: ', format(Sys.Date(), '%Y-%m-%d')),
  paste0('Criterio temporal: últimos 5 años (', year_from, '–', year_to, ')'),
  'Fuente: PubMed / NCBI Entrez (consulta reproducible mediante rentrez).',
  paste0('Query PubMed usada: ', full_query),
  '',
  'REFERENCIAS:',
  ''
)

writeLines(c(header, paste0(seq_along(entries), '. ', entries)), out_path)
cat('✅ Bibliografía APA guardada en: ', out_path, '\n', sep='')
cat('✅ Recuerda: trazabilidad completa en docs/PMIDs_50.txt y docs/pubmed_50.medline.txt\n')

