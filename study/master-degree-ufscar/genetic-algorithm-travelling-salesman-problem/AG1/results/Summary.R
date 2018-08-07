setwd('~/Git/mestrado/CCO-727/Trabalho1-AG_TSP/AG1/')
  
dataset = read.csv("tests/Summary.csv", header = TRUE, sep = ",")

summary(dataset)

# Relacao entre pares de caracteristicas...
pairs(dataset)

# Desvio padrao
sd(dataset$BESTROUTE)

# Matriz de covariancia
cov(data.matrix(dataset))

# Gráfico de distribuicao
h<-hist(dataset$BESTROUTE, breaks=50, col="grey", xlab="Resultado", ylab ='Frquência',
        main='Distribuição dos resultados') 
xfit<-seq(min(dataset$BESTROUTE),max(dataset$BESTROUTE),length=40) 
yfit<-dnorm(xfit,mean=mean(dataset$BESTROUTE),sd=sd(dataset$BESTROUTE)) 
yfit <- yfit*diff(h$mids[1:2])*length(dataset$BESTROUTE) 
lines(xfit, yfit, col="blue", lwd=2)
abline(v = median(dataset$BESTROUTE), col = "red") # Mediana
abline(v = mean(dataset$BESTROUTE), col = "green") # Media