#########################################################################
# 								
# Function: Construction of additive and dominant genomic relationship matrices based on different allele dosages for autopolyploid species. 									
# Written by Hailiang Song
# Copyright:  Beijing Academy of Agriculture and Forestry Sciences. All rights reserved.
# email: songhl0317@163.com									
# First version: 2022-12-6 
# 								
#########################################################################

#' @examples
#' ## Autooctaploid Example
#' Rscript GDmatrixforploidy.R genotype.txt 8


Args <- commandArgs(trailingOnly=TRUE)
genofile=Args[1]
ploidy=as.numeric(Args[2])

marker<-read.table(genofile)
SNP_matrix<-as.matrix(marker)


# G,D
allele_freq = colSums(SNP_matrix)/(ploidy*nrow(SNP_matrix))
W = t(SNP_matrix) - ploidy*allele_freq
WWt = crossprod(W)
denom = sum(ploidy*allele_freq * (1 - allele_freq))
Gmatrix = WWt/denom

Gmatrix = Gmatrix + 0.001*diag(nrow(Gmatrix))
write.table(Gmatrix,paste0(ploidy,"_GMA.txt"),quote = F,row.names =F,col.names =F)


C_matrix = diag(length(combn(ploidy,2))/2, nrow = ncol(SNP_matrix), ncol = ncol(SNP_matrix))
Ploidy_matrix = diag(ploidy, nrow = ncol(SNP_matrix), ncol = ncol(SNP_matrix))
allele_freq_m<-matrix(allele_freq,nrow=nrow(SNP_matrix),ncol=length(allele_freq),byrow=T)

Q = (allele_freq_m^2 %*% C_matrix) - 
  allele_freq_m %*%(Ploidy_matrix - diag(1,nrow = ncol(SNP_matrix), ncol = ncol(SNP_matrix))) * SNP_matrix + 
  0.5 * (SNP_matrix) *(SNP_matrix-1)

D = Q %*% t(Q)

denomDom = sum(C_matrix[1,1]*allele_freq^2*(1- allele_freq)^2) 
Dmatrix = D/denomDom

Dmatrix = Dmatrix + 0.001*diag(nrow(Dmatrix))
write.table(Dmatrix,paste0(ploidy,"_DMA.txt"),quote = F,row.names =F,col.names =F)

