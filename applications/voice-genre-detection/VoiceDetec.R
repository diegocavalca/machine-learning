
dataset <- read.csv('/Users/diegocavalca/Desktop/voice.csv', sep = ',')

# Preparing data
#label <- dataset$label
#varstrain <- !names(dataset) %in% c("label") 
#data <- data[varstrain]

# Classification Tree with rpart
library(rpart)

# grow tree 
fit <- rpart(label ~ .,
             method="class", data=dataset)

printcp(fit) # display the results 
plotcp(fit) # visualize cross-validation results 
summary(fit) # detailed summary of splits

# plot tree 
plot(fit, uniform=TRUE, 
     main="Classification Tree for Gender Voices")
text(fit, use.n=TRUE, all=TRUE, cex=.8)

# create attractive postscript plot of tree 
post(fit, file = "/Users/diegocavalca/Desktop/tree.ps", 
     title = "Classification Tree for Gender Voices")

## SVM
library(e1071)
## split data into a train and test set
index <- 1:nrow(dataset)
testindex <- sample(index, trunc(length(index)/3))
testset <- dataset[testindex,]
trainset <- dataset[-testindex,]


svm.model <- svm(label ~ ., data = trainset, cost = 100, gamma = 1)
print(svm.model)
summary(svm.model)


# test with train data
pred <- predict(svm.model, testset[,-10])
# (same as:)
pred <- fitted(svm.model)
# Check accuracy:
table(pred, trainset$label)

svm.pred <- predict(svm.model, testset[,-10])


#TUning SVM to find the best cost and gamma ..
train_x <- trainset[ , !(names(trainset) %in% c("label"))]
svm_tune <- tune(svm.model, train.x=train_x, train.y=trainset$label,
                 kernel="radial", ranges=list(cost=10^(-1:2), gamma=c(.5,1,2)))
print(svm_tune)
