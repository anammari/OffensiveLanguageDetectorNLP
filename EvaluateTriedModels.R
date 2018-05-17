require(futile.logger)
require(tm)
require(RCurl)
require(jsonlite)
dummy <- Sys.setlocale("LC_TIME", "English_United Kingdom.1252")
dummy <- Sys.setlocale("LC_ALL", "English_United Kingdom.1252")
setwd("C:\\Users\\Ahmad\\Downloads\\hellosoda\\NLPTest")

#For the first experiment only: create the training and testing datasets from the labelled preprocessed tweets
## 75% of the sample size
smp_size <- floor(0.75 * nrow(df_cleaned_tweets))

## set the seed to make your partition reproductible
set.seed(123)
train_ind <- sample(seq_len(nrow(df_cleaned_tweets)), size = smp_size)

#############################################################################
#For the first experiment only: create the train and test DFs
train <- df_cleaned_tweets[train_ind, ]
test <- df_cleaned_tweets[-train_ind, ]
#save the train and test DFs as CSV files
write.table(train[,c("text", "label")], file = "df_tweets_for_training.csv", 
            quote = TRUE, sep = ",", row.names = FALSE, fileEncoding = "utf8")

write.table(test[,c("text", "label")], file = "df_tweets_for_testing.csv", 
            quote = TRUE, sep = ",", row.names = FALSE, fileEncoding = "utf8")
##############################################################################

#train a classification model offline using the train DF on MonkeyLearn (http://www.monkeylearn.com/)
#Note: The samples limit for the free usage of monkeyLearn is 3000
#classifier Name: NLPTest
#classifier URL: https://app.monkeylearn.com/main/classifiers/cl_znZbrRDB/tab/tree-sandbox
#Classifer_ID: cl_znZbrRDB

#For every experiment, read the prepare the test DF for classification. 
rm(test)
test <- read.table(file = "df_tweets_for_testing.csv", 
                   quote = "\"'", sep = ",", header = TRUE, fileEncoding = "utf8", stringsAsFactors = FALSE)
#Remove the preprocessed tweets with 0 characters
test <- test[!nchar(test$text) == 0,]
test$no <- seq.int(nrow(test))
rownames(test) = 1:nrow(test)
test$predictedClass <- rep("",nrow(test))
test$predictedClassProb <- rep(0.0,nrow(test))

#Classify the testing dataset using the MonkeyLearn model
#send 200 tweets with every request
#sleep for 65 seconds every 4000 classifications

classifications <- data.frame(
  predictedClass = character(0),
  predictedClassProb = numeric(0),
  stringsAsFactors = F
)
tweets <- character(0)
for (i in 1:nrow(test)) {
  if (i %% 200 == 0 | i == nrow(test)) {
    tweets <- c(tweets, test[test$no == i,c("text")])
    x= list(text_list=tweets)
    headers <- list('Authorization' = "Token 607ea0e572594ce3e222c1b643b29abb539fb213", 
                    'Content-Type' = 'application/json')
    response <- postForm("https://api.monkeylearn.com/v2/classifiers/cl_znZbrRDB/classify/?sandbox=1", 
                         .opts=list(postfields=toJSON(x), httpheader=headers))
    
    responseJson <- fromJSON(response)
    
    for (j in 1:length(responseJson[[1]])) {
      classifications <- rbind(classifications, data.frame(
        predictedClass = responseJson[[1]][[j]]$label,
        predictedClassProb = responseJson[[1]][[j]]$probability,
        stringsAsFactors = FALSE
      ))
      # cat(paste0("Tweet ",j,":\n","\tLabel: ",responseJson[[1]][[j]]$label,"\tProbability: ",responseJson[[1]][[j]]$probability,"\n"))
    }
    tweets <- character(0)
    flog.info("No of tweets classified: %s (%s)", i, round(i/nrow(test) * 100.00, 2))
    if (i %% 4000 == 0) {
      flog.info("Sleeping for 65 seconds...")
      Sys.sleep(65)
    }
  } else {
    tweets <- c(tweets, test[test$no == i,c("text")])
  }
}

# Fill the data table with the classifications

for (i in 1:nrow(test)) {
  test$predictedClass[i] <- classifications$predictedClass[i]
  test$predictedClassProb[i] <- classifications$predictedClassProb[i]
}

# Save the data frame for evaluation metrics
save(test, file="classificationsSVMtriGrams.Rda")





