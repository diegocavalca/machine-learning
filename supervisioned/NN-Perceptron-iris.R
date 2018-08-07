# Função de treinamento
perceptron.treino <- function(dados, pesos){
  # Taxa de aprendizado
  n <- 0.3
  
  # Variáveis de controle
  erro <- 1 # Treinar rede enquanto erro = 1 (condicao de parada, erro = 0 => 100% de acerto)
  epoca <- 0
  
  while(erro== 1){
    erro <- 0
    epoca <- epoca + 1
    cat("\nEpoca: ", epoca)
    erroMedio <- 0 # Erro médio p/ a época
    for(i in 1:nrow(dados)){
      
      v <- 0 # Potencial de ativação (produto interno Sum_i(Wi+Xi))
      for(j in 1:length(pesos)){
        v <- v + pesos[j]*dados[i, j]  
      }
      
      # Função Sinal
      y <- sign(v)
      erroMedio <- erroMedio + (dados[i,4]-y)*(dados[i,4]-y)
      
      # Atualizaçῶao dos pesos
      if(dados[i,4] != y){
        erro <- 1
        # Ajuste dos pesos em função do erro/amostra
        for(j in 1:length(pesos)){
          pesos[j] <- pesos[j] + n*(dados[i,4]-y)*dados[i, j]
        }
      }
      
    }
    erroMedio <- erroMedio/nrow(dados)
    cat("\nErro Medio: ", erroMedio)
  }
  cat("\nFinalizado com ", epoca," epocas")
  return(pesos)
}

# Função de teste
perceptron.teste <- function(pesos, dado){
  # Produto interno
  #v <- pesos %*% dado
  v <- 0
  for(i in 1:length(pesos)){
    v <- v + pesos[i]*dado[i]
  }
  y <- sign(v) # Ativação
  return(y)
}

# Conjunto de dados (valores das variaveis Xi)
x <- cbind(iris$Sepal.Width, iris$Petal.Width)
y <- ifelse(iris$Species == "setosa", 1, -1)
bias <- rep(1, nrow(x))
x <- cbind(x, bias, y)

# Pesos iniciais (aleatórios)
pesos <- runif(3, -1, 1)
pesos <- t(pesos) # Transposto (estrutura matricial, p/ indexação)

# Treinando a rede
novos.pesos <- perceptron.treino(x, pesos)

# Plotando dados
plot(x, cex=2)
points(subset(x, y==1), col="black", pch="+",cex=2)
points(subset(x, y==-1), col="red", pch="-", cex=2)
# Hiperplanos
intersecao <- -novos.pesos[3]/novos.pesos[2]
coef.angular <- -novos.pesos[1]/novos.pesos[2]
abline(intersecao, coef.angular, col="green") 


# Classificando novos dados
amostra <- c(2.5,0.3,1)
y_ <- perceptron.teste(amostra, novos.pesos)
cat("\nNova amostra #1: ", y_)
amostra <- c(2.5,0.3,1)
y_ <- perceptron.teste(c(2.5,0.5,1), novos.pesos)
cat("\nNova amostra #2: ", y_)
