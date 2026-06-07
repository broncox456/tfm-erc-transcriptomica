# scripts/12_get_bibliography_pubmed.R
suppressPackageStartupMessages({
  library(rentrez)
})

dir.create('docs', showWarnings = FALSE, recursive = TRUE)

# Query PubMed (CKD / ERC) - últimos 5 años
query <- paste0(
  '(',
  '"chronic kidney disease"[Title/Abstract] OR CKD[Title/Abstract] OR ',
  '"diabetic kidney disease"[Title/Abstract] OR ',
  '"kidney fibrosis"[Title/Abstract]',
  ') AND (nephrology[Title/Abstract] OR kidney[Title/Abstract])'
)

year_from <- as.integer(format(Sys.Date(), '%Y')) - 5
year_to   <- as.integer(format(Sys.Date(), '%Y'))
full_query <- paste0(query, ' AND (', year_from, ':', year_to, '[dp])')

cat('🔎 PubMed query:\n', full_query, '\n\n')

# Buscar 50 más recientes
res <- entrez_search(db = 'pubmed', term = full_query, retmax = 50, sort = 'pub+date')
if (length(res$ids) == 0) stop('No se encontraron resultados en PubMed. Ajusta query.', call. = FALSE)

# Guardar PMIDs (trazabilidad)
pmid_path <- 'docs/PMIDs_50.txt'
writeLines(res$ids, pmid_path)
cat('✅ Guardado PMIDs en: ', pmid_path, '\n', sep = '')

# Descargar citas en MEDLINE
med <- entrez_fetch(db = 'pubmed', id = res$ids, rettype = 'medline', retmode = 'text')
out <- 'docs/pubmed_50.medline.txt'
writeLines(med, out)
cat('✅ Guardado MEDLINE en: ', out, '\n', sep = '')

cat('\n📌 Export APA 7 (UAX) recomendado:\n')
cat('1) Importa docs/pubmed_50.medline.txt en Zotero/Mendeley\n')
cat('2) Exporta en APA 7\n')

