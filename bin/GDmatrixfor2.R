#########################################################################
# 								
# Function: Construction of Relationship Matrix G with polyploid. 									
# Written by Hailiang Song
# Copyright:  Beijing Fisheries Research Institute. All rights reserved.
# email: songhl0317@163.com									
# First version: 2020-12-6 
# 								
#########################################################################

#' @examples
#' ## Diploid Example
#' Gmatrix.VanRaden <- Gmatrix(snp.pine, method="VanRaden", missingValue=-9, maf=0.05)
#' 
#' ## Autetraploid example
#' #Build G matrices
#' Gmatrix.VanRaden <- Gmatrix(snp.sol, method="VanRaden", ploidy=4)
#' Gmatrix.Pseudodiploid <- Gmatrix(snp.sol, method="VanRaden", ploidy=4, pseudo.diploid=TRUE)
#' 
#' #Build G matrix with weights
#' Gmatrix.weighted <- Gmatrix(snp.sol, method="VanRaden", weights = runif(3895,0.001,0.1), ploidy=4)


Gmatrix <- function (SNPmatrix = NULL, method = "VanRaden", 
                     missingValue = -9, maf = 0, thresh.missing = 1,
                     verify.posdef = FALSE, ploidy=2,
                     pseudo.diploid = FALSE, integer=TRUE,
                     ratio = FALSE, impute.method = FALSE, ratio.check=TRUE, weights=NULL){
  Time = proc.time()
  markers = colnames(SNPmatrix)
  
  if(!is.null(weights))
    if(length(weights)!=ncol(SNPmatrix))
      stop(deparse("weight should be a numeric vector of the same number of markers in the SNPmatrix"))

  if(ratio){ #This allows to enter in the scaled crossprod condition
    method="VanRaden"
    ploidy=8
  }
  
  if (!is.na(missingValue)) {
    m <- match(SNPmatrix, missingValue, 0)
    SNPmatrix[m > 0] <- NA
  }
  
  check_Gmatrix_data(SNPmatrix=SNPmatrix,method=method,ploidy=ploidy,ratio=ratio,integer=integer)
  
  NumberMarkers <- ncol(SNPmatrix)
  nindTotal <- colSums(!is.na(SNPmatrix))
  nindAbs <- max(nindTotal)
  cat("Initial data: \n")
  cat("\tNumber of Individuals:", max(nindTotal), "\n")
  cat("\tNumber of Markers:", NumberMarkers, "\n")
  
  if(ratio==FALSE){
    SNPmatrix <- snp.check(SNPmatrix,
                           ploidy = ploidy, 
                           thresh.maf = maf, 
                           thresh.missing = thresh.missing,
                           impute.method = impute.method)
  }
  
  ## Testing ratio check function: not final!
  if(ratio && ratio.check){
    SNPmatrix <- snp.check(SNPmatrix,
                           ploidy = ploidy, 
                           thresh.maf = maf, 
                           thresh.missing = thresh.missing,
                           impute.method = impute.method)
  }
  
  if(method=="Slater"){
    P <- colSums(SNPmatrix,na.rm = TRUE)/nrow(SNPmatrix)
    SNPmatrix[,which(P>ploidy/2)] <- ploidy-SNPmatrix[,which(P>(ploidy/2))]
    SNPmatrix <- slater_par(SNPmatrix,ploidy=ploidy)
    NumberMarkers <- ncol(SNPmatrix)
    Frequency <- colSums(SNPmatrix,na.rm=TRUE)/nrow(SNPmatrix)
    FreqP <- matrix(rep(Frequency, each = nrow(SNPmatrix)), 
                    ncol = ncol(SNPmatrix))
  }
  
  if(ploidy==2){
    alelleFreq <- function(x, y) {
      (2 * length(which(x == y)) + length(which(x == 1)))/(2 * 
                                                             length(which(!is.na(x))))
    }
    Frequency <- cbind(apply(SNPmatrix, 2, function(x) alelleFreq(x,0))
                       , apply(SNPmatrix, 2, function(x) alelleFreq(x, 2)))
    
#   if (any(Frequency[, 1] <= maf) & maf != 0) {
#      cat("\t", length(which(Frequency[, 1] <= maf)), "markers dropped due to maf cutoff of", maf, "\n")
#      SNPmatrix <- SNPmatrix[,-which(Frequency[, 1] <= maf)]
#      cat("\t", ncol(SNPmatrix), "markers kept \n")
#      Frequency <- as.matrix(Frequency[-which(Frequency[,1] <= 
#                                                maf), ])
#      NumberMarkers <- ncol(SNPmatrix)
#    }
    FreqP <- matrix(rep(Frequency[, 2], each = nrow(SNPmatrix)), 
                    ncol = ncol(SNPmatrix))
  }
  
  if(ploidy>2 && pseudo.diploid){## Uses Pseudodiploid model
    P <- colSums(SNPmatrix,na.rm = TRUE)/nrow(SNPmatrix)
    SNPmatrix[,which(P>ploidy/2)] <- ploidy-SNPmatrix[,which(P>(ploidy/2))]
    Frequency <- colSums(SNPmatrix,na.rm=TRUE)/(ploidy*nrow(SNPmatrix))
    Frequency <- cbind(1-Frequency,Frequency)
    FreqP <- matrix(rep(Frequency[, 2], each = nrow(SNPmatrix)), 
                    ncol = ncol(SNPmatrix))
    SNPmatrix[SNPmatrix %in% c(1:(ploidy-1))] <- 1
    SNPmatrix[SNPmatrix==ploidy] <- 2
  }
  
  if (method == "MarkersMatrix") {
    Gmatrix <- !is.na(SNPmatrix)
    Gmatrix <- tcrossprod(Gmatrix, Gmatrix)
    return(Gmatrix)
  }
  
  ## VanRaden ##
  if (method == "VanRaden") {
    if(is.null(weights)){
      if(ploidy==2){
        TwoPQ <- 2 * t(Frequency[, 1]) %*% Frequency[, 2]
        SNPmatrix <- SNPmatrix- 2 * FreqP
        SNPmatrix[is.na(SNPmatrix)] <- 0
        Gmatrix <- (tcrossprod(SNPmatrix, SNPmatrix))/as.numeric(TwoPQ)
      }else{
        if(ploidy>2){
          SNPmatrix<-scale(SNPmatrix,center=TRUE,scale=FALSE) 
          K<-sum(apply(X=SNPmatrix,FUN=var,MARGIN=2,na.rm=TRUE))
          SNPmatrix[which(is.na(SNPmatrix))] <- 0
          Gmatrix<-tcrossprod(SNPmatrix)/K
        }
      }
    }else{
      weights = weights[match(colnames(SNPmatrix),markers)]
      if(ploidy==2){
        TwoPQ <- 2 * t(Frequency[, 1]) %*% Frequency[, 2]
        SNPmatrix <- SNPmatrix- 2 * FreqP
        SNPmatrix[is.na(SNPmatrix)] <- 0
        Gmatrix <- tcrossprod(tcrossprod(SNPmatrix, diag(weights)), SNPmatrix)/as.numeric(TwoPQ)
      }else{
        if(ploidy>2){
          SNPmatrix<-scale(SNPmatrix,center=TRUE,scale=FALSE) 
          K<-sum(apply(X=SNPmatrix,FUN=var,MARGIN=2,na.rm=TRUE))
          SNPmatrix[which(is.na(SNPmatrix))] <- 0
          Gmatrix<-tcrossprod(tcrossprod(SNPmatrix, diag(weights)), SNPmatrix)/K
        }
      }
    }
  }
  
  if (method == "Yang") {
    FreqPQ <- matrix(rep(2 * Frequency[, 1] * Frequency[, 
                                                        2], each = nrow(SNPmatrix)), ncol = ncol(SNPmatrix))
    G.all <- (SNPmatrix^2 - (1 + 2 * FreqP) * SNPmatrix + 
                2 * (FreqP^2))/FreqPQ
    G.ii <- as.matrix(colSums(t(G.all), na.rm = T))
    SNPmatrix <- (SNPmatrix - (2 * FreqP))/sqrt(FreqPQ)
    G.ii.hat <- 1 + (G.ii)/NumberMarkers
    SNPmatrix[is.na(SNPmatrix)] <- 0
    Gmatrix <- (tcrossprod(SNPmatrix, SNPmatrix))/NumberMarkers
    diag(Gmatrix) <- G.ii.hat
  }
  
  if (method == "Su"){
    TwoPQ <- 2*(FreqP)*(1-FreqP)
    SNPmatrix[SNPmatrix==2 | SNPmatrix==0] <- 0
    SNPmatrix <- SNPmatrix - TwoPQ
    SNPmatrix[is.na(SNPmatrix)] <- 0
    Gmatrix <- tcrossprod(SNPmatrix,SNPmatrix)/
      sum(TwoPQ[1,]*(1-TwoPQ[1,]))        
  }
  
  if (method == "Vitezica"){
    TwoPQ <- 2*(FreqP[1,])*(1-FreqP[1,])
    SNPmatrix[is.na(SNPmatrix)] <- 0
    SNPmatrix <- (SNPmatrix==0)*-2*(FreqP^2) +
      (SNPmatrix==1)*2*(FreqP)*(1-FreqP) +
      (SNPmatrix==2)*-2*((1-FreqP)^2)
    Gmatrix <- tcrossprod(SNPmatrix,SNPmatrix)/sum(TwoPQ^2)
  }
  
  if (method == "Slater"){
    drop.alleles <- which(Frequency==0)
    if(length(drop.alleles)>0){
      Frequency <- Frequency[-drop.alleles]
      SNPmatrix <- SNPmatrix[,-drop.alleles]
      FreqP <- FreqP[,-drop.alleles]
    }
    FreqPQ <- matrix(rep(Frequency * (1-Frequency),
                         each = nrow(SNPmatrix)),
                     ncol = ncol(SNPmatrix))
    SNPmatrix[which(is.na(SNPmatrix))] <- 0
    G.ii <- (SNPmatrix^2 - (2 * FreqP) * SNPmatrix + FreqP^2)/FreqPQ
    G.ii <- as.matrix(colSums(t(G.ii), na.rm = T))
    G.ii <- 1 + (G.ii)/NumberMarkers
    SNPmatrix <- (SNPmatrix - (FreqP))/sqrt(FreqPQ)
    SNPmatrix[is.na(SNPmatrix)] <- 0
    Gmatrix <- (tcrossprod(SNPmatrix, SNPmatrix))/NumberMarkers
    diag(Gmatrix) <- G.ii
  }
  
  if( method == "Endelman" ){
    if( ploidy != 4 ){
      cat( stop( "'Endelman' method is just implemented for ploidy=4" ))
    }
    Frequency <- colSums(SNPmatrix)/(nrow(SNPmatrix)*ploidy)
    Frequency <- cbind(Frequency,1-Frequency)
    SixPQ <- 6 * t((Frequency[, 1]^2)) %*% (Frequency[, 2]^2)
    SNPmatrix <- 6 * t((Frequency[, 1]^2)%*%t(rep(1,nrow(SNPmatrix)))) - 
      3*t((Frequency[, 1])%*%t(rep(1,nrow(SNPmatrix))))*SNPmatrix + 0.5 * SNPmatrix*(SNPmatrix-1)
    Gmatrix <- (tcrossprod(SNPmatrix, SNPmatrix))/as.numeric(SixPQ)
  }
  
  if (verify.posdef) {
    e.values <- eigen(Gmatrix, symmetric = TRUE)$values
    indicator <- length(which(e.values <= 0))
    if (indicator > 0) 
      cat("\t Matrix is NOT positive definite. It has ", indicator, 
          " eigenvalues <= 0 \n \n")
  }
  
  Time = as.matrix(proc.time() - Time)
  cat("Completed! Time =", Time[3], " seconds \n")
  gc()
  return(Gmatrix)
}

## Internal Functions ##

# Coding SNPmatrix as Slater (2016) Full autotetraploid model including non-additive effects (Presence/Absence per Genotype per Marker)
slater_par <- function(X,ploidy){
  prime.index <- c(3,5,7,11,13,17,19,23,29,31,37,
                   41,43,47,53,59,61,67,71,73,79)
  
  NumberMarkers <- ncol(X)
  nindTotal <- nrow(X)
  X <- X+1
  
  ## Breaking intervals to use less RAM
  temp <- seq(1,NumberMarkers,10000)
  temp <- cbind(temp,temp+9999)
  temp[length(temp)] <- NumberMarkers
  prime.index <- prime.index[1:(ploidy+1)]
  
  ## Uses Diagonal (which is Sparse mode, uses less memmory)
  for(i in 1:nrow(temp)){
    X.temp <- X[,c(temp[i,1]:temp[i,2])]
    NumberMarkers <- ncol(X.temp)
    X.temp <- X.temp %*% t(kronecker(diag(NumberMarkers),prime.index))
    X.temp[which(as.vector(X.temp) %in%
                   c(prime.index*c(1:(ploidy+1))))] <- 1
    X.temp[X.temp!=1] <- 0
    if(i==1){
      X_out <- X.temp
    }else{
      X_out <- cbind(X_out,X.temp)
    }   
  }
  gc()
  return(X_out)
}

# Function by Luis F. V. Ferrao
# Internal function to maf cutoff and impute data
snp.check = function(M = NULL,
                     ploidy=4,
                     thresh.maf = 0.05,
                     thresh.missing = 0.9,
                     impute.method = "mean"){
  # SNP missing data
  ncol.init <- ncol(M)
  
  missing <- apply(M, 2, function(x) sum(is.na(x))/nrow(M))
  missing.low = missing <= thresh.missing
  cat("\nMissing data check: \n")
  if(any(missing.low)){
    cat("\tTotal SNPs:", ncol(M),"\n")
    cat("\t",ncol(M) - sum(missing.low), "SNPs dropped due to missing data threshold of", thresh.missing,"\n")
    cat("\tTotal of:",sum(missing.low), " SNPs \n")
    idx.rm <- which(missing.low)
    M <- M[, idx.rm, drop=FALSE]
  } else{
    cat("\tNo SNPs with missing data, missing threshold of = ", thresh.missing,"\n")
  }
  
  # Minor alele frequency
  MAF <- apply(M, 2, function(x) {
    AF <- mean(x, na.rm = T)/ploidy
    MAF <- ifelse(AF > 0.5, 1 - AF, AF) # Minor allele freq can be ref allele or not
  })
  snps.low <- MAF < thresh.maf
  cat("MAF check: \n")
  if(any(snps.low)){
    cat("\t",sum(snps.low), "SNPs dropped with MAF below", thresh.maf,"\n")
    cat("\tTotal:",ncol(M) - sum(snps.low), " SNPs \n")
    idx.rm <- which(snps.low)
    M <- M[, -idx.rm, drop=FALSE]
  } else{
    cat("\tNo SNPs with MAF below", thresh.maf,"\n")
  }
  
  # SNPs monomorficos
  mono <- apply(M, 2, function(x) {
    equal <- isTRUE(all.equal(x, rep(x[1], length(x))))
  })
  cat("Monomorphic check: \n")
  if(any(mono)){
    cat("\t",sum(mono), "monomorphic SNPs \n")
    cat("\tTotal:",ncol(M) - sum(mono), "SNPs \n")
    idx.rm <- which(mono)
    M <- M[, -idx.rm, drop=FALSE]
  } else{
    cat("\tNo monomorphic SNPs \n")
  }
  
  # Imputing by mode
  if(impute.method=="mean"){
    ix <- which(is.na(M))
    if (length(ix) > 0) {
      M[ix] <- mean(M,na.rm = TRUE)
    }
  }
  
  if(impute.method=="mode"){
    ix <- which(is.na(M))
    if (length(ix) > 0) {
      M[ix] <- as.integer(names(which.max(table(M))))
    }
  }
  
  # Total of SNPs
  cat("Summary check: \n")
  cat("\tInitial: ", ncol.init, "SNPs \n")
  cat("\tFinal: ", ncol(M), " SNPs (", ncol.init - ncol(M), " SNPs removed) \n \n")
  return(M)
}

# Internal function to check input Gmatrix arguments
check_Gmatrix_data <- function(SNPmatrix,ploidy,method, ratio=FALSE, integer=TRUE){
  if (is.null(SNPmatrix)) {
    stop(deparse("Please define the variable SNPdata"))
  }
  if (all(method != c("Yang", "VanRaden", "Slater", "Su", "Vitezica", "MarkersMatrix","Endelman"))) {
    stop("Method to build Gmatrix has to be either `Yang` or `VanRaden` for marker-based additive relationship matrix, or `Su` or `Vitezica` or `Endelman` for marker-based dominance relationship matrx, or `MarkersMatrix` for matrix with amount of shared-marks by individuals pairs")
  }
  
#  if( method=="Yang" && ploidy>2)
#    stop("Change method to 'VanRaden' for ploidies higher than 2 for marker-based additive relationship matrix")
  
  if( method=="Su" && ploidy>2)
    stop("Change method to 'Slater' for ploidies higher than 2 for marker-based non-additive relationship matrix")

  if( method=="Vitezica" && ploidy>2)
    stop("Change method to 'Slater' for ploidies higher than 2 for marker-based non-additive relationship matrix")
  
  if(!is.matrix(SNPmatrix)){
    cat("SNPmatrix class is:",class(SNPmatrix),"\n")
    stop("SNPmatrix class must be matrix. Please verify it.")
  }
  
  if(!ratio){
  if( ploidy > 20 | (ploidy %% 2) != 0)
    stop(deparse("Only even ploidy from 2 to 20"))
  
  t <- max(SNPmatrix,na.rm = TRUE)
  if( t > ploidy )
    stop(deparse("Check your data, it has values above ploidy number"))
  
  t <- min(SNPmatrix,na.rm=TRUE)
  if( t < 0 )
    stop(deparse("Check your data, it has values under 0"))
  
  if(integer)
    if(prod(SNPmatrix == round(SNPmatrix),na.rm = TRUE)==0)
      stop(deparse("Check your data, it has not integer values"))
    }

  if(ratio){
    t <- max(SNPmatrix,na.rm = TRUE)
    if( t > 1)
      stop(deparse("Check your data, it has values above 1. It is expected a ratio values [0;1]."))
    
    t <- min(SNPmatrix,na.rm=TRUE)
    if( t < 0 )
      stop(deparse("Check your data, it has values under 0. It is expected a ratio values [0;1]."))
  }
}



Args <- commandArgs(trailingOnly=TRUE)
genofile=Args[1]
ploidy=as.numeric(Args[2])

marker<-read.table(genofile)
marker<-as.matrix(marker)
G<-Gmatrix(marker,ploidy = ploidy,method="VanRaden")
write.table(G,paste0(genofile,"_GMA.txt"),quote = F,row.names =F,col.names =F)

D<-Gmatrix(marker,ploidy = ploidy,method="Vitezica")
write.table(D,paste0(genofile,"_DMA.txt"),quote = F,row.names =F,col.names =F)