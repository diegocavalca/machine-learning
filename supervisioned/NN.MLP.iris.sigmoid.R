require(nnet) # biblioteca pra codificar multiplas classes (binario)

# Função de Ativaçao (sigmoidal)
funcao.ativacao <- function(v){
  y <- 1/(1 + exp(-v))
  return(y)
}

# Derivada da funçao de ativação
der.funcao.ativacao <- function(y){
  derivada <- y * (1-y)
  return(derivada)
} 

# Arquitetura da MLP: Incluido valores default, de acordo com problema Iris
arquitetura <- function(num.entrada = 4, num.escondida = 2, num.saida = 3, 
                        funcao.ativacao = funcao.ativacao, der.funcao.ativacao = der.funcao.ativacao){
  arq = list()
  arq$num.entrada <- num.entrada
  arq$num.escondida <- num.escondida
  arq$num.saida <- num.saida
  arq$funcao.ativacao <- funcao.ativacao
  arq$der.funcao.ativacao <- der.funcao.ativacao
  
  # Arquitetura geral MLP:
  # Num. neuronios x ( 4 atributos + bias) x 3 outputs
  # Neur.   Ent1  Ent2  Ent3  Ent4  Bias
  #  1      w11   w12   w13   w14   w15
  #  2      w21   w22   w23   w24   w25
  #  3      w31   w32   w33   w34   w35
  
  # Pesos conectando a camada de entrada com a escondida
  num.pesos.entrada.escondidas <- (num.entrada + 1) * num.escondida
  # Camadas escondidas
  arq$escondida <- matrix(runif(min = -0.5, max = 0.5, num.pesos.entrada.escondidas), # Valores aleatorios
                          nrow = num.escondida, 
                          ncol = num.entrada + 1 )
  
  # Pesos conectando a camada escondida com a saida
  num.pesos.escondida.saida <- (num.escondida  + 1) * num.saida
  # Camada de saida
  arq$saida <- matrix(runif(min = -0.5, max = 0.5, num.pesos.escondida.saida),
                      nrow = num.saida, 
                      ncol = num.escondida + 1)
  
  return(arq)
}

# Propagacao
mlp.propagacao <- function(arq, exemplo){

  # Camada de Entrada >- escondida
  v.entrada.escondida <- arq$escondida %*% as.numeric(c(exemplo, 1)) # Exemplo COM bias
  y.entrada.escondida <-arq$funcao.ativacao(v.entrada.escondida)
  
  # Camada Escondida >- Saida
  v.escondida.saida <- arq$saida %*% as.numeric(c(y.entrada.escondida, 1))
  y.escondida.saida <- arq$funcao.ativacao(v.escondida.saida)
  
  resultados <- list()
  resultados$v.entrada.escondida <- v.entrada.escondida
  resultados$y.entrada.escondida <- y.entrada.escondida
  resultados$v.escondida.saida <- v.escondida.saida
  resultados$y.escondida.saida <- y.escondida.saida
  
  return(resultados)
}

# Fase de retropropagação: inserido valores default
mlp.retropropagacao <-function(arq, dados.treino, taxa.aprendizado = 0.1, limiar.parada = 1e-3) {

  erroQuadratico <- 2 * limiar.parada
  epocas <- 0 # Passar TODOS exemplos pela rede
  
  # Treina eqto ERRO > LIMIAR
  while (erroQuadratico > limiar.parada){
    
    erroQuadratico <- 0 # Atualizar na epoca
    
    # Treino sob todos exemplos
    for(i in 1:nrow(dados.treino)){
    
      # Exemplo i de treino
      x.entrada <- dados.treino[i, 1:arq$num.entrada]
      x.saida <- as.numeric(dados.treino[i, (arq$num.entrada +1 ):ncol(dados.treino) ]) # OBS: Captura o vetor binario referente as 3 classes do problema

      # # Calcular saida da rede para o exemplo
      resultado <- mlp.propagacao(arq, x.entrada)
      y <- resultado$y.escondida.saida
      
      # # OBS: Atualiza o calculo do erro a partir de saida multiplas classes
      erro <- x.saida - y
      
      # Calculando erro quadrático
      erroQuadratico <- erroQuadratico + sum(erro ^ 2) # OBS: Faz o somatorio do erro pras 3 classes
      
      # 1) Regra de apendizagem da camada de saida:
      #    gradiente_saida = (Yp - Op) * der.fun.ativ(camada)
      # Portando:
      #    w(t+1) = w(t) - eta * dE2_dw # Erro quadratico no sentido de W
      #  onde ...
      #    dE_dw = gradiente_saida * i_pj # Gradiente x Entradas j
      #
      # Calculando gradiente da camada de saída para a escondida
      gradiente.local.saida <- erro * arq$der.funcao.ativacao(y)
      
      # 2) Regra de apendizagem da camada escondida:
      #   gradiente_escondida = der.fun.ativ(camada) * sum(gradiente_o * pesos_saida)
      # Portanto:
      #   w(t+1) = w(t) - eta * gradiente_escondida * amostra
      #
      # Calculando gradiente da camada escondida para a entrada
      pesos.saida <- arq$saida[, 1:arq$num.escondida]
      gradiente.local.escondida <- as.numeric( arq$der.funcao.ativacao(resultado$y.entrada.escondida) ) * 
                               ( as.numeric(gradiente.local.saida) %*% pesos.saida) # OBS
      
      # Ajustando os pesos na rede
      # Camada de Saida
      arq$saida <- arq$saida + 
      taxa.aprendizado * ( gradiente.local.saida %*% c(resultado$y.entrada.escondida, 1) ) 
      
      # Camada Escondida
      arq$escondida <- arq$escondida + 
      taxa.aprendizado * ( t(gradiente.local.escondida) %*% as.numeric(c(x.entrada, 1)) )
      
    }
    
    erroQuadratico <- erroQuadratico / nrow(dados.treino)
    cat("EQM = ", erroQuadratico, "\n")
    epocas <- epocas + 1
  }
  
  modelo <- list()
  modelo$arq <- arq
  modelo$epocas <- epocas
  
  return(modelo)
}

# Carregando e pre-processando dados do problema Iris
dataset <- cbind(iris[, 1:4], class.ind(iris[,5])) # OBS: a função class.ind (pacote nnet) codifica a classe original do problema em um vetor (3x1) binario
# Ex.: 
# setosa =====> (1 0 0)
# versicolor => (0 1 0)
# virginica ==> (0 0 1)

# Dividindo aleatoriamente os dados em conjuntos de treino/teste
ids <- sample(1:nrow(dataset), size = 75)
treino <- dataset[ids,]
teste <- dataset[-ids,]

# Instanciando uma arquitetura de MLP com:
# - 4 neuronios na camada de entrada (Iris attrs.)
# - 3 neuronios na camada escondida 
# - 3 neuronios na camada de saida (1 pra cada classe do dataset 'iris')
arq <- arquitetura(4, 3, 3, funcao.ativacao, der.funcao.ativacao) 

# Calibrando o modelo (treinamento da rede)
modelo <- mlp.retropropagacao(arq, treino, 0.1, 0.05)

# Avaliando o modelo com o conjunto de teste
R <- NULL
for(i in 1:nrow(teste)){
  R <- rbind(R, 
             t(round( mlp.propagacao(modelo$arq, as.numeric(teste[i, 1:4]))$y.escondida.saida )) )
}
erros <- sum(sign( 3 - rowSums( teste[,5:7] == R ) ))/nrow(teste)
acertos <- (1-erros) * 100
cat("\nTaxa de acerto (teste): ", acertos, "%\n" )

cat('\nTestando modelo com uma amostra de cada classe')
# 1) Setosa
cat('\n->Setosa')
exemplo_setosa <- teste[teste$setosa == 1, ][1, ]
y_predito <- t(round( mlp.propagacao(modelo$arq, as.numeric(exemplo_setosa[1:4]))$y.escondida.saida ))
status <- all(y_predito == as.numeric(exemplo_setosa[5:7]))
cat('\nPredito: ', y_predito )
cat('\nCorreto? ', status )

# 2) Versicolor
cat('\n-> Versicolor')
exemplo_versicolor <- teste[teste$versicolor == 1, ][1, ]
y_predito <- t(round( mlp.propagacao(modelo$arq, as.numeric(exemplo_versicolor[1:4]))$y.escondida.saida ))
status <- all(y_predito == as.numeric(exemplo_versicolor[5:7]))
cat('\nPredito: ', y_predito )
cat('\nCorreto? ', status ) 

# 3) Virginica
cat('\n-> Virginica')
exemplo_virginica <- teste[teste$virginica == 1, ][1, ]
y_predito <- t(round( mlp.propagacao(modelo$arq, as.numeric(exemplo_virginica[1:4]))$y.escondida.saida ))
status <- all(y_predito == as.numeric(exemplo_virginica[5:7]))
cat('\nPredito: ', y_predito )
cat('\nCorreto? ', status )

cat('\n\nAluno: Diego Luiz Cavalca')