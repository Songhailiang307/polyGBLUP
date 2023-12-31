# polyGBLUP
* A modified genomic best linear unbiased prediction improved the genomic prediction efficiency for autopolyploid species.
* This script executes GBLUP, GDBLUP, polyGBLUP, and polyGDBLUP according to the specified ploidy level.
* This script will store the results in a text file, including prediction accuracy, unbiasedness, mse and mae.

# Requirements
* R 3.6.3 or higher
* Python 3.7.0 or higher
* DMU v6

# Usage
```
./polyGBLUP.sh Phenotype.txt Genotype.txt rel_id val_id 8
```
## Description of arguments

* Phenotype.txt  
Phenotype file: Columns 2 to 5 of “G Sir Dam Sex” are arbitrary but must include: if it is simulated data, TBV is the true breeding value; if it is real data, TBV is the phenotype value.
```
ID G Sire Dam Sex Phe Tbv
601 1 27 450 M -0.378874325529809 -0.322451821660245
602 1 27 450 F 0.537554667907665 -1.03486386149278
603 1 27 450 M 1.87202482194102 0.868207084762083
604 1 27 450 F -2.41237020100124 -1.04451257766466
605 1 27 450 M 3.20884024591512 0.560424519731894
606 1 27 450 F -2.8160559253388 0.00536519306531358
607 1 27 450 M -0.527503767970916 0.0978945069090352
608 1 27 450 F 1.33129031811685 0.685598765498074
609 1 27 450 M 0.956010092761646 1.72195216327604
```
* Genotype.txt  
Genotype file: No header and ID name, individual order consistent with phenotype file.
```
8 0 0 0 0 3 3 5 0 0 5 0 0 0 0 0 8 8 
8 0 1 1 1 3 3 4 0 0 4 0 0 0 0 0 8 8 
8 0 0 0 0 3 3 5 0 0 5 0 0 0 0 0 8 8 
8 0 0 0 0 3 3 5 0 0 5 0 0 0 0 0 8 8 
8 0 1 1 1 4 4 3 0 0 3 0 0 0 0 0 8 8 
8 0 0 0 0 1 1 7 0 0 7 0 0 0 0 0 8 8 
8 0 1 1 1 2 2 5 0 0 5 0 0 0 0 0 8 8
```

* rel_id  
ID number of reference population.
```
16601
16602
16603
16604
16605
16606
16607
16608
16609
16610
16611
16612
```

* val_id  
ID number of validation population.
```
19616
18652
20176
19927
20506
19380
19181
20426
20217
19797
20146
20254
18658
```
* 8  
The specified ploidy level is based on the autopolyploid species.

## Output file
* GBLUP.txt  
Accuracy (corr), unbiasedness (reg), mse (MSE) and mae (MAE) of prediction using GBLUP.
* GDBLUP.txt  
Accuracy (corr), unbiasedness (reg), mse (MSE) and mae (MAE) of prediction using GDBLUP.
* Varance_GBLUP.txt  
Estimated variance components using GBLUP.
* Varance_GDBLUP.txt  
Estimated variance components using GDBLUP.
* polyGBLUP.txt  
Accuracy (corr), unbiasedness (reg), mse (MSE) and mae (MAE) of prediction using polyGBLUP.
* polyGDBLUP.txt  
Accuracy (corr), unbiasedness (reg), mse (MSE) and mae (MAE) of prediction using polyGDBLUP.
* Varance_polyGBLUP.txt  
Estimated variance components using polyGBLUP.
* Varance_polyGDBLUP.txt  
Estimated variance components using polyGDBLUP.

# Data simulation
```
Rscript ./bin/simFInaA.R 4 0.1
Rscript ./bin/simFInAD.R 8 0.3 1

4    # The ploidy level that needs to be simulated, 4 stands for autotetraploid.
	   # Heritability to be simulated.
8    # The ploidy level that needs to be simulated, 4 stands for Autooctaploid.
0.3  # Heritability to be simulated.
1    # dominance degree (δ)
```
# File Description
## The folder bin contains the following scripts:
* GDmatrixforploidy.R is R code for constructing additive and dominant genomic relationship matrices based on different allele dosages for autopolyploid species.
* GDmatrixfor2.R is R code for constructing additive and dominant genomic relationship matrices for diploid species.
* simFInaA.R is R code for genetic effects of traits including additive effects only were simulated. 
* simFInaAD.R is R code for genetic effects of traits including additive effects and dominant effects were simulated.
* Gma_to_3lineID.py is python code that converts a matrix into a 3 column form.
* GINV.py is python code for matrix inversion.
* relvalphe.py is a python code that extracts reference populations and validates population phenotypes.
* marker.py is a python code that handles genotype files.
* gebv.py is a python code that extracts the GEBV of the GBLUP or polyGBLUP model.
* ggebv.py is a python code that extracts the GEBV of the GDBLUP or polyGDBLUP model.
* COR_REG_used2.py is a python code that calculates accuracy, unbiasedness, mse, and mae.
* gblup.DIR is a DMU driver file for polyGBLUP or GBLUP model.
* gblup.DIR is a DMU driver file for polyGDBLUP or GDBLUP model.
* r_dmuai, dmu1 and dmuai are the modules of DMU software.
## The folder data contains the following files:
* Example includes simulated example data
* Sweetpotato includes autohexaploid sweet potato phenotype and genotype data
