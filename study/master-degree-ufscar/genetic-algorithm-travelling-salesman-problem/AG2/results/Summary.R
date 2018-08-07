setwd('~/Documentos/MEGA/Pessoal/Estudos/Mestrado/CCO-727 Otimização Inteligente de Sistemas Produtivos/Trabalho 1 - TSP/')
  
dataset = read.csv("tests/Summary.csv", header = TRUE, sep = ";")

summary(dataset[,5:7])

# Relacao entre pares de caracteristicas...
pairs(dataset[,4:7])

# Desvio padrao
sd(dataset$BESTROUTE)

# Matriz de covariancia
cov(data.matrix(dataset[,4:7]))

# Gráfico de distribuicao
h<-hist(dataset$BESTROUTE, breaks=50, col="grey", xlab="Resultado", ylab ='Frquência',
        main='Distribuição dos resultados') 
xfit<-seq(min(dataset$BESTROUTE),max(dataset$BESTROUTE),length=40) 
yfit<-dnorm(xfit,mean=mean(dataset$BESTROUTE),sd=sd(dataset$BESTROUTE)) 
yfit <- yfit*diff(h$mids[1:2])*length(dataset$BESTROUTE) 
lines(xfit, yfit, col="blue", lwd=2)
abline(v = median(dataset$BESTROUTE), col = "red") # Mediana
abline(v = mean(dataset$BESTROUTE), col = "green") # Media