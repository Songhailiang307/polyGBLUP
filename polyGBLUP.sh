#!/bin/bash
#########################################################################
# 								
# Function: This script executes GBLUP, GDBLUP, polyGBLUP, and polyGDBLUP according to the specified ploidy level. 									
# Written by Hailiang Song
# Copyright:  Beijing Academy of Agriculture and Forestry Sciences. All rights reserved.
# email: songhl0317@163.com									
# First version: 2022-12-6 
# 								
#########################################################################

#' @examples
#' ## Autooctaploid Example
#' ./polyGBLUP Phenotype.txt Genotype.txt rel_id val_id 8
#' Phenotype.txt   # Phenotype file: Columns 2 to 5 of "G Sir Dam Sex" are arbitrary but must include: if it is simulated data, TBV is the true breeding value; if it is real data, TBV is the phenotype value.
#' Genotype.txt    # Genotype file: No header and ID name, individual order consistent with phenotype file.
#' rel_id          # ID number of reference population
#' val_id          # ID number of validation population
#' 8               # The specified ploidy level is based on the autopolyploid species

PHE=$1
SNP=$2
REL=$3
VAL=$4
Ploidy=$5

#Generate all genotype individuals
cat ${REL} ${VAL} > geno_id

#Genotype.txt

#Calculate the autopolyploid G and D matrices and their inverse matrices according to the specified ploidy level
Rscript ./bin/GDmatrixforploidy.R ${SNP} ${Ploidy} 
python ./bin/GINV.py ${Ploidy}_DMA.txt DMA.txt_GINV
python ./bin/Gma_to_3lineID.py DMA.txt_GINV geno_id Ginv
python ./bin/GINV.py ${Ploidy}_GMA.txt GMA.txt_GINV
python ./bin/Gma_to_3lineID.py GMA.txt_GINV geno_id Ginv

#Generate the reference and validation populations according to the specified id file
python ./bin/relvalphe.py ${REL} ${VAL} ${PHE} relphe.txt val_tbv

#run polyGBLUP and polyGDBLUP
cp ./bin/gblup.DIR ./bin/gdblup.DIR ./
./bin/r_dmuai gblup
./bin/r_dmuai gdblup

#get GEBV
python ./bin/ggebv.py gdblup.SOL val_tbv val_gdebv
python ./bin/gebv.py gblup.SOL val_tbv val_gebv

#Calculate prediction accuracy, unbiasedness, mse and mae
python ./bin/COR_REG_used2.py val_gdebv polyGDBLUP.txt 1
python ./bin/COR_REG_used2.py val_gebv polyGBLUP.txt 1	
cat gblup.PAROUT >> Varance_polyGBLUP.txt
cat gdblup.PAROUT >> Varance_polyGDBLUP.txt	


#Calculate the diploid G and D matrices and their inverse matrices
python ./bin/marker.py Genotype.txt ${Ploidy} Genotype2.txt
Rscript ./bin/GDmatrixfor2.R Genotype2.txt 2
python ./bin/GINV.py Genotype2.txt_DMA.txt DMA.txt_GINV
python ./bin/Gma_to_3lineID.py DMA.txt_GINV geno_id Ginv
python ./bin/GINV.py Genotype2.txt_GMA.txt GMA.txt_GINV
python ./bin/Gma_to_3lineID.py GMA.txt_GINV geno_id Ginv	


#run GBLUP and GDBLUP
./bin/r_dmuai gblup
./bin/r_dmuai gdblup	

#get GEBV
python ./bin/ggebv.py gdblup.SOL val_tbv val_gdebv
python ./bin/gebv.py gblup.SOL val_tbv val_gebv

#Calculate prediction accuracy, unbiasedness, mse and mae
python ./bin/COR_REG_used2.py val_gdebv GDBLUP.txt 1
python ./bin/COR_REG_used2.py val_gebv GBLUP.txt 1	
cat gblup.PAROUT >> Varance_GBLUP.txt
cat gdblup.PAROUT >> Varance_GDBLUP.txt		
