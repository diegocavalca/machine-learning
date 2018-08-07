# Arquitetura
#camada.entrada <- 4
#camada.oculta <- 6
#W <- 0.01*matrix(rnorm(camada.entrada * camada.oculta),
#                        nrow=camada.entrada,
#                        ncol=camada.oculta)
#b <- matrix(0, nrow=1, ncol = camada.oculta)
# Referencias:
# - Softmax e Entropia Cruzada: 
# - - - https://eli.thegreenplace.net/2016/the-softmax-function-and-its-derivative/
# - - - http://gluon.mxnet.io/chapter03_deep-neural-networks/mlp-scratch.html
# - - - https://beckernick.github.io/neural-network-scratch/

mlp.pred <- function(model, data = X.test) {
  # new data, transfer to matrix
  new.data <- data.matrix(data)
  
  # Feed Forwad
  hidden.layer <- sweep(new.data %*% model$W1 ,2, model$b1, '+')
  # neurons : Rectified Linear
  hidden.layer <- pmax(hidden.layer, 0)
  score <- sweep(hidden.layer %*% model$W2, 2, model$b2, '+')
  
  # Loss Function: softmax
  score.exp <- exp(score)
  probs <-sweep(score.exp, 1, rowSums(score.exp), '/') 
  
  # select max possiblity
  labels.predicted <- max.col(probs)
  return(labels.predicted)
}

# Train: build and train a 2-layers neural network 
mlp.treino <- function(dados.treino = data, dados.teste = NULL,
                      # set hidden layers and neurons
                      # currently, only support 1 hidden layer
                      neuronios.camada.oculta = c(6), 
                      # max iteration steps
                      maxit = 2000,
                      # delta loss 
                      abstol = 1e-2,
                      # learning rate
                      lr = 1e-2,
                      # regularization rate
                      reg = 1e-3,
                      # show results every 'display' step
                      display = 100,
                      random.seed = 1)
{
  # to make the case reproducible.
  set.seed(random.seed)
  
  # Qtd. de amostras
  N <- nrow(dados.treino)
  # Extraindo os indices referentes aos atributos e classe do dataset
  atributos.qtd <- ncol(dados.treino)-1
  atributos.idx <- 1:atributos.qtd
  classe.idx <- ncol(iris)
  X <- unname(data.matrix(dados.treino[, atributos.idx])) # removendo label dos atributos (desnecessarios)
  Y <- dados.treino[, classe.idx]
  if(is.factor(Y)) { Y <- as.integer(Y) } # Converter classes (str) em numeros inteiros (calculo do erro)

  # Revisar
  classes <- length(unique(Y)) # número de classes do problema (outputs)
  Y.set   <- sort(unique(Y))
  Y.index <- cbind(1:N, match(Y, Y.set))

  # Camada de entrada: inicializando Pesos (W) e bias (b)
  # Ps.: Ponderar pesos por 0.01 a fim de potencializar a convergencia (ativacao / gradiente)
  W.entrada <- 0.01 * matrix(rnorm(atributos.qtd * neuronios.camada.oculta), 
                             nrow = atributos.qtd, ncol = neuronios.camada.oculta) 
  b.entrada <- matrix(0, nrow=1, ncol = neuronios.camada.oculta)
  
  # Camada de entrada: inicializando Pesos (W) e bias (b)
  W.oculta <- 0.01 * matrix(rnorm(neuronios.camada.oculta * classes), 
                            nrow = neuronios.camada.oculta, ncol = classes)
  b.oculta <- matrix(0, nrow = 1, ncol = classes)
  
  # init loss to a very big value
  perda <- 100000
  
  # Calibrando a MLP
  i <- 0
  while(i < maxit && perda > abstol ) {
    
    # iteration index
    i <- i +1
    
    # Propagacao
    
    # Calculo da Camada Oculta
    # 1) Potencial de ativacao: Z = W*X +b
    Z.oculta <- sweep(X %*% W.entrada, 2, b.entrada, '+') 
    # 2) Função de Ativacao: Sigma(Z) = ReLU(Z)
    Sigma.oculta <- pmax(Z.oculta, 0)  
    
    # Calculo da Camada de Saida
    # 1) Potencial de ativacao: Z = W*X +b
    Z.saida <- sweep(Sigma.oculta %*% W.oculta, 2, b.oculta, '+') 
    # 2) Função de Ativacao: Sigma'(Z) = Softmax(Z)
    Z.saida.exp <- exp(Z.saida)
    Sigma.saida <- sweep(Z.saida.exp, 1, rowSums(Z.saida.exp), '/') 
    
    # Calculo do erro (Entropia cruzada), considerando saida Softmax
    entropia.cruzada <- - sum( log(Sigma.saida[Y.index]) ) / N

    # Regularização dos pesos W (L2)
    L2.reg   <- 0.5 * reg * (sum(W.entrada * W.entrada) + sum(W.oculta * W.oculta))
    perda <- entropia.cruzada + L2.reg
    
    # Exibir erro e atualizar modelo
    if( i %% display == 0) {
      
      if(!is.null(dados.teste)) {
        modelo <- list() 
        
        modelo$W.entrada = W.entrada
        modelo$b.entrada = b.entrada
        modelo$W.oculta = W.oculta 
        modelo$b.oculta = b.oculta
        labs <- mlp.pred(modelo, dados.teste[,-y])      
        
        # updated: 10.March.2016
        accuracy <- mean(as.integer(dados.teste[,y]) == Y.set[labs])
        cat(i, perda, accuracy, "\n")
        
      } else {
        cat(i, perda, "\n")
      }
    }
    
    # Fase 2) Retropropagacao
    
    # Gradiente: Peso e bias conectados a camada de saida
    # Calculo do erro relativo
    d.saida <- Sigma.saida
    d.saida[Y.index] <- d.saida[Y.index] -1
    d.saida <- d.saida / N
    # Calculo do fator de correcao pelo gradiente
    dW.oculta <- t(Z.oculta) %*% d.saida 
    db.oculta <- colSums(d.saida)
    dW.oculta <- dW.oculta + reg * W.oculta
    
    # Gradiente: Peso e bias conectados a camada oculta
    # Calculo do erro relativo
    d.oculta <- d.saida %*% t( W.oculta )
    d.oculta[camada.oculta <= 0] <- 0
    # Calculo do fator de correcao pelo gradiente
    dW.entrada <- t(X) %*% d.oculta
    db.entrada <- colSums(d.oculta) 
    dW.entrada <- dW.entrada  + reg * W.entrada
    
    # Atualizacao dos Pesos (W) e bias (b): 
    W.entrada <- W.entrada - lr * dW.entrada
    b.entrada <- b.entrada - lr * db.entrada
    
    W.oculta <- W.oculta - lr * dW.oculta
    b.oculta <- b.oculta - lr * db.oculta
    
  }
  
  # Retornando uma lista com as informacoes do modelo final
  modelo <- list() 
  #modelo$D = D
  #modelo$H = H
  #modelo$K = K
  modelo$W.entrada = W.entrada
  modelo$b.entrada = b.entrada
  modelo$W.oculta = W.oculta 
  modelo$b.oculta = b.oculta
  
  return(modelo)
}

########################################################################
# testing
#######################################################################
set.seed(1)

# Resumo dos dados do problema
summary(iris)

# Dividir o conjunto de dados em treino/teste (amostragem aleatoria, 50%-50%)
amostras <- c(sample(1:50,25), 
              sample(51:100,25), 
              sample(101:150,25))

# Calibrando o modelo
modelo <- mlp.treino(dados.treino = iris[amostras, ], 
                     #dados.teste = iris[-amostras, ], 
                     neuronios.camada.oculta = 6, 
                     maxit = 2000, 
                     display = 50)

# 3. prediction
#labels.dnn <- predict.dnn(modelo, iris[-samp, -5])

# 4. verify the results
#table(iris[-samp,5], labels.dnn)
#          labels.dnn
#            1  2  3
#setosa     25  0  0
#versicolor  0 24  1
#virginica   0  0 25

#accuracy
#cat(mean(as.integer(iris[-samp, 5]) == labels.dnn))
# 0.98