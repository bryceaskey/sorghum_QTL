#combine marker, genotype, and phenotype data for all individuals into 1 .csv file

library(tibble)

#number of phenotypic traits to be added to all_data
num.pheno <- 4

#make array of filenames containing Ref in specified directory
all.folders <- dir("/home/schnable/Desktop/SorghumSeedImages/SorghumImages")

all.data <- read.csv(file="/home/schnable/Documents/R/QTL_Practice/genetic_map.csv", header=TRUE, sep=",")
all.data <- add_column(all.data, NA, .after="id")
colnames(all.data)[colnames(all.data)=="NA"] <- "accessionID"

accession_data <- read.csv(file="/home/schnable/Documents/R/QTL_Practice/FileS4_IS11.avg.qtl.csv", header=TRUE, sep=",")

for(i in 3:length(all.data[ , 1])){
  id <- all.data$id[[i]]
  row.ind <- match(id, accession_data$id)
  accession.num <- accession_data$ID2[[row.ind]] + 650000
  all.data$accessionID[[i]] <- accession.num
}

#load phenotype data into all.data
all.data <- add_column(all.data, NA, .after="accessionID")
colnames(all.data)[colnames(all.data)=="NA"] <- "leafCount"
all.data <- add_column(all.data, NA, .after="leafCount")
colnames(all.data)[colnames(all.data)=="NA"] <- "leafAngle"
all.data <- add_column(all.data, NA, .after="leafAngle")
colnames(all.data)[colnames(all.data)=="NA"] <- "stalkHeight"
all.data <- add_column(all.data, NA, .after="stalkHeight")
colnames(all.data)[colnames(all.data)=="NA"] <- "panicleExsertion"

phenotype.data <- read.csv(file="/home/schnable/Documents/R/QTL_Practice/allPhenotypeData.csv", header=TRUE, sep=",", stringsAsFactors=FALSE)
for(i in 3:length(all.data[ , 1])){
  accession.num <- all.data$accessionID[[i]]
  row.ind <- grep(accession.num, phenotype.data$folderName)
  if(length(row.ind>0)){
    all.data$leafCount[[i]] <- phenotype.data$maxLeafCount[[row.ind[1]]]
    all.data$leafAngle[[i]] <- phenotype.data$leafAngle[[row.ind[1]]]
    all.data$stalkHeight[[i]] <- phenotype.data$stalkHeight[[row.ind[1]]]
    all.data$panicleExsertion[[i]] <- phenotype.data$panicleExsertion[[row.ind[1]]]
    phenotype.data <- phenotype.data[-c(row.ind[1]), ]
  }
}

#add all duplicates to end of all.data
phenotype.data <- phenotype.data[!grepl("NaN", phenotype.data$medianLeafCount), ]
for(i in 3:length(all.data[ , 1])){
  accession.num <- all.data$accessionID[[i]]
  row.ind <- grep(accession.num, phenotype.data$folder)
  if(length(row.ind)>0){
    num.duplicates = length(row.ind)
    for(j in 1:num.duplicates){
      id <- all.data$id[nrow(all.data)] + 1
      leaf.num <- phenotype.data$maxLeafCount[[row.ind[j]]]
      leaf.ang <- phenotype.data$leafAngle[[row.ind[j]]]
      stk.hgt <- phenotype.data$stalkHeight[[row.ind[j]]]
      pan.exs <- phenotype.data$panicleExsertion[[row.ind[j]]]
      ind.geno.data <- all.data[row.ind[j], (num.pheno + 3):ncol(all.data)]
      new.row <- data.frame(id, accession.num, leaf.num, leaf.ang, stk.hgt, pan.exs, ind.geno.data)
      names(new.row) <- names(all.data)
      all.data <- rbind(all.data, new.row)
      #phenotype.data <- phenotype.data[-c(row.ind[1]), ]
      #rownames(phenotype.data) <- seq(length=nrow(phenotype.data))
    }
  }
}

#add all Ref (parent) plants to end of all.data
#parent line - alles at all markers are AA
ref.folder.inds <- grep('Ref', phenotype.data[ , 1])
for(i in 1:length(ref.folder.inds)){
  row.ind <- ref.folder.inds[[i]]
  id <- all.data$id[nrow(all.data)] + 1
  folder.name <- as.character(phenotype.data$folderName[[row.ind]])
  accession.num <- sapply(strsplit(sapply(strsplit(folder.name, "_"), "[", 4), "-"), "[", 3)
  leaf.num <- phenotype.data$maxLeafCount[[row.ind]]
  leaf.ang <- phenotype.data$leafAngle[[row.ind]]
  stk.hgt <- phenotype.data$stalkHeight[[row.ind]]
  pan.exs <- phenotype.data$panicleExsertion[[row.ind]]

  ind.geno.data <- all.data[3, (num.pheno + 3):ncol(all.data)]
  for(j in 1:length(ind.geno.data)){
    ind.geno.data[j] <- "AA"
  }
  
  new.row <- data.frame(id, accession.num, leaf.num, leaf.ang, stk.hgt, pan.exs, ind.geno.data)
  names(new.row) <- names(all.data)
  
  all.data <- rbind(all.data, new.row)
  #phenotype.data <- phenotype.data[-c(row.ind[1]), ]
}

rownames(all.data) <- seq(length=nrow(all.data))

#write all.data to new csv file to be read by genetic_map.R
write.csv(all.data, file="allData.csv", row.names=FALSE)