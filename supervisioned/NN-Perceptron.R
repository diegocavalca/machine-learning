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
x1 <- c(4,2,5,3,1.5,2.5,4,5,1.5,3,5,4)
x2 <- c(5,4.5,4.5,4,3,3,3,3,1.5,2,1.5,1)
bias <- c(1,1,1,1,1,1,1,1,1,1,1,1)
classe <- c(1,-1,1,1,-1,-1,1,1,-1,-1,1,-1)
dados <- data.frame(x1,x2, bias, classe)

# Pesos iniciais (aleatórios)
pesos <- runif(3, -1, 1)
pesos <- t(pesos) # Transposto (estrutura matricial, p/ indexação)

# Treinando a rede
novos.pesos <- perceptron.treino(dados, pesos)

# Plotando dados
cores <- dados$classe
cores[cores==-1] <- 2
plot(x1,x2,col=cores,pch=ifelse(dados$classe>0,"+","-"), cex=2, lwd=2)
# Hiperplano
intersecao <- -novos.pesos[3]/novos.pesos[2]
coef.angular <- -novos.pesos[1]/novos.pesos[2]
abline(intersecao, coef.angular, col="green") 

# Testando a 'rede'
exemplo <- c(3.5,2,1)
y_ <- perceptron.teste(novos.pesos, exemplo)
#plot(exemplo[1], exemplo[2], col="blue", pch="*")
cat("\nTeste: ", exemplo," / Classe: ", y_)