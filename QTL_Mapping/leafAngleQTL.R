if(getwd() != "/lustre/work/schnablelab/braskey/sorghumQTL"){
  setwd("/lustre/work/schnablelab/braskey/sorghumQTL")
}

library(qtl)

sorghum_data <- read.cross(format="csv", file="sorghumData.csv", na.strings="-", genotype=c("AA", "BB"), alleles=c("A", "B"), crosstype="riself")
sorghum_data <- sim.geno(sorghum_data, step=2, n.draws=256, error.prob = 0.001)
leafAngle <- scantwo(sorghum_data, pheno.col=4, method="imp", n.perm=1000)

print(summary(leafAngle))
print(calc.penalties(leafAngle, alpha=c(0.05, 0.20)))