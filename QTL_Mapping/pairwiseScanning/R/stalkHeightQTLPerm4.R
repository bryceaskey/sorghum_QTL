set.seed(400)

if(getwd() != "/lustre/work/schnablelab/braskey/sorghumQTL/v2/stalkHeight"){
  setwd("/lustre/work/schnablelab/braskey/sorghumQTL/v2/stalkHeight")
}

library(qtl)

sorghum_data <- read.cross(format="csv", file="/lustre/work/schnablelab/braskey/sorghumQTL/v2/newSorghumData.csv", na.strings="-", genotype=c("AA", "BB"), alleles=c("A", "B"), crosstype="riself")
sorghum_data <- sim.geno(sorghum_data, step=10, n.draws=256, error.prob = 0.001)
stalkHeightPerm4 <- scantwo(sorghum_data, pheno.col=5, method="imp", n.perm=200)

save(stalkHeightPerm4, file="stalkHeightPerm4.RData")