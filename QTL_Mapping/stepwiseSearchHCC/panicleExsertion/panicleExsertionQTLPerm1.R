set.seed(100)

if(getwd() != "/lustre/work/schnablelab/braskey/sorghumQTL/v2/panicleExsertion"){
  setwd("/lustre/work/schnablelab/braskey/sorghumQTL/v2/panicleExsertion")
}

library(qtl)

sorghum_data <- read.cross(format="csv", file="/lustre/work/schnablelab/braskey/sorghumQTL/v2/newSorghumData.csv", na.strings="-", genotype=c("AA", "BB"), alleles=c("A", "B"), crosstype="riself")
sorghum_data <- sim.geno(sorghum_data, step=10, n.draws=256, error.prob = 0.001)
panicleExsertionPerm1 <- scantwo(sorghum_data, pheno.col=6, method="imp", n.perm=200)

save(panicleExsertionPerm1, file="panicleExsertionPerm1.RData")