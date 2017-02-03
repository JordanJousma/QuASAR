#processing
#DNA library 
#summed replicate counts
#require ref+alt counts >100 
#require 5 counts each ref and alt
#DNA_prop = ref/(ref+alt)
#RNA library
#require being in DNA library
#require 5 counts each ref and alt

library(data.table)

## ftp://ftp.ncbi.nlm.nih.gov/geo/series/GSE75nnn/GSE75661/suppl/GSE75661_79k_collapsed_counts.txt.gz

MPRA_counts <- fread("curl 'ftp://ftp.ncbi.nlm.nih.gov/geo/series/GSE75nnn/GSE75661/suppl/GSE75661_79k_collapsed_counts.txt.gz' | zcat")

##transform(MPRA_counts, DNA = Plasmid_r1 + Plasmid_r2 + Plasmid_r3 + Plasmid_r4 + Plasmid_r5 )
##transform(MPRA_counts, RNA.HepG2 = HepG2_r1 + HepG2_r2 + HepG2_r3 + HepG2_r4 + HepG2_r5 )
##transform(MPRA_counts, RNA.NA12878 = NA12878_r1 + NA12878_r2 + NA12878_r3 + NA12878_r4 + NA12878_r5 )
##transform(MPRA_counts, RNA.NA19239 = NA19239_r1 + NA19239_r2 + NA19239_r3 + NA19239_r4 + NA19239_r5 )


## Preprocessing DNA
mpra <- MPRA_counts[,c(1:6)]
mpra <- transform(mpra, DNA=Plasmid_r1+Plasmid_r2+Plasmid_r3+Plasmid_r4+Plasmid_r5)
mpra$Oligo <- as.character(mpra$Oligo)
alt <- mpra[grep('alt', mpra$Oligo),]
RC <- mpra[ grep('RC', mpra$Oligo), ]

mpra_F <- subset(mpra, !(mpra$Oligo %in% RC$Oligo))
x <- strsplit(mpra_F$Oligo, "_")
mpra_F$rsID <- sapply(x, function(y) { y[1] })
mpra_F$Allele <- sapply(x, function(y) { y[2] })
R <- mpra_F[grep('A',mpra_F$Allele),]
mpra_F <- transform(mpra_F, Allele_class=ifelse(Oligo %in% R$Oligo, "R", "A"), alt_hap=ifelse(Oligo %in% alt$Oligo, "1", "0"))

x <- strsplit(RC$Oligo, "_")
RC$rsID <- sapply(x, function(y) { y[1] })
#mpra$Allele_class <- sapply(x, function(y) { y[2] })
RC$Allele <- sapply(x, function(y) { y[3] })
R <- RC[grep('A',RC$Allele),]
RC <- transform(RC, Allele_class=ifelse(Oligo %in% R$Oligo, "R", "A"),alt_hap=ifelse(Oligo %in% alt$Oligo, "1", "0"))

mpra_ref <- subset(mpra_F, alt_hap=="0")
RC_ref <- subset(RC, alt_hap=="0")
mpra_alt <- subset(mpra_F, alt_hap=="1")
RC_alt <- subset(RC, alt_hap=="1")
allele_count <- dcast(mpra_ref, rsID ~ Allele_class, value.var="DNA", sum)
allele_count_5 <- subset(allele_count,  R>= 5 & A>=5)
y_100 <- subset(allele_count_5, R+A>=100)
y_100 <- transform(y_100, DNA_prop=R/(A+R), logit_prop=log2(R/A))
mpra_ref_Filt <- merge(mpra_ref, y_100, by="rsID")

allele_count <- dcast(mpra_alt, rsID ~ Allele_class, value.var="DNA", sum)
allele_count_5 <- subset(allele_count,  R>= 5 & A>=5)
y_100 <- subset(allele_count_5, R+A>=100)
y_100 <- transform(y_100, DNA_prop=R/(A+R), logit_prop=log2(R/A))
mpra_alt_Filt <- merge(mpra_alt, y_100, by="rsID")
## 
dna_mpra_Filt <- rbind(mpra_ref_Filt, mpra_alt_Filt)

allele_count <- dcast(RC_ref, rsID ~ Allele_class, value.var="DNA", sum)
allele_count_5 <- subset(allele_count,  R>= 5 & A>=5)
y_100 <- subset(allele_count_5, R+A>=100)
y_100 <- transform(y_100, DNA_prop=R/(A+R), logit_prop=log2(R/A))
RC_ref_Filt <- merge(RC_ref, y_100, by="rsID")

allele_count <- dcast(RC_alt, rsID ~ Allele_class, value.var="DNA", sum)
allele_count_5 <- subset(allele_count,  R>= 5 & A>=5)
y_100 <- subset(allele_count_5, R+A>=100)
y_100 <- transform(y_100, DNA_prop=R/(A+R), logit_prop=log2(R/A))
RC_alt_Filt <- merge(RC_alt, y_100, by="rsID")
##
dna_RC_Filt <- rbind(RC_ref_Filt, RC_alt_Filt)

####



mpra <- MPRA_counts[,c(1,15:19)]
mpra <- transform(mpra, RNA=HepG2_r1+HepG2_r2+HepG2_r3+HepG2_r4+HepG2_r5)
##mpra$Oligo <- as.character(mpra$Oligo)
alt <- mpra[grep('alt', mpra$Oligo),]
RC <- mpra[ grep('RC', mpra$Oligo), ]
names(dna_mpra_Filt)[12] <- "DNA_A"
names(dna_mpra_Filt)[13] <- "DNA_R"
names(dna_RC_Filt)[12] <- "DNA_A"
names(dna_RC_Filt)[13] <- "DNA_R"
dna_RC_Filt <- dna_RC_Filt[,-c(3:7)]
dna_mpra_Filt <- dna_mpra_Filt[,-c(3:7)]
RC <- merge(RC,dna_RC_Filt, by="Oligo")
mpra_F <- subset(mpra, !(mpra$Oligo %in% RC$Oligo))
mpra_F <- merge(mpra_F,dna_mpra_Filt, by="Oligo")
mpra_F <- subset(mpra_F, !(mpra_F$Oligo %in% RC$Oligo))
x <- strsplit(mpra_F$Oligo, "_")
mpra_F$rsID <- sapply(x, function(y) { y[1] })
mpra_F$Allele <- sapply(x, function(y) { y[2] })
R <- mpra_F[grep('A',mpra_F$Allele),]
mpra_F <- transform(mpra_F, Allele_class=ifelse(Oligo %in% R$Oligo, "R", "A"), alt_hap=ifelse(Oligo %in% alt$Oligo, "1", "0"))

x <- strsplit(RC$Oligo, "_")
RC$rsID <- sapply(x, function(y) { y[1] })
#mpra$Allele_class <- sapply(x, function(y) { y[2] })
RC$Allele <- sapply(x, function(y) { y[3] })
R <- RC[grep('A',RC$Allele),]
RC <- transform(RC, Allele_class=ifelse(Oligo %in% R$Oligo, "R", "A"),alt_hap=ifelse(Oligo %in% alt$Oligo, "1", "0"))

mpra_ref <- subset(mpra_F, alt_hap=="0")
RC_ref <- subset(RC, alt_hap=="0")
mpra_alt <- subset(mpra_F, alt_hap=="1")
RC_alt <- subset(RC, alt_hap=="1")
allele_count <- dcast(mpra_ref, rsID ~ Allele_class, value.var="RNA", sum)
allele_count_5 <- subset(allele_count,  R>= 5 & A>=5)
mpra_ref_Filt <- merge(mpra_ref, allele_count_5, by="rsID")

allele_count <- dcast(mpra_alt, rsID ~ Allele_class, value.var="RNA", sum)
allele_count_5 <- subset(allele_count,  R>= 5 & A>=5)
mpra_alt_Filt <- merge(mpra_alt, allele_count_5, by="rsID")
mpra_Filt <- rbind(mpra_ref_Filt, mpra_alt_Filt)

allele_count <- dcast(RC_ref, rsID ~ Allele_class, value.var="RNA", sum)
allele_count_5 <- subset(allele_count,  R>= 5 & A>=5)
RC_ref_Filt <- merge(RC_ref, allele_count_5, by="rsID")

allele_count <- dcast(RC_alt, rsID ~ Allele_class, value.var="RNA", sum)
allele_count_5 <- subset(allele_count,  R>= 5 & A>=5)
RC_alt_Filt <- merge(RC_alt, allele_count_5, by="rsID")
RC_Filt <- rbind(RC_ref_Filt, RC_alt_Filt)
