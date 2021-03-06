set.seed(200)

if(getwd() != "/lustre/work/schnablelab/braskey/sorghumQTL/v2/leafAngle"){
  setwd("/lustre/work/schnablelab/braskey/sorghumQTL/v2/leafAngle")
}

library(qtl)

sorghum_data <- read.cross(format="csv", file="/lustre/work/schnablelab/braskey/sorghumQTL/v2/newSorghumData.csv", na.strings="NA", genotype=c("AA", "BB"), alleles=c("A", "B"), crosstype="riself")
sorghum_data <- sim.geno(sorghum_data, step=10, n.draws=256, error.prob = 0.001)
leafAnglePerm2 <- scantwo(sorghum_data, pheno.col=4, method="imp", n.perm=200)

save(leafAnglePerm2, file="leafAnglePerm2.RData")