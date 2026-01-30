suppressPackageStartupMessages({
  library(clusterProfiler)
  library(org.Hs.eg.db)
  library(enrichplot)
  library(ChIPseeker)
  library(TxDb.Hsapiens.UCSC.hg19.knownGene)
  library(rtracklayer)
  library(ggplot2)
})

txdb <- TxDb.Hsapiens.UCSC.hg19.knownGene
outdir <- "results/plots"
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

peaks <- rtracklayer::import("results/peaks/macs2/YOUR_SAMPLE/YOUR_SAMPLE_peaks.narrowPeak")
anno <- annotatePeak(peaks, tssRegion = c(-3000, 3000), TxDb = txdb, annoDb = "org.Hs.eg.db")

genes <- unique(as.data.frame(anno)$geneId)
genes <- genes[!is.na(genes)]

ego <- enrichGO(gene = genes, OrgDb = org.Hs.eg.db, keyType = "ENTREZID",
                ont = "BP", pAdjustMethod = "BH", pvalueCutoff = 0.05, readable = TRUE)

write.csv(as.data.frame(ego), file.path(outdir, "GO_BP.csv"), row.names = FALSE)

pdf(file.path(outdir, "GO_BP_dotplot.pdf"), 9, 6)
print(dotplot(ego, showCategory = 20) + ggtitle("GO BP enrichment"))
dev.off()

