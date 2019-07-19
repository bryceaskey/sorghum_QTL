rm(list = ls())
library(qtl)

sorghum_data <- read.cross(format="csv", file="all_data_new_map.csv", na.strings="-", genotype=c("AA", "BB"), alleles=c("A", "B"), crosstype="riself")
sorghum_data <- sim.geno(sorghum_data, step=2, n.draws=8, error.prob = 0.001)
operm2 <- scantwo(sorghum_data, pheno.col=3, method="imp", n.perm=1000)