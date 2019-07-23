if(getwd() != "/lustre/work/schnablelab/braskey/sorghumQTL"){
  setwd("/lustre/work/schnablelab/braskey/sorghumQTL")
}

library(qtl)

sorghum_data <- read.cross(format="csv", file="sorghumData.csv", na.strings="-", genotype=c("AA", "BB"), alleles=c("A", "B"), crosstype="riself")
sorghum_data <- sim.geno(sorghum_data, step=2, n.draws=256, error.prob = 0.001)
leafCount <- scantwo(sorghum_data, pheno.col=3, method="imp", n.perm=1000)

print(summary(leafCount))
print(calc.penalties(leafCount, alpha=c(0.05, 0.20)))