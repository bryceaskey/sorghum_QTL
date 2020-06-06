set.seed(400)

if(getwd() != "/lustre/work/schnablelab/braskey/sorghumQTL/v2/leafCount"){
  setwd("/lustre/work/schnablelab/braskey/sorghumQTL/v2/leafCount")
}

library(qtl)

sorghum_data <- read.cross(format="csv", file="/lustre/work/schnablelab/braskey/sorghumQTL/v2/newSorghumData.csv", na.strings="NA", genotype=c("AA", "BB"), alleles=c("A", "B"), crosstype="riself")
sorghum_data <- sim.geno(sorghum_data, step=10, n.draws=256, error.prob = 0.001)
leafCountPerm4 <- scantwo(sorghum_data, pheno.col=3, method="imp", n.perm=200)

save(leafCountPerm4, file="leafCountPerm4.RData")