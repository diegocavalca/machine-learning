# Função de Ativaçῶao (sigmoidal)
funcao.ativacao <- function(v){
  y <- 1/(1 + exp(-v))
  return(y)
}

# Derivada da funçῶao de ativação
der.funcao.ativacao <- function(y){
  derivada <- y * (1-y)
  return(derivada)
} 

# Arquitetura da rede (matrizes com pesos iniciais)
arquitetura <- function(num.entrada, num.escondida, num.saida, 
                        funcao.ativacao, der.funcao.ativacao){
  arq <- list()
  arq$num.entrada <- num.entrada
  arq$num.escondida <- num.escondida
  arq$num.saida <- num.saida
  arq$funcao.ativacao <- funcao.ativacao
  arq$der.funcao.ativacao <- der.funcao.ativacao
  
  # 2 neuronios + bias
  # Neur.   Ent1  Ent2  Bias
  #  1      w11   w12   w13
  #  2      w21   w22   w23
  
  # Pesos conectando a camada de entrada com a escondida
  num.pesos.entrada.escondidas <- (num.entrada + 1) * num.escondida
  # Camadas escondidas
  arq$escondida <- matrix(runif(min = -0.5, max = 0.5, num.pesos.entrada.escondidas), # Valores aleatorios
                         nrow = num.escondida, ncol = num.entrada + 1 )
  
  # Pesos conectando a camada escondida com a saida
  num.pesos.escondida.saida <- (num.escondida  + 1) * num.saida
  # Camada de saida
  arq$saida <- matrix(runif(min = -0.5, max = 0.5, num.pesos.escondida.saida),
                      nrow = num.saida, ncol = num.escondida + 1)

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

# Fase de retropropagação
mlp.retropropagacao <-function(arq, dados.treino, taxa.aprendizado, limiar.parada) {
  
  erroQuadratico <- 2*limiar.parada
  epocas <- 0 # Passar TODOS exemplos pela rede
  
  # Treina eqto ERRO > LIMIAR
  while (erroQuadratico > limiar.parada){
    
    erroQuadratico <- 0 # Atualizar na epoca
    
    # Treino sob todos exemplos
    for(i in 1:nrow(dados.treino)){
      
      # Exemplo i de treino
      x.entrada <- dados[i, 1:arq$num.entrada]
      x.saida <- dados[1, ncol(dados)]
      
      # Calcular saida da rede para o exemplo
      resultado <- mlp.propagacao(arq, x.entrada)
      y <- resultado$y.escondida.saida
      
      # Calcular o erro dos pesos para a amostra
      erro <- x.saida - y
      erroQuadratico <- erroQuadratico + erro*erro
      
      # Calcular o gradiente local do neuronio de saida
      # Erro * der.funcao.ativacao
      gradiente.local.saida <- erro * arq$der.funcao.ativacao(y)
      
      # Calcular o gradiente local dos neuronios escondidos
      # derivada.funcao.ativacao * (SOMATORIO gradientes locais * pesos)
      pesos.saida <- arq$saida[, 1:arq$num.escondida]
      gradiente.local.escondida <- as.numeric(arq$der.funcao.ativacao(resultado$y.entrada.escondida)) * (gradiente.local.saida %*% pesos.saida) 
      
      
      # Ajustando os pesos na rede
      # Camada de Saida
      arq$saida <- arq$saida + taxa.aprendizado * (gradiente.local.saida %*% c(resultado$y.entrada.escondida, 1))
      
      # Camada Escondida
      arq$escondida <- arq$escondida + taxa.aprendizado * (t(gradiente.local.escondida) %*% as.numeric(c(x.entrada, 1)))
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

arq <- arquitetura(2, 2, 1, funcao.ativacao, der.funcao.ativacao)

dados <- read.table('/Volumes/Toshiba/MEGA/Pesquisa/Doutorado/Disciplinas/CCO-726 Introdução a Redes Neurais/Códigos/XOR.txt')

# Treinamento da rede
modelo <- mlp.retropropagacao(arq, dados, 0.1, 1e-3)

# Teste
mlp.propagacao(modelo$arq, dados[1, 1:2])