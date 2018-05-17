# OffensiveLanguageDetectorNLP

code and summary report for an example predictive model developed using R and [MonkeyLearn](https://monkeylearn.com/) which detects offensive language and hate speech in social signals (tweets).

# Contents:

- NLPTest.html: Summary report which contains the exploratory analysis, evaluation results, and answers to the research questions, in HTML formal.

- NLP Test.pdf: a PDF version of the summary report. 

- NLPTest.Rmd: R Markdown that is used to generate the NLPTest.html summary report.

- EvaluateTriedModels.R: R script used to evaluate the tried models implemented as a service (further explained in the report).

- ComputePredictionsUnlabeled.R: R script used to classify the unlabeled data using the selected model implemented as a service (further explained in the report).

- UnlabeledDataPredictions.csv: CSV file contains the IDs of the unlabeled tweets as well as their predicted labels and prediction probabilities.

- df_tweets_for_training.csv, df_tweets_for_testing.csv: CSV files of the training / testing portions of the labeled data used for modelling / evaluation.

- *.Rda: R objects (six files) containing the classifications of the testing data for the evaluation of the tried models.

- triedModels: Folder containing evaluation metrics (e.g. confusion matrices) for the tried models, as PNG images.
