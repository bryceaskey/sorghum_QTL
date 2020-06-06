# sorghum_QTL
Automated phenotyping and QTL mapping procedure for 438 Sorghum bicolor plants grown from 18 September 2017 to 9 February 2018 in the Greenhouse Innovation Center at the University of Nebraska-Lincoln. 417 plants were members of a BTx623 x IS3620C family of RILs (https://npgsweb.ars-grin.gov/gringlobal/descriptordetail.aspx?id=289007), with 371 unique lines represented. The remaining 21 plants were of genotype BTx623, one of the parents of the RIL family. 

## computer_vision
MATLAB code for RGB image segmentation and automated measurement of 4 phenotypic traits. The phenotypes measured were stalk height, panicle exsertion, leaf count, and leaf angle.

## QTL_Mapping
R code used in genetic map construction, genotypic and phenotypic data merging, and multiple QTL mapping.

#### Genotype data source:
Kong, W., Kim, C., Zhang, D., Guo, H., Tan, X., Jin, H., Zhou, C., Shuang, L., et al. (2018). Genotyping by Sequencing of 393 Sorghum bicolor BTx623 × IS3620C Recombinant Inbred Lines Improves Sensitivity and Resolution of QTL Detection. G3: Genes, Genomes, Genetics, 8(8), 2563-2572.

#### Genetic map constructed with ASMap package in R:
Taylor, J., & Butler, D. (2017). R Package ASMap: Efficient Genetic Linkage Map Construction and Diagnosis. Journal of Statistical Software, 79(6), 1-29.

#### QTL mapping completed with R/qtl package in R:
Broman, K. W., Wu, H., Sen, Ś., & Churchill, G. A. (2003). R/qtl: QTL mapping in experimental crosses. Bioformatics, 19, 889-890.

#### QTL results visualized with karyoploteR package in R:
Gel, B., Serra, E. (2017). karyoploteR : an R/Bioconductor package to plot customizable genomes displaying arbitrary data. Bioinformatics, 33(19), 3088-3090.

# Overview of workflow:
[1. Generation of phenotype data](#pheno-data-generation) \
[2. Merging phenotype and genotype data](#data-merging) \
[3. Genetic map construction](#genetic-map) \
[4. Multiple QTL mapping](#QTL-mapping) \
[5. Model fitting](#estimate-effects) \
[6. Visualization of results](#visualize-results)

## Generation of phenotype data <a name="pheno-data-generation"></a>
Phenotypic data was generated by running the [RGB_image_analysis.m](https://github.com/bryceaskey/sorghum_QTL/blob/master/computer_vision/RGB_image_analysis.m) MATLAB script. Before running, the working directory should first be set to that containing the script and all other helper functions. The script loads and calls all other helper MATLAB functions, looping over all images in the total_folder_name directory that is specified at the beginning of the script. Output data is saved to a .csv file in the working directory. [Example of output data.](https://github.com/bryceaskey/sorghum_QTL/blob/master/computer_vision/phenotypeData.csv)

A more detailed explanation of the computer vision method, as well as a visualization of the algorithm can be found in [20200123_overview.pptx](https://github.com/bryceaskey/sorghum_QTL/blob/master/20200123_overview.pptx) and [poster.pdf](https://github.com/bryceaskey/sorghum_QTL/blob/master/poster.pdf).

## Genetic map construction <a name="genetic-map"></a>
A genetic map of marker positions was generated with the [construct_genetic_map.R](https://github.com/bryceaskey/sorghum_QTL/blob/master/QTL_Mapping/construct_genetic_map.R) script, which uses the ASMap package. The map was constructed with the genotype data from [Supplemental File 2](https://github.com/bryceaskey/sorghum_QTL/tree/master/QTL_Mapping/data/FIleS2_genotype.csv) of Kong et al (2018), which contains data for 616 SNP markers across 393 RILs. Mapping success was evaluated by plotting the physical position of each marker against its relative genetic distance, and calculating the resulting Spearman coefficient for each chromosome. The script exports the remapped marker data as a .csv file to the [QTL_mapping/data/](https://github.com/bryceaskey/sorghum_QTL/tree/master/QTL_Mapping/data) subdirectory. [Example of remapped marker data](https://github.com/bryceaskey/sorghum_QTL/blob/master/QTL_Mapping/data/FIleS2_genotype_remapped.csv).

## Merging phenotype and genotype data <a name="data-merging"></a>
For the r/qtl package to import and interpret data correctly, phenotype and genotype data was merged into a single .csv file, with phenotype data in the leftmost columns and genotype data to the right. Each row in the file contains the phenotype and genotype data collected for a single plant. See the [read.cross() documentation](https://www.rdocumentation.org/packages/qtl/versions/1.46-2/topics/read.cross) for a more thorough explanation of this formatting.

Genotype and phenotype data was merged with the [merge_data.R](https://github.com/bryceaskey/sorghum_QTL/blob/master/QTL_Mapping/add_pheno_data.R) script. The script parses the filenames contained in [phenotypeData.csv](https://github.com/bryceaskey/sorghum_QTL/blob/master/computer_vision/phenotypeData.csv) to identify the accession number (e.g. 658860) of the plant in the image which the phenotype data was generated for. To identify the corresponding genotype data for the accession, the ID2 column in [Supplemental Figure 4](https://github.com/bryceaskey/sorghum_QTL/tree/master/QTL_Mapping/data/FileS4_IS11.avg.qtl.csv) of Kong et al (2018) is searched for each accession number, and the id number from the first column saved. This id number is then matched with the id number in the first column of the [FIleS2_genotype_remapped.csv](https://github.com/bryceaskey/sorghum_QTL/tree/master/QTL_Mapping/data/FIleS2_genotype_remapped.csv) file to identify the genotype data for that plant. The script exports the merged genotype and phenotype data as a .csv file to the /data subdirectory. [Example of merged data file](https://github.com/bryceaskey/sorghum_QTL/tree/master/QTL_Mapping/data/mergedData.csv).

Note that for the 21 BTx623 plants included in this study, each marker was assigned a value of AA. This is because BTx623 is one of the parents of the RIL family.

## Multiple QTL mapping <a name="QTL-mapping"></a>
Multiple QTL mapping was used to identify both individually significant QTL, and significant interactions between QTL (i.e. epistatic effects). Due to the computationally intensive nature of this step, it was ran on the HCC's supercomputers. Thus, the merged genotype and phenotype data generated by the previous step was first uploaded into the HCC.

The first step step in multiple QTL mapping is pairwise scanning. The R code, SLURM scripts, and results of the pairwise scanning are saved in the [QTL_mapping/pairwiseScanning/](https://github.com/bryceaskey/sorghum_QTL/tree/master/QTL_Mapping/pairwiseScanning) subdirectory. As this step requires a significant amount of RAM, the scan for each phenotype was broken up into a separate script, and then further separated into 5 scripts which were ran concurrently. To specify which phenotype QTL should be scanned for, the pheno.col argument in the [scantwo()](https://www.rdocumentation.org/packages/qtl/versions/1.46-2/topics/scantwo) function should was set accordingly. Following recommendations from r/qtl's documentation, the multiple imputation method of pairwise scanning was applied, with a total of 1000 permutations per phenotype. This meant that each of the 5 scripts called for each phenotype ran 200 permutations, as reflected by the n.perm=200 argument in each [scantwo()](https://www.rdocumentation.org/packages/qtl/versions/1.46-2/topics/scantwo) call. To ensure that the permutations calculated by each of the 5 pairwise scans were different, the seed which R uses to generate random numbers was manually set with set.seed() at the beginning of eachs script. The results of each pairwise scan were then saved as a .RData file.

As a QTL search will identify every loci that is at least somewhat associated with the variation in the phenotype, a stepwise search using the pairwise scanning results was used to eliminate nonsignificant QTL from consideration. The R code, SLURM scripts, and results of the stepwise search are saved in the [QTL_mapping/stepwiseSearch/](https://github.com/bryceaskey/sorghum_QTL/tree/master/QTL_Mapping/stepwiseSearch) subdirectory. 2 significance levels (i.e. alpha values) were tested: 0.05 and 0.20. The R code first loads and merges the results of all pairwise scans for each phenotypic trait into a single object. The [stepwiseqtl()](https://www.rdocumentation.org/packages/qtl/versions/1.46-2/topics/stepwiseqtl) function is then called on the merged genotype and phenotype data generated previously, using the merged pairwise scan object to calculate the penalties that should be applied when determining the significance of each QTL and QTL interaction. The output, a QTL model which contains only QTL and QTL interactions with a p-value smaller than the specified alpha, is then saved as a .RData file.

## Model fitting <a name="estimate-effects"></a>
Model fitting was used to estimate how much of the observed phenotypic variation in the RIL family could be explained by the identified QTL and QTL interactions. The [model_fitting.R](https://github.com/bryceaskey/sorghum_QTL/tree/master/QTL_Mapping/modelFitting/fit_models.R) script was used to fit the QTL models at both 0.05 and 0.20 significance levels to the mereged genotype and phenotype data. Various statistics are calculated for each QTL and QTL interaction, including LOD score, % variance explained, and estimated phenotypic effect. These statistics can be viewed by calling the summary() function on the model. The script saves the fitted models (which contain these statistics) to the [QTL_mapping/modelFitting/results/](https://github.com/bryceaskey/sorghum_QTL/tree/master/QTL_Mapping/modelFitting/results/) subdirectory.

## Visualization of results <a name="visualize-results"></a>

