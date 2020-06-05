# Script to construct genetic map from genotype data for RIL population
library(qtl)
library(ASMap)
library(abind)

# Set working directory
setwd("C:/Users/Bryce/Documents/sorghum_QTL/QTL_mapping/")

# Load genotype data from Kong et al (2018)
genoData <- read.cross(format = "csv", file = "data/FIleS2_genotype.csv", na.strings="-", genotypes = c("AA", "BB"), alleles = c("A", "B"), crosstype = "riself")

# Genotype data checking ----

# Segregation distortion - identify markers with extreme deviation from expected 1:1 (AA:BB) ratio
#gt <- geno.table(genoData)
#distorted <- gt[gt$P.value < 1e-07, ]

# Similar genotypes - identify individuals with extremely similar (> 95%) genotype data 
#cg <- comparegeno(genoData)
#similar <- which(cg > 0.95, arr.ind=TRUE)

# Pairwise recombination fractions - identify any linked markers that are on separate chromosomes
#genoData <- est.rf(genoData)
#checkAlleles(genoData)

# Don't need to evaluate marker order - mstmap accounts for misordered markers if anchor=FALSE

# Jitter markers mapped to same location
genoData <- jittermap(genoData)

# Pull missing and co-located markers from genoData (parameter need to first be initialized with pp.init)
pp <- pp.init(miss.thresh=0.3, seg.thresh="bonf")
genoData <- pullCross(genoData, type="missing", pars=pp)
genoData <- pullCross(genoData, type="co.located")

# Construct genetic map ----
as.map <- mstmap(genoData, id="id", bychr=FALSE, trace=TRUE, p.value=1e-18, detectBadData=TRUE)
as.map <- jittermap(as.map)

pg <- profileGen(as.map, bychr=FALSE, stat.type=c("xo", "dxo", "miss"), id="id", xo.lambda=14, layout=c(1, 3), lty=2)
as.map <- subsetCross(as.map, ind=!pg$xo.lambda)
as.map <- mstmap(as.map, bychr=FALSE, trace=TRUE, id="id", p.value=1e-18, detectBadData=TRUE)

profileMark(as.map, stat.type=c("seg.dist", "prop", "dxo", "recomb"), layout=c(1,5), type="l")

pp <- pp.init(miss.thresh=0.7, max.rf=0.3)
as.map <- pushCross(genoData, type="missing", pars=pp)
as.map <- mstmap(as.map, bychr=TRUE, trace=TRUE, id="id", p.value=2, detectBadData=TRUE)

as.map <- mstmap(as.map, bychr=TRUE, trace=TRUE, id="id", p.value=2)

for(i in 1:6){
  as.map <- movemarker(as.map, find.marker(as.map, 1, index=1), 6)
}

as.map <- movemarker(as.map, find.marker(as.map, 1, index=48), 5)
as.map <- movemarker(as.map, find.marker(as.map, 1, index=47), 9)

as.map <- mstmap(as.map, bychr=TRUE, trace=TRUE, id="id", p.value=2)

# Evalute accuracy of genetic map ----
# Compare genetic distance to physical distance with spearman correlation coeff, and create plot to check mapping results
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

# Save genotype data with remapped markers ----
# Load marker positions from genotype file with old map, and save new file with remapped markers
map <- pull.map(as.map)
genoData_oldMap <- read.csv(file="data/FIleS2_genotype.csv", header=TRUE, sep=",", stringsAsFactors = FALSE)
genoData_newMap <- data.frame(id=genoData_oldMap[ , 1])
for(i in 1:nchr(map)){
  for(j in 1:nmar(map)[[i]]){
    marker.name <- names(map[[i]][j])
    marker.pos <- map[[i]][[j]]
    marker.col <- genoData_oldMap[ , grep(marker.name, names(genoData_oldMap))]
    genoData_newMap$name <- marker.col
    names(genoData_newMap)[names(genoData_newMap) == "name"] <- marker.name
    genoData_newMap[2, ncol(genoData_newMap)] <- marker.pos
  }
}

write.csv(genoData_newMap, file="data/FIleS2_genotype_remapped.csv", row.names = FALSE)