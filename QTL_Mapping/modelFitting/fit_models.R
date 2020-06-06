setwd("C:/Users/Bryce/Documents/sorghum_QTL/QTL_mapping/")

library(qtl)

sorghum_data <- read.cross(format="csv", file="data/mergedData.csv", na.strings="NA", genotype=c("AA", "BB"), alleles=c("A", "B"), crosstype="riself")
sorghum_data <- jittermap(sorghum_data)
sorghum_data <- sim.geno(sorghum_data, step=10, n.draws=256, error.prob = 0.001)

# alpha 0.05 ----
load("stepwiseSearch/results/alpha0.05/leafCountQTL.RData")
leafCountQTL <- refineqtl(sorghum_data, pheno.col=3, qtl=leafCountQTL)
leafCountModel <- fitqtl(sorghum_data, pheno.col=3, qtl=leafCountQTL, get.ests=TRUE)
save(leafCountModel, file="modelFitting/results/alpha0.05/leafCountModel.RData")

load("stepwiseSearch/results/alpha0.05/leafAngleQTL.RData")
leafAngleQTL <- refineqtl(sorghum_data, pheno.col=4, qtl=leafAngleQTL)
leafAngleModel <- fitqtl(sorghum_data, pheno.col=4, qtl=leafAngleQTL, get.ests=TRUE)
save(leafAngleModel, file="modelFitting/results/alpha0.05/leafAngleModel.RData")

load("stepwiseSearch/results/alpha0.05/stalkHeightQTL.RData")
stalkHeightQTL <- refineqtl(sorghum_data, pheno.col=5, qtl=stalkHeightQTL)
stalkHeightModel <- fitqtl(sorghum_data, pheno.col=5, qtl=stalkHeightQTL, get.ests=TRUE)
save(stalkHeightModel, file="modelFitting/results/alpha0.05/stalkHeightModel.RData")

load("stepwiseSearch/results/alpha0.05/panicleExsertionQTL.RData")
panicleExsertionQTL <- refineqtl(sorghum_data, pheno.col=6, qtl=panicleExsertionQTL)
panicleExsertionModel <- fitqtl(sorghum_data, pheno.col=6, qtl=panicleExsertionQTL, get.ests=TRUE)
save(panicleExsertionModel, file="modelFitting/results/alpha0.05/panicleExsertionModel.RData")

# alpha 0.20 ----
load("stepwiseSearch/results/alpha0.20/leafCountQTL.RData")
leafCountQTL <- refineqtl(sorghum_data, pheno.col=3, qtl=leafCountQTL)
leafCountModel <- fitqtl(sorghum_data, pheno.col=3, qtl=leafCountQTL, get.ests=TRUE)
save(leafCountModel, file="modelFitting/results/alpha0.20/leafCountModel.RData")

load("stepwiseSearch/results/alpha0.20/leafAngleQTL.RData")
leafAngleQTL <- refineqtl(sorghum_data, pheno.col=4, qtl=leafAngleQTL)
leafAngleModel <- fitqtl(sorghum_data, pheno.col=4, qtl=leafAngleQTL, get.ests=TRUE)
save(leafAngleModel, file="modelFitting/results/alpha0.20/leafAngleModel.RData")

load("stepwiseSearch/results/alpha0.20/stalkHeightQTL.RData")
stalkHeightQTL <- refineqtl(sorghum_data, pheno.col=5, qtl=stalkHeightQTL)
stalkHeightModel <- fitqtl(sorghum_data, pheno.col=5, qtl=stalkHeightQTL, get.ests=TRUE)
save(stalkHeightModel, file="modelFitting/results/alpha0.20/stalkHeightModel.RData")

load("stepwiseSearch/results/alpha0.20/panicleExsertionQTL.RData")
panicleExsertionQTL <- refineqtl(sorghum_data, pheno.col=6, qtl=panicleExsertionQTL)
panicleExsertionModel <- fitqtl(sorghum_data, pheno.col=6, qtl=panicleExsertionQTL, get.ests=TRUE)
save(panicleExsertionModel, file="modelFitting/results/alpha0.20/panicleExsertionModel.RData")