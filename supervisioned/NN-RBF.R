library(corpcor)

# Definição da classe das amostras (-1 ou 1, com base em xi)
target <- function(x1, x2){
  return( 2*(x2 - x1 + 0.25*sin(pi*x1)>=0) -1 )
}
# Amostras de treino
N <- 300
X <- data.frame(x1=runif(N, min=-1, max=1),
                x2=runif(N, min=-1, max=1))
Y <- target(X$x1, X$x2)
plot(X$x1, X$x2, col = Y+3)


# Gama = variancia (gaussiana)
rbf <- function(X, Y, K=10, gama = 1.0){
  N <- dim(X)[1] # num. exemplos
  ncols <- dim(X)[2] # num colunas
  
  # Descobrindo centro dos grupos (Kmeans)
  repeat{
    km <- kmeans(X, K)
    # evitar grupo Ki vazio
    if( min(km$size) > 0 ) 
      break
  }
  
  # Calcula saida das gaussianas (cada função de base radial, conjunto PHI)
  Phi <- matrix(rep(NA, (K+1)*N), ncol = K+1)
  mus <- km$centers # Centroids dos neuronios (funcoes RB)
  # Calcular por amostra
  for(lin in 1:N){
    Phi[lin, 1] <- 1 # Bias
    # Varrer dimensoes
    for(col in 1:K){
      Phi[lin, col+1] <- exp( -(1/2*gama*gama) *
                          sum( (X[lin, ] - mus[col, ]) ^ 2 )
                        )
    }
  }
  
    # Ajustar os pesos (Oculta -> Saida)
  w <- pseudoinverse( t(Phi)%*%Phi ) %*% t(Phi) %*% Y
  
  # Arquitetura da rede
  lista <- list()
  lista$pesos <- w
  lista$gama <- gama
  lista$centros <- mus
  lista$Phi <- Phi
  
  return( lista )
}

# 
rbf.predict <- function(modelo, X, classificacao = FALSE){
  gama <- modelo$gama
  centros <- modelo$centros
  w <- modelo$pesos
  N <- dim(X)[1]
  
  # Inicilizando o vetor de resultados
  pred <- rep( w[1],  N)
  
  for(j in 1:N){
    for(k in 1:nrow(centros)){
      pred[j] <- pred[j] + w[k+1] * exp( -(1/2*(gama^2) ) *
                                           sum( (X[j, ] - centros[k, ]) ^ 2 )
                                    )
    }
  }
  
  if(classificacao == TRUE){
    pred <- unlist(lapply( pred, sign ))
    
  }
    
  return( pred )
}

# Treinando o modelo
modelo <- rbf(X, Y, 10)

# Testando o modelo RBF
# Amostras de teste
N.teste <- 100
X.out <- data.frame(x1=runif(N.teste, min=-1, max=1),
                x2=runif(N.teste, min=-1, max=1))
Y.out <- target(X.out$x1, X.out$x2)

# Classificacao do modelo
Y.pred <- rbf.predict(modelo, X.out, TRUE)

# Analise de resultados
erro.medio <- sum(Y.pred != Y.out)/N.teste

plot(X.out$x1, X.out$x2, col = Y.out + 3, pch = 0) # Verdadeiros
points(X.out$x1, X.out$x2, col = Y.pred + 3, pch = 0) # Preditos
points(modelo$centros, col = 'black', pch = 19)
legend('topleft', c('Verdadeiro', 'Predito'), pch = c(0, 3), bg = 'white')