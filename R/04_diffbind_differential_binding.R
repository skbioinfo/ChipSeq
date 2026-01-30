suppressPackageStartupMessages({
  library(DiffBind)
  library(tidyverse)
  library(ggrepel)
})

# ---- edit paths ----
samplesheet_csv <- "results/diffbind_samplesheet.csv"
outdir <- "results/diffbind"
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

# Load DiffBind sample sheet
# Must have columns like:
# SampleID, Tissue, Factor, Condition, Replicate, bamReads, bamControl, Peaks, PeakCaller
dba_obj <- dba(sampleSheet = samplesheet_csv)

# Count reads in consensus peakset
dba_obj <- dba.count(dba_obj, summits = 250)  # 250bp around summit is common

# QC plots
pdf(file.path(outdir, "01_PCA.pdf"), width = 7, height = 6)
plot(dba.plotPCA(dba_obj, attributes = DBA_CONDITION, label = DBA_ID))
dev.off()

pdf(file.path(outdir, "02_Correlation_heatmap.pdf"), width = 8, height = 7)
plot(dba.plotHeatmap(dba_obj, correlations = TRUE))
dev.off()

# Differential analysis (DESeq2)
dba_obj <- dba.contrast(dba_obj, categories = DBA_CONDITION, minMembers = 2)
dba_obj <- dba.analyze(dba_obj, method = DBA_DESEQ2)

# MA plot
pdf(file.path(outdir, "03_MAplot.pdf"), width = 7, height = 6)
plot(dba.plotMA(dba_obj))
dev.off()

# Volcano plot (custom)
res <- dba.report(dba_obj, method = DBA_DESEQ2, th = 1) %>% as.data.frame()
res$log10FDR <- -log10(pmax(res$FDR, 1e-300))

# Add labels for top peaks
res <- res %>% mutate(rank_score = log10FDR * abs(Fold))
top_lab <- res %>% arrange(desc(rank_score)) %>% slice_head(n = 20)

p <- ggplot(res, aes(x = Fold, y = log10FDR)) +
  geom_point(alpha = 0.4, size = 1.3) +
  geom_vline(xintercept = c(-1, 1), linetype = 2) +
  geom_hline(yintercept = -log10(0.05), linetype = 2) +
  geom_text_repel(data = top_lab, aes(label = paste0(seqnames, ":", start, "-", end)),
                  size = 2.5, max.overlaps = Inf) +
  theme_minimal(base_size = 12) +
  labs(title = "Differential Binding Volcano (DiffBind)",
       x = "log2 Fold Change", y = "-log10(FDR)")

ggsave(file.path(outdir, "04_Volcano.pdf"), p, width = 7, height = 6)

# Heatmap of differential sites
pdf(file.path(outdir, "05_Differential_heatmap.pdf"), width = 9, height = 7)
plot(dba.plotHeatmap(dba_obj, contrast = 1, correlations = FALSE))
dev.off()

write.csv(res, file.path(outdir, "diffbind_results.csv"), row.names = FALSE)
message("Done: DiffBind results in ", outdir)

