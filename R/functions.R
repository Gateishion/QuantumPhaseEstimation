
arb_sampling <- function(f_d,sz,l_s, u_s){
#This function returns a sample of an
#arbitrary PDF
#f is a probability distribution
#size of sample

part <- 1000
x<-seq(l_s,u_s, by = abs(l_s-u_s)/part)

Smp <-  function(f){
  force(f)

  storage.vector <- rep(NA,length(x))
  for (i in 1:length(storage.vector)){
    storage.vector[i] <-  f(x[i])}
  return(storage.vector)
}

rsamp <- function(f,n){
  force(f)
  y1<-cumsum(Smp(f))*diff(seq(l_s,u_s, by = abs(l_s-u_s)/part))[1]
  pf <- approxfun(x,y1)
  qf <- approxfun(y1,x)
  return(qf(runif(n)))
}

return(rsamp(f_d,sz))

}

maxims <- function(a,tol,low,up) {
#This functions returns all local maximums of a
#function
#tol is the subdivitions

  force(a)
  x <- seq(low, up, length= tol)
  y <- vector("numeric", length = length(x))
  for (j in 1:length(x)) {
    y[j] <- a(x[j])
  }
  #print(x)
  m <- rep(NA, length(x)-1)
  for (i in 2:(length(x)-1)) {
    #print(c(y[i-1],y[i],y[i+1]))
    if( y[i-1] < y[i] & y[i] > y[i+1]){
    m[i] <- optimize(a, lower = x[i-1], x[i+1], maximum = T, tol=1e-16)$maximum }
  }

  #Delete de NAs
  m <- m[!is.na(m)]
  #m <- c(m,a(x[1]), a(x[length(x)]))
  m <- c(m,x[1], x[length(x)])
  #if (length(m)==0){m <-optimize(a, lower = low, up, maximum = T,tol=1e-16)$maximum }
  return(m)

}


choosemax <- function(atol,vec,f){
#choose the global maximum of a vector of maximums
#atol is the digits to compare
    force(f)
  #if( is.na(vec) == TRUE){
  #  return(NA)
  #}
  #v1 <- f(vec)
  v1 <- vector("numeric", length(vec))
  for (j in 1:length(vec)) {
    v1[j] <- round(f(vec[j]), digits = atol)
  }

  v2 <- vec[which(v1 == max(v1))]
  prop <- length(v2)
  #ss <- sample(1:prop, size = 1, prob = rep((1/(prop)), prop))
  ss <- sample(1:prop, size = 1)
  return(v2[ss])
}


logfunc2 <- function(f){
  #returns the log of a function
  force(f)
  function(...){log(f(...))}
}


sumfunct2<-function(a,b){
  #returns the sum of two functions
  force(a)
  force(b)
  function(...){a(...)+b(...)}
}


sumfctb2 <- function(vec,n){
  #sum vector of functions
  if (n==1) {vec[[1]]}
  else{
    for(j in 1:n){
      force(vec[[j]])
    }
    out <- vec[[1]]
    for(i in 2:n){
      out <- sumfunct2(out,vec[[i]])
    }
    return(out)
  }
}


pdfunct2<-function(a,b){
  #Product of 2 functs
  force(a)
  force(b)
  function(...){a(...)*b(...)}
}


pdfctb2 <- function(vec,n){
  #Product of list of functions
  if (n==1) {vec[[1]]}
  else{
    for(j in 1:n){
      force(vec[[j]])
    }
    out <- vec[[1]]
    for(i in 2:n){
      out <- pdfunct2(out,vec[[i]])
    }
    return(out)
  }
}


Holevo_Var <- function(est){
  #Returns the Holevo variance
  #est, vector of estimations
  v <- (CircStats::circ.disp(est)$rbar^(-2)-1)
  return(v)
}


#-----------------------------------
#Pauli Basis
#-----------------------------------
Pauli_M <- function(i){
#i in 0 to 3
S <- vector(mode="list", length = 4)
sigma0 <- matrix(nrow=2, ncol = 2, c(1,0,0,1))
sigma1 <- matrix(nrow=2, ncol = 2, c(0,1,1,0))
sigma2 <- matrix(nrow=2, ncol = 2, c(0,complex(real=0, imaginary = 1),complex(real = 0, imaginary = -1),0))
sigma3 <-  matrix(nrow=2, ncol = 2, c(1,0,0,-1))

S[[1]] <- sigma0
S[[2]] <- sigma1
S[[3]] <- sigma2
S[[4]] <- sigma3

if(i > 4 | i< 0){
  return( "i must be 0,1,2,3 or 4")
}

return(S[[i+1]])

}

P_vector <- function(v) {
  #returns the "dot product" of paulis with a vector
  sigma0 <- matrix(nrow=2, ncol = 2, c(1,0,0,1))
  sigma1 <- matrix(nrow=2, ncol = 2, c(0,1,1,0))
  sigma2 <- matrix(nrow=2, ncol = 2, c(0,complex(real=0, imaginary = 1),complex(real = 0, imaginary = -1),0))
  sigma3 <-  matrix(nrow=2, ncol = 2, c(1,0,0,-1))
  (v[1]*sigma1)+(v[2]*sigma2)+(v[3]*sigma3)
  }

Qubit <- function(a){
  #Returns a qubit
  #Input Bloch vector
  if(length(a)>4){
    return("the length of a must be 3")
  }
  asig <- P_vector(a)
  rho <- (1/2)*(Pauli_M(0)+asig)
  return(rho)
}


#--------------------------------------
#Covariant Estimation
#--------------------------------------

P_covariante <- function(qbit_vec,axis,phase,x){
#return p(x | theta) de la medida covariante M_star

n <- axis
J <- (1/2)*(P_vector(n))
rho <- Qubit(qbit_vec)
theta <- phase

SpecJ <- eigen(J)
Pj1 <- SpecJ$vectors[,1]%*%Conj(t(SpecJ$vectors[,1]))
Pjm1 <- SpecJ$vectors[,2]%*%Conj(t(SpecJ$vectors[,2]))
Pb1 <- Re(sum(mgcv::sdiag(Pj1%*%rho)))
Pbm1 <- Re(sum(mgcv::sdiag(Pjm1%*%rho)))
SuppJ <- c(SpecJ$values[1],SpecJ$values[2])
ProbJ <- c(Pb1, Pbm1)
MatofpbJ <- cbind(SuppJ, ProbJ)


eilam <- function(x,t,m) {complex(real = cos(m*(x-t)), imaginary = -sin(m*(x-t)))}
PSn <- MatofpbJ

create_eilam <- function(i){
  ei_out <- function(x,t) {eilam(x=x, t=t,m=i)*sqrt(PSn[,2][i])}
}
Sumandos <- lapply(1:length(PSn[,2]), create_eilam)

SP <- sumfctb2(Sumandos, length(Sumandos))
ProbSN <- function(x) {pracma::Real ((1/(2*pi))*(SP(x,t=theta)*Conj(SP(x,t=theta))))}
vfpbMS <- Vectorize(ProbSN)
return(vfpbMS(x))

}

#---------------------------------------
#Entangled
#---------------------------------------

Conv2 <- function(M,N) {
  kSamples::conv(M[,1],M[,2],N[,1],N[,2])
}
#Convolution of a vector of matrices of probabilities
ConvNb <- function(M,n){
  if (n==1) {
    M}
  else{
    out <- M
    for(i in 2:n){
      out <- Conv2(out,M)
    }
    return(out)
  }
}


Matrix_Prob_J <- function(axis,qbit_vec){

  n <- axis
  J <- (1/2)*(P_vector(n))
  rho <- Qubit(qbit_vec)

  SpecJ <- eigen(J)
  Pj1 <- SpecJ$vectors[,1]%*%Conj(t(SpecJ$vectors[,1]))
  Pjm1 <- SpecJ$vectors[,2]%*%Conj(t(SpecJ$vectors[,2]))
  Pb1 <- Re(sum(mgcv::sdiag(Pj1%*%rho)))
  Pbm1 <- Re(sum(mgcv::sdiag(Pjm1%*%rho)))
  SuppJ <- c(SpecJ$values[1],SpecJ$values[2])
  ProbJ <- c(Pb1, Pbm1)
  MatofpbJ <- cbind(SuppJ, ProbJ)

  return(MatofpbJ)

}





################################################################
#AQSE
################################################################

AQSE_Hvar <- function(theta_real, par_space, n_boost, num_prob, n_i, a_i){

library(parallel)
numCores <- detectCores()


#------------------------------
#Parametro desconocido
#------------------------------
theta <- theta_real
N <- 100
theta_discret <- seq(par_space[1], par_space[2], length.out = N)

#--------------------------------
#Axis of rotation
#--------------------------------
#n <- c(1/sqrt(3),1/sqrt(3),1/sqrt(3))
n <- n_i

#----------------------------------
#Initial Condition of the probe
#----------------------------------
#a <- c(1/sqrt(2), 0, -1/sqrt(2))
#a <- c((3*sqrt(5)+sqrt(3))/12,-(3*sqrt(5)-sqrt(3))/12 ,1/sqrt(3))
a <- a_i

#------------------------------------
#State Bloch-Rep
#------------------------------------

rho <- Qubit(a)

#----------------------------------
#Rotations
#----------------------------------

nca <- pracma::cross(c(n[1],n[2],n[3]), c(a[1],a[2],a[3]))
nda <- pracma::dot(c(n[1],n[2],n[3]), c(a[1],a[2],a[3]))
at <- function(t){(cos(t)*a) +(sin(t)*nca)+(2*(sin(t/2)^2)*nda*n)}
rhotbloch <- function(t) { Qubit(at(t)) }

et <- function(t) {(pracma::cross(n,at(t)))/pracma::Norm(pracma::cross(n,at(t))) }

#Projectors
EM <- function(t) {(1/2)*(Pauli_M(0) + P_vector(et(t)))}
Em <- function(t) {(1/2)*(Pauli_M(0) - P_vector(et(t)))}
#Probabilities
p1 <- function(t,g) {pracma::Real(sum(diag(rhotbloch(t)%*%EM(g))) )}
vp1 <- Vectorize(p1)
p0 <- function(t,g) {pracma::Real(sum(diag(rhotbloch(t)%*%Em(g))) )}
vp0 <- Vectorize(p0)

#---------------------------------------
# Likelihood
#---------------------------------------

Measure <- function(t,g){rbinom(1,1,vp1(t,g))}

Like <- function(x,t,gi){
  if(x==1){
    return(vp1(t,gi))
  }
  if(x==0){
    return(vp0(t,gi))
  }
}

#------------------------------------
#Auxiliary Function
#------------------------------------

aux_fn <- function(t){
  return(1)
}

#------------------------------------
#Method
#------------------------------------

MLE_fuji_qubit <- function(Tot_meas){
  CI_init <- par_space
  measures <- vector("numeric", length = Tot_meas)
  estimations <- rep(1, length = Tot_meas+1)
  #like_list <- vector(mode = "list", Tot_meas)
  #loglike_list <- vector(mode = "list", Tot_meas)

  estimations[1] <- runif(1, min=par_space[1], max= par_space[2])

  loglike_l <- vector(mode="list", Tot_meas-1)

  for (k in 1:length(loglike_l)) {
    loglike_l[[k]] <- aux_fn
  }


  for(j in 1:Tot_meas) {
    #print(estimations[j])
    measures[j] <- Measure(theta,estimations[j])

    create_loglikeMS <- function(i){
      loglikes <- function(t){Like(measures[i],t, estimations[i]) }
    }

    loglike_l[[j]] <- create_loglikeMS(j)
    #loglike <- function(t) sumfctb2(loglike_l, j)(t)
    loglike <- function(t) log(pdfctb2(loglike_l, j)(t))
    V_ll <- Vectorize(loglike)
    #plot(theta_discret, V_ll(theta_discret), type = "l")

    Inter <- c(CI_init[1], CI_init[2])

    mx <- tryCatch(maxims(V_ll, 25, Inter[1], Inter[2]), error=function(e) NA)
    estimations[j+1] <- choosemax(9, mx, V_ll)

  }
  #
  # return(estimations[Tot_meas])
  return(estimations[Tot_meas])
}



#----------------------------------
#Bootstrap_to_Variance
#----------------------------------

nummles <- n_boost


VariancesJI <- function(nm){
  X <- rep(nm, nummles)
  #estimsJI <- sapply(X, MLEestCorrection)
  estimsJI <- unlist(mclapply(X, MLE_fuji_qubit, mc.cores = (numCores)))
  #estimsJI = estimsJI[!is.na(estimsJI)]
  v <- (mean(cos(estimsJI -theta))^(-2)-1)*(nm)
  return(v)
}

return(VariancesJI(num_prob))

}

#######################################################
#######################################################
#Covariant
#######################################################
#######################################################


Covariant_Hvar <- function(theta_real, par_space, n_boost, num_prob, n_i, a_i){

library(parallel)
numCores <- detectCores()
#numCores <- 6

#----------------------------
#Parametro desconocido
#----------------------------
theta <- theta_real
xp<-seq(par_space[1],par_space[2], length.out = 100)


#-------------------------------
#Parameters of Generator
#-------------------------------
#n1 <- 1/sqrt(3)
#n2 <- 1/sqrt(3)
#n3 <- 1/sqrt(3)
n <- n_i


#----------------------------------
#Parameters of state
#----------------------------------
#a1 <- 1/sqrt(2)
#a2 <- 0
#a3 <- -1/sqrt(2)

#a1 <- (3*sqrt(5)+sqrt(3))/12
#a2 <- -(3*sqrt(5)-sqrt(3))/12
#a3 <- 1/sqrt(3)
a <- a_i

#---------------------------------
#Likelihood
#---------------------------------

likeMS1 <- function(x,t) pracma::Real(P_covariante(a,n,t,x))
vflkMS <- Vectorize(likeMS1)
llikeMS <- logfunc2(vflkMS)

vfpbMS <- function(x) { pracma::Real(P_covariante(a,n,theta,x))}


MLEest <- function(nm) {

  #Generate the sample
  sampMS <- arb_sampling(vfpbMS,nm,par_space[1],par_space[2])
  sampMS <- sampMS[!is.na(sampMS)]
  while (length(sampMS)<nm) {
    sampMS <- append(sampMS, arb_sampling(vfpbMS, 1,par_space[1],par_space[2]), after = length(sampMS))
    sampMS <- sampMS[!is.na(sampMS)]}

  create_loglikeMS <- function(i){
    loglikes <- function(t){llikeMS(x=sampMS[i], t=t)   }
  }
  loglikesMS <- lapply(1:length(sampMS), create_loglikeMS)
  PlikelihoodMS <- function(t) sumfctb2(loglikesMS, length(loglikesMS))(t)

  #if(nm==1)  {mleM <- sampMS[nm]} else {
  mleM <- choosemax(8, maxims(Vectorize(PlikelihoodMS),8,par_space[1],par_space[2]), Vectorize(PlikelihoodMS))
  #}
  #plot(xp, Vectorize(PlikelihoodMS)(xp), type = "l")
  return(mleM)
}

#system.time({ print(MLEest(300))})

#----------------------------------
#Bootstrap_to_Variance
#----------------------------------

nummles <- n_boost

VariancesJI <- function(nm){
  X <- rep(nm, nummles)
  #estimsJI <- sapply(X, MLEestCorrection)
  estimsJI <- unlist(mclapply(X, MLEest, mc.cores = (numCores)))
  v <- (mean(cos(estimsJI -theta))^(-2)-1)*(nm)
  return(v)
}

return(VariancesJI(num_prob))

}



################################################################
################################################################
#Our_prop
################################################################
################################################################


ECI_Hvar <- function(theta_real, par_space, n_boost, num_prob, n_i, a_i, C_lev, Margin_Err){

  library(parallel)
  numCores <- detectCores()

  #------------------------------
  #Parametro desconocido
  #------------------------------
  theta <- theta_real
  N=300
  theta_discret <- seq(par_space[1], par_space[2], length.out = N)

  #--------------------------------
  #Axis of rotation
  #--------------------------------
  n <- n_i

  #----------------------------------
  #Initial Condition of the probe
  #----------------------------------

  #a <- c(1/sqrt(2), 0, -1/sqrt(2))
  #a <- c((3*sqrt(5)+sqrt(3))/12,-(3*sqrt(5)-sqrt(3))/12 ,1/sqrt(3))
  a <- a_i

  #---------------------------------
  #Covariant Likelihood
  #---------------------------------

  likeMS1 <- function(x,t) pracma::Real(P_covariante(a,n,t,x))
  vflkMS <- Vectorize(likeMS1)
  llikeMS <- logfunc2(vflkMS)

  vfpbMS <- function(x) { pracma::Real(P_covariante(a,n,theta,x))}

  #---------------------------------
  #Lue Likelihood
  #---------------------------------

  nca <- pracma::cross(c(n[1],n[2],n[3]), c(a[1],a[2],a[3]))

  nda <- pracma::dot(c(n[1],n[2],n[3]), c(a[1],a[2],a[3]))
  at <- function(t){(cos(t)*a) +(sin(t)*nca)+(2*(sin(t/2)^2)*nda*n)}
  rhotbloch <- function(t) { Qubit(at(t)) }

  et <- function(t) {(pracma::cross(n,at(t)))/pracma::Norm(pracma::cross(n,at(t))) }

  #Projectors
  EM <- function(t) {(1/2)*(Pauli_M(0) + P_vector(et(t)))}
  Em <- function(t) {(1/2)*(Pauli_M(0) - P_vector(et(t)))}
  #Probabilities
  p1 <- function(t,g) {pracma::Real(sum(diag(rhotbloch(t)%*%EM(g))) )}
  vp1 <- Vectorize(p1)
  p0 <- function(t,g) {pracma::Real(sum(diag(rhotbloch(t)%*%Em(g))) )}
  vp0 <- Vectorize(p0)


  Measure <- function(t,g){rbinom(1,1,vp1(t,g))}

  Like <- function(x,t,gi){
    if(x==1){
      return(vp1(t,gi))
    }
    if(x==0){
      return(vp0(t,gi))
    }
  }

  Measure <- function(t,g){rbinom(1,1,vp1(t,g))}
  like1 <- function(n,x,t,g){(vp1(t,g)^x)*(1-vp1(t,g))^(n-x)}
  vflk1 <- Vectorize(like1)
  llike1 <- logfunc2(vflk1)

  #-------------------------------------
  #Confidence Interval
  #-------------------------------------

  FCount <- function(t,g,x) {(Fq(x)*cos(t-g)^2)/(1-Fq(x)*sin(t-g)^2)}

  integratingtest <- function(t,x)    (1/(2*pi))*((1-x^2)*(sin(t-theta)^2)/(1+cos(t-theta)*sqrt((1-x^2))))
  vint <- Vectorize(integratingtest)
  FS <- function(xx){ integrate(vint,par_space[1],par_space[2], x=xx)$value }
  FISP <- FS(nda)

  Crit_point <- function(C_l){
    qnorm(1-((1-C_l)/2))
  }

  crit <- Crit_point(C_lev)

  ConfidenceIntervals <- function(nummeas, maxlik){
    ciValue <- (1/sqrt((nummeas*FISP)))*crit
    CIf <- c((maxlik-ciValue), (maxlik+ciValue))
    return(CIf)
  }

  FQ <- 1-(nda)^2

  ConfidenceIntervals_2 <- function(nummeas, maxlik, nr){
    ciValue <- (1/sqrt(( (nummeas*FISP) + (nr*FQ)  )))*crit
    CIf <- c((maxlik-ciValue), (maxlik+ciValue))
    return(CIf)
  }


  #-------------------------------------
  #Update Function
  #-------------------------------------

  AddlikeRy <- function(step, likelihoodp, mlep){
    force(likelihoodp)
    nmCount <- sum(rbinom(step, 1, vp1(theta, mlep)))
    loglikeCount <- function(t) {llike1(step,nmCount,t,mlep) + likelihoodp(t)}
    return(loglikeCount)
  }

  #-------------------------------------
  #MLE
  #-------------------------------------


  MLEest <- function(nm,nt,stepf) {
    count <- nt-nm
    #mleM <- vector(mode="numeric", length = nt+1)

    if(nm == 0) {
      CI <- par_space
      mleM <- runif(1, min=par_space[1], max=par_space[2])
      nmCount <- sum(rbinom(stepf, 1, vp1(theta, mleM)))
      loglikeCount <- function(t) {llike1(stepf,nmCount,t,mleM)}
      PlikelihoodMS <- Vectorize(loglikeCount)


      while (count>0) {
        print(mleM)
        PlikelihoodMS <- AddlikeRy(stepf, PlikelihoodMS, mleM)
        mleM <- choosemax(8, maxims(PlikelihoodMS,50,CI[1],CI[2]), PlikelihoodMS)
        #print(choosemax(8, maxims(PlikelihoodMS,50,CI[1],CI[2]), PlikelihoodMS))
        count <- count-stepf
      }
      return(mleM)
    }


    else {

      #Generate the sample
      sampMS <- arb_sampling(vfpbMS,nm,par_space[1],par_space[2])
      sampMS <- sampMS[!is.na(sampMS)]
      while (length(sampMS)<nm) {
        sampMS <- append(sampMS, arb_sampling(vfpbMS, 1,par_space[1],par_space[2]), after = length(sampMS))
        sampMS <- sampMS[!is.na(sampMS)]}

      #sampMS <- rep(5,nm)

      create_loglikeMS <- function(i){
        loglikes <- function(t){llikeMS(x=sampMS[i], t=t)   }
      }
      loglikesMS <- lapply(1:length(sampMS), create_loglikeMS)


      PlikelihoodMS <- function(t) sumfctb2(loglikesMS, length(loglikesMS))(t)
      VPLike <- Vectorize(PlikelihoodMS)

      mleM <- choosemax(8, maxims(VPLike,45,par_space[1],par_space[2]), VPLike)
      #mleM <- optimize(VPLike, lower = 0, upper = 2*pi, tol=1e-30, maximum = T)$maximum
      mlePovmStar <- mleM
      #print(mleM)
      #plot(theta_discret, PlikelihoodMS(theta_discret), type="l")
      CI <- ConfidenceIntervals(nm, mlePovmStar)
      ncr <- 0

      #print(CI)
      while (count>0) {

        PlikelihoodMS <- AddlikeRy(stepf, PlikelihoodMS, mleM)
        VPLK <- Vectorize(PlikelihoodMS)
        mleM <- optimize(VPLK, lower = (CI[1]-0.00001), upper = (CI[2]+0.0001), tol=1e-30, maximum = T)$maximum%%(2*pi)
        #mleM <- choosemax(9, maxims(Vectorize(PlikelihoodMS),20,0,2*pi), Vectorize(PlikelihoodMS))
        #mleM <- optimize(VPLK, lower = 0, upper = 2*pi, tol=1e-30, maximum = T)$maximum%%(2*pi)
        print(mleM)
        #}

        ncr <- ncr+stepf
        CI <- ConfidenceIntervals_2(nm, mleM, ncr)
        count <- count-stepf
        #print(mleM)
        #print(CI)
      }
    }

    return(c(mleM))
  }


  #---------------------------------
  #Calculate the minimum covariant
  #---------------------------------

  Sample_Size <- function(cl, me, Fq){

    #Am <- ((100-(cl))/2)
    #zc <- qnorm(Am, lower.tail = F)
    #z <- c(1.645,1.96, 2.326, 2.576)

    n = (crit^2)/(Fq*(me^2))

    return(ceiling(n))

  }



  Conf_level <- C_lev
  num_cov <- Sample_Size(Conf_level, Margin_Err, FISP)


  #------------------------------------------------
  #Bootstrap_to_calculate_variance
  #------------------------------------------------

  nummles <- n_boost
  ncov <- num_cov
  stepM <-1
  MLEestCorrection <-  function(m) {MLEest(ncov,m,stepM)}


  #estimations <- NULL
  VariancesJI <- function(nm){
    X <- rep(nm, nummles)
    #estimsJI <- sapply(X, MLEestCorrection)
    estimsJI <- unlist(mclapply(X, MLEestCorrection, mc.cores = (numCores)))
    v <- (mean(cos(estimsJI -theta))^(-2)-1)*(nm)
    #print(estimsJI)
    return(v)
  }


return(VariancesJI(num_prob))


}









################################################################
################################################################
#Hvar_Scheme
################################################################
################################################################


Hvar_Scheme <- function(theta_real, par_space, n_boost, num_prob, n,a, strategy){
   if( strategy == 2){
     return(AQSE_Hvar(theta_real = theta_real, par_space = par_space, n_boost = n_boost, num_prob = num_prob, n_i = n, a_i=a))
   }

  if( strategy == 1){
    return(Covariant_Hvar(theta_real = theta_real, par_space = par_space, n_boost = n_boost, num_prob = num_prob, n_i = n, a_i=a))
  }

  if( strategy == 3){
    return(ECI_Hvar(theta_real = theta_real, par_space = par_space, n_boost = n_boost, num_prob = num_prob, n_i = n, a_i=a))
  }


  if(strategy < 1 | strategy >4){
    return(print("Error: strategy must between 1 to 4"))
  }
}

#####################################################################
#####################################################################
#Entangled_var
#####################################################################
#####################################################################


Ent_Hvar <- function(theta_real, par_space,n_i,a_i, N_T){

#----------------------------
#Parametro desconocido
#----------------------------
theta <- theta_real
xp<-seq(par_space[1],par_space[2], length.out = 10)


#-------------------------------
#Parameters of Generator
#-------------------------------
#n1 <- 1/sqrt(3)
#n2 <- 1/sqrt(3)
#n3 <- 1/sqrt(3)
n <- n_i


#----------------------------------
#Parameters of state
#----------------------------------
#a1 <- 1/sqrt(2)
#a2 <- 0
#a3 <- -1/sqrt(2)

#a1 <- (3*sqrt(5)+sqrt(3))/12
#a2 <- -(3*sqrt(5)-sqrt(3))/12
#a3 <- 1/sqrt(3)
a <- a_i

MatofpbJ <- Matrix_Prob_J(n,a)
eilam <- function(x,t,m) {complex(real = cos(m*(x-t)), imaginary = -sin(m*(x-t)))}

#------------------------------
#Function of Variance
#------------------------------

HVAR <- function(NM) {

  PSn <- ConvNb(MatofpbJ,NM)

  creat_eilam <- function(i){
    ei_out <- function(x,t) {eilam(x=x, t=t,m=i)*sqrt(PSn[,2][i])}
  }
  Sumandos <- lapply(1:length(PSn[,2]), creat_eilam)

  SP <- sumfctb2(Sumandos, length(Sumandos))

  ProbSN <- function(x) {pracma::Real ((1/(2*pi))*(SP(x,t=theta)*Conj(SP(x,t=theta))))   }

  #plot(xp, ProbSN(xp), type = "l")
  VecPSN <- Vectorize(ProbSN)

  sharp <- function(x) {complex(real = cos(x), imaginary = sin(x))*VecPSN(x)}
  HVar <- pracma::Real(1/((pracma::integral(sharp,xmin=0,xmax=2*pi,abstol = 1e-10))*Conj((pracma::integral(sharp,xmin=0,xmax=2*pi,abstol = 1e-10)))) -1)
  Hvariances <- HVar*NM
  return(Hvariances)
}


return(HVAR(N_T))

}










