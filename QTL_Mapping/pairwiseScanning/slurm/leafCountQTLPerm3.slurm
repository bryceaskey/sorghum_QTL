#!/bin/sh
#SBATCH --time=08:00:00          # Run time in hh:mm:ss
#SBATCH --mem-per-cpu=32768      # Maximum memory required per CPU (in megabytes)
#SBATCH --job-name=leafCount
#SBATCH --partition=jclarke
#SBATCH --error=/work/schnablelab/braskey/sorghumQTL/v2/leafCount/leafCountQTL.%J.err
#SBATCH --output=/work/schnablelab/braskey/sorghumQTL/v2/leafCount/leafCountQTL.%J.out

module load R/3.5

Rscript /work/schnablelab/braskey/sorghumQTL/v2/leafCount/leafCountQTLPerm3.R

hostname
sleep 60

