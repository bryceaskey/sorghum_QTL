rm(list = ls())

library(qtl)
library(ASMap)
library(abind)

#set working directory
if(getwd() != "/home/schnable/Documents/R/QTL_Practice"){
  setwd("/home/schnable/Documents/R/QTL_Practice")
}

#read data from .csv file
all_sorghum_data <- read.cross(format = "csv", file = "all_pheno.csv", na.strings="-", genotypes = c("AA", "BB"), alleles = c("A", "B"), crosstype = "riself")

#subset RILs --------------------------------------------------------------------------------------

#create genetic map with a subset of individuals from sorghum_data
#add individuals back to cross once map has been created



#genotype data checking ---------------------------------------------------------------------------

#segregation distortion
#identify markers with extreme deviation from expected 1:1 (AA:BB) ratio
#gt <- geno.table(sorghum_data)
#distorted <- gt[gt$P.value < 1e-07, ]

#similar genotypes
#identify individuals with extremely similar (> 95%) genotype data 
#cg <- comparegeno(sorghum_data)
#similar <- which(cg > 0.95, arr.ind=TRUE)

#pairwise recombination fractions
#identify any linked markers that are on separate chromosomes
#sorghum_data <- est.rf(sorghum_data)
#checkAlleles(sorghum_data)

#don't need to evaluate marker order - mstmap accounts for misordered markers if anchor=FALSE

#jitter markers
#several markers mapped to same location - use jitter to separate
all_sorghum_data <- jittermap(all_sorghum_data)
sorghum_data <- subsetCross(all_sorghum_data, ind=1:393)
#remove individuals if missing allele data at >50% of markers
#sg <- statGen(sorghum_data, bychr=FALSE, stat.type="miss", id="id")
#sorghum_data <- subset(sorghum_data, ind=sg$miss < sum(nmar(sorghum_data))/2)

pp <- pp.init(miss.thresh=0.3, seg.thresh="bonf")
sorghum_data <- pullCross(sorghum_data, type="missing", pars=pp)
#sorghum_data <- pullCross(sorghum_data, type="seg.distortion", pars=pp)
sorghum_data <- pullCross(sorghum_data, type="co.located")

#genetic map construction -------------------------------------------------------------------------
as.map <- mstmap(sorghum_data, id="id", bychr=FALSE, trace=TRUE, p.value=1e-18, detectBadData=TRUE)
as.map <- jittermap(as.map)

pg <- profileGen(as.map, bychr=FALSE, stat.type=c("xo", "dxo", "miss"), id="id", xo.lambda=14, layout=c(1, 3), lty=2)
as.map <- subsetCross(as.map, ind=!pg$xo.lambda)
as.map <- mstmap(as.map, bychr=FALSE, trace=TRUE, id="id", p.value=1e-18, detectBadData=TRUE)

profileMark(as.map, stat.type=c("seg.dist", "prop", "dxo", "recomb"), layout=c(1,5), type="l")

pp <- pp.init(miss.thresh=0.7, max.rf=0.3)
as.map <- pushCross(sorghum_data, type="missing", pars=pp)
as.map <- mstmap(as.map, bychr=TRUE, trace=TRUE, id="id", p.value=2, detectBadData=TRUE)

as.map <- mstmap(as.map, bychr=TRUE, trace=TRUE, id="id", p.value=2)

for(i in 1:6){
  as.map <- movemarker(as.map, find.marker(as.map, 1, index=1), 6)
}

as.map <- movemarker(as.map, find.marker(as.map, 1, index=48), 5)
as.map <- movemarker(as.map, find.marker(as.map, 1, index=47), 9)

as.map <- mstmap(as.map, bychr=TRUE, trace=TRUE, id="id", p.value=2)

#genetic map evaluation ---------------------------------------------------------------------------
#compare genetic distance to physical distance with spearman correlation coeff
par(mfrow=c(3, 4))
corr <- array(data=NA, dim=nchr(as.map))
for(i in 1:nchr(as.map)){
  chr_data <- data.frame(gene_dist=(as.map$geno[[i]]$map))
  dist_data <- array(data=NA, dim=c(nmar(as.map)[[i]], 2))
  for(j in 1:nmar(as.map)[[i]]){
    geno_dist <- chr_data[j, 1]
    phys_dist <- strtoi(sapply(strsplit(row.names(chr_data)[[j]], "_"), '[', 2))
    dist_data[j, 1] <- geno_dist
    dist_data[j, 2] <- phys_dist
  }
  x <- cor.test(x=dist_data[, 1], y=dist_data[, 2], method="spearman")
  plot(dist_data[, 1], dist_data[, 2], main=paste("Chromosome", i), xlab="Genetic dist (cM)", ylab="Physical dist (bp)")
  round_dec <- function(num, k) trimws(format(round(num, k), nsmall=k))
  text(x=0, y=5e06, labels=paste("Spearman r^2 =", round_dec(x$estimate, 5)), adj=c(0, NA))
  corr[i] <- x$estimate
}
spearman_coeffs <- data.frame(spearman_coeff = corr)

#manually change marker positions in .csv file
map <- pull.map(as.map)
sorghum.csv <- read.csv(file="/home/schnable/Documents/R/QTL_Practice/all_pheno.csv", header=TRUE, sep=",", stringsAsFactors = FALSE)
new.sorghum.csv <- data.frame(sorghum.csv[ , 1], sorghum.csv[ , 2], sorghum.csv[ , 3], sorghum.csv[ , 4], sorghum.csv[ , 5], sorghum.csv[ , 6])
names(new.sorghum.csv) <- names(sorghum.csv[ , 1:6])
for(i in 1:nchr(map)){
  for(j in 1:nmar(map)[[i]]){
    marker.name <- names(map[[i]][j])
    marker.pos <- map[[i]][[j]]
    marker.col <- sorghum.csv[ , grep(marker.name, names(sorghum.csv))]
    new.sorghum.csv$name <- marker.col
    names(new.sorghum.csv)[names(new.sorghum.csv) == "name"] <- marker.name
    new.sorghum.csv[2, ncol(new.sorghum.csv)] <- marker.pos
  }
}

write.csv(new.sorghum.csv, file="all_data_new_map.csv", row.names = FALSE)

