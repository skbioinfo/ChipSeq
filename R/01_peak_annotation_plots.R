suppressPackageStartupMessages({
  library(ChIPseeker)
  library(TxDb.Hsapiens.UCSC.hg19.knownGene)
  library(org.Hs.eg.db)
  library(rtracklayer)
})

txdb <- TxDb.Hsapiens.UCSC.hg19.knownGene
outdir <- "results/plots"
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

peaks <- rtracklayer::import("results/peaks/macs2/YOUR_SAMPLE/YOUR_SAMPLE_peaks.narrowPeak")

anno <- annotatePeak(peaks, tssRegion = c(-3000, 3000), TxDb = txdb, annoDb = "org.Hs.eg.db")

pdf(file.path(outdir, "peak_annotation_pie.pdf"), 7, 6); plotAnnoPie(anno); dev.off()
pdf(file.path(outdir, "peak_annotation_upset.pdf"), 9, 6); upsetplot(anno); dev.off()
pdf(file.path(outdir, "dist_to_tss.pdf"), 7, 5); plotDistToTSS(anno); dev.off()

write.csv(as.data.frame(anno), file.path(outdir, "peak_annotation_table.csv"), row.names = FALSE)

