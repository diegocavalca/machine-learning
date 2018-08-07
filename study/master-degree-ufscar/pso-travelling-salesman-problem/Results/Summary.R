#setwd('~/Documentos/MEGA/Pessoal/Estudos/Mestrado/CCO-727 Otimização Inteligente de Sistemas Produtivos/Trabalho 1 - TSP/')
setwd('/Volumes/Toshiba/Github/mestrado/CCO-727/Trabalho2-PSO_TSP/Results/')  
dataset = read.csv("Summary.csv", header = TRUE, sep = ";")

# Comportamento geral dos dados em relacao aos atributos 10 e 11
summary(dataset[,10:11])

# Minima Rota
minResult <- dataset[dataset$BESTROUTE == min(dataset$BESTROUTE),]

# Quantile
qtResult <- quantile(dataset$BESTROUTE) 

# Relacao entre pares de caracteristicas (influencia e correlacao)...
pairs(dataset[,6:10])
library(ggplot2)
library(GGally)
customBin <- function(data, mapping, ..., low = "#132B43", high = "red") {
  ggplot(data = data, mapping = mapping) +
    geom_bin2d(...) +
    scale_fill_gradient(low = low, high = high)
}
pairsResult <- ggpairs(
  dataset[,6:10], 
  columnLabels = c("W", "C1", "C2", "Cpr", "BestRoute"),
  lower = list(
    continuous = customBin
  ),
  title = "Correlação de parâmetros com 'BestRoute'"
) #+ theme_bw()
pairsResult


# Desvio padrao / Media
sdResult <- sd(dataset$BESTROUTE)
meanResult <- mean(dataset$BESTROUTE)

# Matriz de covariancia
cov(data.matrix(dataset[,4:7]))

# Gráfico de distribuicao
h<-hist(dataset$BESTROUTE, breaks=50, col="grey", xlab="Resultado", ylab ='Frquência',
        main='Distribuição dos resultados') 
xfit<-seq(min(dataset$BESTROUTE), max(dataset$BESTROUTE),length=40) 
yfit<-dnorm(xfit, mean=meanResult, sd=sdResult) 
yfit <- yfit*diff(h$mids[1:2])*length(dataset$BESTROUTE) 
lines(xfit, yfit, col="blue", lwd=2)
abline(v = median(dataset$BESTROUTE), col = "red") # Mediana
abline(v = mean(dataset$BESTROUTE), col = "green") # Media

# Distribuição de probabilidades com base nos dados
#library(ggplot2)
#ggplot(
#  data.frame(x = c(350, 550)), aes(x)) +
#  stat_function(fun = dnorm, args = list(mean = meanResult, sd = sdResult)) +
#  xlab('Resultado') +
#  ylab('Probabilidade') +
#  geom_vline(xintercept = meanResult, colour="green") + # Media
#  geom_vline(xintercept = (meanResult - (2*sdResult)), colour="blue", linetype = "longdash") + # 95% (Media - 2*Sd)
#  geom_vline(xintercept = (meanResult + (2*sdResult)), colour="blue", linetype = "longdash") # 95% (Media + 2*Sd)

#library(xtable)
#xtable(dataset[dataset$BESTROUTE == min(dataset$BESTROUTE),])
#dataset[dataset$BESTROUTE == min(dataset$BESTROUTE),]
