#!/bin/sh
#SBATCH --time=03:15:00          # Run time in hh:mm:ss
#SBATCH --mem-per-cpu=4048      # Maximum memory required per CPU (in megabytes)
#SBATCH --job-name=hello-world
#SBATCH --partition=jclarke
#SBATCH --error=/work/schnablelab/baskey/job.%J.err
#SBATCH --output=/work/schnablelab/baskey/job.%J.out

module load matlab/r2019a

echo hello world

hostname
sleep 60
