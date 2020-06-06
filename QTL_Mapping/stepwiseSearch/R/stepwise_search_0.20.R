library(qtl)

sorghum_data <- read.cross(format="csv", file="/lustre/work/schnablelab/braskey/sorghumQTL/v2/newSorghumData.csv", na.strings="NA", genotype=c("AA", "BB"), alleles=c("A", "B"), crosstype="riself")
sorghum_data <- jittermap(sorghum_data)
sorghum_data <- sim.geno(sorghum_data, step=10, n.draws=256, error.prob=0.001)

#leaf count QTL search ----------------------------------------------------------------------------
load("/lustre/work/schnablelab/braskey/sorghumQTL/v2/leafCount/leafCountPerm1.RData")
load("/lustre/work/schnablelab/braskey/sorghumQTL/v2/leafCount/leafCountPerm2.RData")
load("/lustre/work/schnablelab/braskey/sorghumQTL/v2/leafCount/leafCountPerm3.RData")
load("/lustre/work/schnablelab/braskey/sorghumQTL/v2/leafCount/leafCountPerm4.RData")
load("/lustre/work/schnablelab/braskey/sorghumQTL/v2/leafCount/leafCountPerm5.RData")
leafCountAll <- c(leafCountPerm1, leafCountPerm2, leafCountPerm3, leafCountPerm4, leafCountPerm5)
leafCountQTL <- stepwiseqtl(sorghum_data, pheno.col=3, max.qtl=10, penalties=calc.penalties(leafCountAll, alpha=0.20), verbose=FALSE)
save(leafCountQTL, file="/lustre/work/schnablelab/braskey/sorghumQTL/v2/leafCountQTL.RData")

#leaf angle QTL search ----------------------------------------------------------------------------
load("/lustre/work/schnablelab/braskey/sorghumQTL/v2/leafAngle/leafAnglePerm1.RData")
load("/lustre/work/schnablelab/braskey/sorghumQTL/v2/leafAngle/leafAnglePerm2.RData")
load("/lustre/work/schnablelab/braskey/sorghumQTL/v2/leafAngle/leafAnglePerm3.RData")
load("/lustre/work/schnablelab/braskey/sorghumQTL/v2/leafAngle/leafAnglePerm4.RData")
load("/lustre/work/schnablelab/braskey/sorghumQTL/v2/leafAngle/leafAnglePerm5.RData")
leafAngleAll <- c(leafAnglePerm1, leafAnglePerm2, leafAnglePerm3, leafAnglePerm4, leafAnglePerm5)
leafAngleQTL <- stepwiseqtl(sorghum_data, pheno.col=4, max.qtl=10, penalties=calc.penalties(leafAngleAll, alpha=0.20), verbose=FALSE)
save(leafAngleQTL, file="/lustre/work/schnablelab/braskey/sorghumQTL/v2/leafAngleQTL.RData")

#stalk height QTL search --------------------------------------------------------------------------
load("/lustre/work/schnablelab/braskey/sorghumQTL/v2/stalkHeight/stalkHeightPerm1.RData")
load("/lustre/work/schnablelab/braskey/sorghumQTL/v2/stalkHeight/stalkHeightPerm2.RData")
load("/lustre/work/schnablelab/braskey/sorghumQTL/v2/stalkHeight/stalkHeightPerm3.RData")
load("/lustre/work/schnablelab/braskey/sorghumQTL/v2/stalkHeight/stalkHeightPerm4.RData")
load("/lustre/work/schnablelab/braskey/sorghumQTL/v2/stalkHeight/stalkHeightPerm5.RData")
stalkHeightAll <- c(stalkHeightPerm1, stalkHeightPerm2, stalkHeightPerm3, stalkHeightPerm4, stalkHeightPerm5)
stalkHeightQTL <- stepwiseqtl(sorghum_data, pheno.col=5, max.qtl=10, penalties=calc.penalties(stalkHeightAll, alpha=0.20), verbose=FALSE)
save(stalkHeightQTL, file="/lustre/work/schnablelab/braskey/sorghumQTL/v2/stalkHeightQTL.RData")

#panicle exsertion QTL search ---------------------------------------------------------------------
load("/lustre/work/schnablelab/braskey/sorghumQTL/v2/panicleExsertion/panicleExsertionPerm1.RData")
load("/lustre/work/schnablelab/braskey/sorghumQTL/v2/panicleExsertion/panicleExsertionPerm2.RData")
load("/lustre/work/schnablelab/braskey/sorghumQTL/v2/panicleExsertion/panicleExsertionPerm3.RData")
load("/lustre/work/schnablelab/braskey/sorghumQTL/v2/panicleExsertion/panicleExsertionPerm4.RData")
load("/lustre/work/schnablelab/braskey/sorghumQTL/v2/panicleExsertion/panicleExsertionPerm5.RData")
panicleExsertionAll <- c(panicleExsertionPerm1, panicleExsertionPerm2, panicleExsertionPerm3, panicleExsertionPerm4, panicleExsertionPerm5)
panicleExsertionQTL <- stepwiseqtl(sorghum_data, pheno.col=6, max.qtl=10, penalties = calc.penalties(panicleExsertionAll, alpha=0.20), verbose=FALSE)
save(panicleExsertionQTL, file="/lustre/work/schnablelab/braskey/sorghumQTL/v2/panicleExsertionQTL.RData")
