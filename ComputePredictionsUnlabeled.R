require(futile.logger)
require(tm)
library(stringr)
require(RCurl)
require(jsonlite)
library(XLConnect)
dummy <- Sys.setlocale("LC_TIME", "English_United Kingdom.1252")
dummy <- Sys.setlocale("LC_ALL", "English_United Kingdom.1252")
setwd("C:\\Users\\Ahmad\\Downloads\\hellosoda\\NLPTest")

#reading unlabeled data from .xlsx
if (exists("unlabeled")){
  rm(unlabeled)
}
unlabeled <- readWorksheetFromFile("Twitter-hate_speech-test_unlabeled.xlsx", sheet=1, header = TRUE)

if (dim(unlabeled)[1] > 0)
{
  unlabeled$tweet_text <- sapply(unlabeled$tweet_text,function(row) iconv(row, "latin1", "ASCII", sub=""))
}

#generate a regex-based text-preprocessed version of the tweets. 
#If the preprocessed version has 0 chars, consider the original tweet
df_unlabeled_tweets = data.frame(
  id = integer(0),
  original = character(0),
  text = character(0),
  stringsAsFactors=F
)
punct <- '[]\\?#!"£$%&(){}+*/:;,._`|~\\[<=>\\^-]'
for (i in 1:nrow(unlabeled)) {
  x <- unlabeled[i,]$tweet_text
  x <- str_replace_all(x,"[^[:graph:]]", " ")
  x <- gsub("(f|ht)tp(s?)://(.*)[.][a-zA-Z]+/([a-zA-Z0-9]*)?", " ", x)
  x <- gsub('[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}'," ", x, perl=T)
  x <- gsub(punct, " ", x, perl=T)
  x <- gsub("@[a-zA-Z0-9]+"," ", x, perl=T)
  x <- gsub("\\s+", " ", x)
  x <- gsub("^ ", " ", x, perl=T)
  x <- gsub(" $", " ", x, perl=T)
  x_list <- strsplit(x, " ")
  x_vec <- unlist(x_list)
  x_vec <- x_vec[sapply(x_vec,nchar) > 1]
  encodings <- Encoding(x_vec)
  x_enc <- iconv(x_vec, "latin1", "ASCII", sub=NA)
  x_enc_nn <- x_enc[!is.na(x_enc)]
  sentence <- paste(x_enc_nn, sep="", collapse=" ")
  if (nchar(sentence) == 0) {
    sentence <- unlabeled[i,]$tweet_text
  }
  df_unlabeled_tweets <- rbind(df_unlabeled_tweets, data.frame(
                                                              id = unlabeled[i,]$id,
                                                              original = unlabeled[i,]$tweet_text,
                                                              text=sentence, 
                                                              stringsAsFactors=FALSE
                                                              )
                              )
}
df_unlabeled_tweets$no <- seq.int(nrow(df_unlabeled_tweets))
rownames(df_unlabeled_tweets) = 1:nrow(df_unlabeled_tweets)
df_unlabeled_tweets$predictedClass <- rep("",nrow(df_unlabeled_tweets))
df_unlabeled_tweets$predictedClassProb <- rep(0.0,nrow(df_unlabeled_tweets))

#Classify the unlabeled data (text column) through the MonkeyLearn API using the selected model
#classifier Name: NLPTest
#classifier URL: https://app.monkeylearn.com/main/classifiers/XXX/tab/tree-sandbox
#Classifer_ID: XXX
#Authorization: Token XXX
#Service endpoint URL: https://api.monkeylearn.com/v2/classifiers/XXX/classify/?sandbox=1
#send 200 tweets with every request (Free version usage limit)
#sleep for 65 seconds every 4000 classifications (Free version usage limit)

classifications <- data.frame(
  predictedClass = character(0),
  predictedClassProb = numeric(0),
  stringsAsFactors = F
)
tweets <- character(0)
for (i in 1:nrow(df_unlabeled_tweets)) {
  if (i %% 200 == 0 | i == nrow(df_unlabeled_tweets)) {
    tweets <- c(tweets, df_unlabeled_tweets[df_unlabeled_tweets$no == i,c("text")])
    x= list(text_list=tweets)
    headers <- list('Authorization' = "XXX", 
                    'Content-Type' = 'application/json')
    response <- postForm("https://api.monkeylearn.com/v2/classifiers/XXX/classify/?sandbox=1", 
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
    flog.info("No of tweets classified: %s (%s)", i, round(i/nrow(df_unlabeled_tweets) * 100.00, 2))
    if (i %% 4000 == 0) {
      flog.info("Sleeping for 65 seconds...")
      Sys.sleep(65)
    }
  } else {
    tweets <- c(tweets, df_unlabeled_tweets[df_unlabeled_tweets$no == i,c("text")])
  }
}

# Fill the data table with the classifications

for (i in 1:nrow(df_unlabeled_tweets)) {
  df_unlabeled_tweets$predictedClass[i] <- classifications$predictedClass[i]
  df_unlabeled_tweets$predictedClassProb[i] <- classifications$predictedClassProb[i]
}

# Save the unlabeled data frame with the predictions and prediction probabilities obtained by the model
write.table(df_unlabeled_tweets[,c("id", "predictedClass","predictedClassProb")], file = "UnlabeledDataPredictions.csv", 
            quote = FALSE, sep = ",", row.names = FALSE, fileEncoding = "utf8")



