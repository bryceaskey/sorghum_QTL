# Script to merge genotype and phenotype data for all samples into 1 .csv file

# Load packages
library(tibble)

# Set working directory
setwd("C:/Users/Bryce/Documents/sorghum_QTL/QTL_mapping/")

# Specify number of phenotypic traits
num.pheno <- 4

# Load genotype data from Kong et al (2018) with SNPs remapped 
allData <- read.csv(file="data/FIleS2_genotype_remapped.csv", header=TRUE, sep=",")
allData <- add_column(allData, NA, .after="id")
colnames(allData)[2] <- "accessionID"

# Load QTL mapping data from Kong et al (2018) - column ID2 contains accession numbers for each RIL
accessionData <- read.csv(file="data/FileS4_IS11.avg.qtl.csv", header=TRUE, sep=",")

# Create a new column to save accession numbers for each RIL 
for(i in 3:length(allData[ , 1])){
  id <- allData$id[[i]]
  row.ind <- match(id, accessionData$id)
  accession.num <- accessionData$ID2[[row.ind]] + 650000
  allData$accessionID[[i]] <- accession.num
}

# Add phenotype data to allData ----
allData <- add_column(allData, NA, .after="accessionID")
colnames(allData)[colnames(allData)=="NA"] <- "leafCount"
allData <- add_column(allData, NA, .after="leafCount")
colnames(allData)[colnames(allData)=="NA"] <- "leafAngle"
allData <- add_column(allData, NA, .after="leafAngle")
colnames(allData)[colnames(allData)=="NA"] <- "stalkHeight"
allData <- add_column(allData, NA, .after="stalkHeight")
colnames(allData)[colnames(allData)=="NA"] <- "panicleExsertion"

phenotypeData <- read.csv(file="../computer_vision/phenotypeData.csv", header=TRUE, sep=",", stringsAsFactors=FALSE)
phenotypeData <- phenotypeData[3:nrow(phenotypeData), ]
phenotypeData[phenotypeData[,] == "NaN"] <- NA
for(i in 3:length(allData[ , 1])){
  accession.num <- allData$accessionID[[i]]
  row.ind <- grep(accession.num, phenotypeData$fileName)
  if(length(row.ind>0)){
    allData$leafCount[[i]] <- phenotypeData$medianLeafCount[[row.ind[1]]]
    allData$leafAngle[[i]] <- phenotypeData$leafAngle[[row.ind[1]]]
    allData$stalkHeight[[i]] <- phenotypeData$stalkHeight[[row.ind[1]]]
    allData$panicleExsertion[[i]] <- phenotypeData$panicleExsertion[[row.ind[1]]]
    phenotypeData <- phenotypeData[-c(row.ind[1]), ]
  }
}

# Add all duplicates to end of allData ----
for(i in 3:length(allData[ , 1])){
  accession.num <- allData$accessionID[[i]]
  row.ind <- grep(accession.num, phenotypeData$fileName)
  if(length(row.ind)>0){
    num.duplicates = length(row.ind)
    for(j in 1:num.duplicates){
      ind.geno.data <- allData[row.ind[j], (num.pheno + 3):ncol(allData)]
      new.row <- data.frame(
        id=allData$id[nrow(allData)] + 1,
        accessionID=accession.num,
        leafCount=phenotypeData$medianLeafCount[[row.ind[j]]],
        leafAngle=phenotypeData$leafAngle[[row.ind[j]]],
        stalkHeight=phenotypeData$stalkHeight[[row.ind[j]]],
        panicleExsertion=phenotypeData$panicleExsertion[[row.ind[j]]],
        ind.geno.data
      )
      colnames(new.row) <- colnames(allData)
      allData <- rbind(allData, new.row)
    }
  }
}

# Add all Ref (BTx623) parent plants to end of allData ----
# Note: alles at all markers are AA
ref.folder.inds <- grep('Ref', phenotypeData[ , 1])
for(i in 1:length(ref.folder.inds)){
  row.ind <- ref.folder.inds[[i]]
  id <- allData$id[nrow(allData)] + 1
  fileName <- as.character(phenotypeData$fileName[[row.ind]])
  accession.num <- sapply(strsplit(sapply(strsplit(fileName, "_"), "[", 4), "-"), "[", 3)
  leaf.num <- phenotypeData$maxLeafCount[[row.ind]]
  leaf.ang <- phenotypeData$leafAngle[[row.ind]]
  stk.hgt <- phenotypeData$stalkHeight[[row.ind]]
  pan.exs <- phenotypeData$panicleExsertion[[row.ind]]

  ind.geno.data <- allData[3, (num.pheno + 3):ncol(allData)]
  for(j in 1:length(ind.geno.data)){
    ind.geno.data[j] <- "AA"
  }
  
  new.row <- data.frame(id, accession.num, leaf.num, leaf.ang, stk.hgt, pan.exs, ind.geno.data)
  colnames(new.row) <- colnames(allData)
  
  allData <- rbind(allData, new.row)
}

rownames(allData) <- seq(length=nrow(allData))

# Export merged data as a .csv file ----
allData[1:2, 1:6] <- ""
allData[allData=="-"] <- NA
write.csv(allData, file="data/mergedData.csv", row.names=FALSE)