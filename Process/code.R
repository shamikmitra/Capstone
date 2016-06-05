#--------------------------------------------------------------------------------------#
# WARNING: THIS FILE CONTAINS CODE FOR THE COURSERA DATA SCIENCE CAPSTONE PROJECT      #
#          IF YOU HAVE NOT COMPLETED THE PROJECT YOURSELF AND INTEND TO DO SO, THEN    #
#          DO NOT READ THIS FILE AS IT WILL VIOLATE THE HONOR CODE. IF YOU HAVE        #
#          ALREADY COMPLETED THE PROJECT AND/OR WANT TO READ THIS FOR ACADAMEIC        #
#          REASONS, GO ON ....                                                         #
#--------------------------------------------------------------------------------------#


#      This is the script used to process the input text files and create the final
#      nGram table that will be used in predicting the next word.
#      
#      Date            Developer           Comments
#      2016 June 5     Shamik Mitra        Final Version

options(java.parameters = "-Xmx4g")
setwd("Z:/Project/")
NumOfBreaks <- 1000

library(NLP)
library(tm)
library(RWeka)
library(ngram)
library(stringi)
library(stringr)
library(mailR)

# Define a generic email function that can be used to send emails at key points of the email
SendStatusEmail <- function(mytitle, mymailbody) {
  send.mail(from = "xxx@xxx.com",
            to = c("xxx@xxx.com"),
            subject = mytitle,
            body = mymailbody,
            smtp = list(host.name = "smtp.xxx.xxx", port = 465, 
                        user.name = "xxx@xxx.com",
                        passwd = "xxx", ssl = TRUE),
            authenticate = TRUE,
            send = TRUE)
}

#------------------------------------- Step 1 -------------------------------------#
# Read the files, combine them into one large input string
cat(paste("Step 1: Reading input files",Sys.time()))
en_blogs_lines <- as.character(readLines("Data/1.Input/en_US.blogs.txt"))
en_news_lines <- as.character(readLines("Data/1.Input/en_US.news.txt"))
en_twitter_lines <- as.character(readLines("Data/1.Input/en_US.twitter.txt"))
en_lines <- paste(en_blogs_lines, en_news_lines, en_twitter_lines, collapse = ".")
rm(en_blogs_lines)
rm(en_news_lines)
rm(en_twitter_lines)
SendStatusEmail <- function("Job Status - Step 1 complete", "Input files read")

#------------------------------------- Step 2 -------------------------------------#
# Clean lines
cat(paste("\nStep 2: Cleaning input",Sys.time()))
en_lines <- unlist(strsplit(en_lines, split = ".", fixed = TRUE))
en_lines <- unlist(strsplit(en_lines, split = "!", fixed = TRUE))
en_lines <- unlist(strsplit(en_lines, split = ":", fixed = TRUE))
en_lines <- unlist(strsplit(en_lines, split = ";", fixed = TRUE))
en_lines <- unlist(strsplit(en_lines, split = '"', fixed = TRUE))
en_lines <- gsub("\\d","",en_lines)
en_lines <- gsub("    "," ",en_lines)
en_lines <- gsub("   "," ",en_lines)
en_lines <- gsub("  "," ",en_lines)
en_lines <- gsub("[^[:alnum:]///' ]", "", en_lines)
en_lines <- gsub(intToUtf8(226),intToUtf8(39), en_lines)
en_lines <- stri_trans_tolower(en_lines)
en_lines <- en_lines[!en_lines %in% c(" ","")]
en_lines <- str_replace_all(en_lines,"[[:punct:]]","")
en_lines <- str_trim(en_lines, side = "both")
SendStatusEmail <- function("Job Status - Step 2 complete", "Input has been cleaned")

#------------------------------------- Step 3 -------------------------------------#
# Break the line and save it in separate lines
cat(paste("\nStep 3: Breaking the input into multiple files",Sys.time()))
StartLine <- 1
FileLines <- round(length(en_lines)/NumOfBreaks,0)
pb <- txtProgressBar(min = 0, max = NumOfBreaks, initial = 0, style = 3)
for(i in 1:NumOfBreaks) {
  if(i==NumOfBreaks) EndLine <- length(en_lines)
  else EndLine <- StartLine + FileLines - 1
  writeLines(en_lines[StartLine:EndLine], paste("Data/2.BrokenText/",as.character(i),".txt", sep = ""))
  StartLine <- EndLine + 1
  setTxtProgressBar(pb, i)
}
close(pb)
rm(en_lines)
SendStatusEmail <- function("Job Status - Step 3 complete", "Files have been split")

#------------------------------------- Step 4 -------------------------------------#
# Create TermDocumentMatrix for each of the separate files, convert them into matrices and then save them into a separate file
cat(paste("\nStep 4: Creating TermDocumentMatrix for each file",Sys.time()))
Tokenizer <- function(x) NGramTokenizer(x, Weka_control(min = 2, max = 5))
badwords <- str_trim(readLines("Data/badwords.txt"), side = "both")
cat(paste("Start", Sys.time()))
for(i in StartPos:EndPos) {
  cat(paste("\n",as.character(i)))
  inputText <- readLines(paste("Data/2.BrokenText/",as.character(i),".txt", sep = ""))
  en_corpus <- Corpus(VectorSource(inputText))
  en_corpus <- tm_map(en_corpus, removeWords, badwords)
  tdm <- TermDocumentMatrix(en_corpus, control = list(tokenize = Tokenizer))
  tdm <- as.matrix(tdm)
  tdm <- rowSums(tdm)
  write.csv(tdm, paste("Data/3.TDMFiles/",as.character(i),".csv", sep = ""))
}
rm(inputText)
rm(en_corpus)
rm(tdm)
SendStatusEmail <- function("Job Status - Step 4 complete", "Each file has been converted to nGrams")

#------------------------------------- Step 5 -------------------------------------#
# Combining all the files into one and create a combined csv file
cat(paste("\nStep 5: Combining individual TDM files",Sys.time()))
pb <- txtProgressBar(min = 1, max = (EndPos - StartPos + 1), initial = 1, style = 3)
TDMFile <- as.data.frame(read.csv(paste("Data/3.TDMFiles/",StartPos,".csv",sep=""), stringsAsFactors=FALSE), stringsAsFactors=FALSE)
names(TDMFile) <- c("nGram","Count")
setTxtProgressBar(pb, 1)

for(i in 2:NumOfBreaks) {
  TDMSubFile <- read.csv(paste("Data/3.TDMFiles/",i,".csv",sep=""), stringsAsFactors=FALSE)
  names(TDMSubFile) <- c("nGram","Count")
  TDMFile <- rbind(TDMFile, TDMSubFile)
  setTxtProgressBar(pb, i)
}
write.csv(TDMFile, paste("Data/4.SemiCombinedTDMFiles/1.csv", sep = ""), row.names = FALSE)
SendStatusEmail <- function("Job Status - Step 5 complete", "Split files have been combined back")

#------------------------------------- Step 6 -------------------------------------#
# Since the files had been split, there could be duplicate nGrams. Go through all the
# nGrams in the combined file and combine the duplicates
cat(paste("\nStep 6: Combining rows"),Sys.time()))
pb <- txtProgressBar(min = 0, max = (nrow(TDMFile)-1), initial = 0, style = 3)
for(j in 1:(nrow(TDMFile)-1)) {
  if(TDMFile$nGram[j]==TDMFile$nGram[j+1]) {
    TDMFile$Count[j+1] <- TDMFile$Count[j+1] + TDMFile$Count[j]
    TDMFile$Count[j] <- 0
  }
  setTxtProgressBar(pb, j)
}
TDMFile <- TDMFile[!TDMFile$Count==0,]
SendStatusEmail <- function("Job Status - Step 6 complete", "Duplicate nGrams combined")

#------------------------------------- Step 7 -------------------------------------#
#Split last word out into a separate column
cat(paste("\nStep 7: Splitting last word"),Sys.time()))
pb <- txtProgressBar(min = 0, max = nrow(TDMFile), initial = 0, style = 3)
for(j in 1:nrow(TDMFile)) {
  FullWord <- TDMFile$nGram[j]
  NumOfWords <- str_count(FullWord, " ") + 1
  TDMFile$nGram[j] <- paste(unlist(strsplit(FullWord, " ", fixed=TRUE))[1:(NumOfWords-1)],collapse = " ")
  TDMFile$NextWord[j] <- unlist(strsplit(FullWord, " ", fixed = TRUE))[NumOfWords]
  setTxtProgressBar(pb, j)
}
SendStatusEmail <- function("Job Status - Step 7 complete", "Last word split")

#------------------------------------- Step 8 -------------------------------------#
#The final product only needs to make 3 suggestions. If a particular nGram has more than 3
#NextWords, then they will never be used. Remove those lines to reduce file size
cat(paste("\nStep 8: Sorting data frame"),Sys.time()))
TDMFile <- TDMFile[order(TDMFile$nGram, -TDMFile$Count),]
cat("\nDeleting additional suggestions\n")
pb <- txtProgressBar(min = 1, max = nrow(TDMFile), initial = 1, style = 3)
NumOfNgrams <- 1
for(j in 2:nrow(TDMFile)) {
  if(TDMFile$nGram[j]==TDMFile$nGram[j-1]) {
    NumOfNgrams <- NumOfNgrams + 1
    if(NumOfNgrams>3) TDMFile$Count[j] <- 0
  }
  else {
    NumOfNgrams <- 1
  }
  setTxtProgressBar(pb, j)
}
TDMFile <- TDMFile[!TDMFile$Count==0,]
SendStatusEmail <- function("Job Status - Step 8 complete", "More than 3 suggestions deleted")
  
#------------------------------------- Step 9 -------------------------------------#
#Write the final output into a file to be used by the application
cat(paste("\nStep 9: Writing file to disk"),Sys.time()))
write.csv(TDMFile, "nGrams.csv", row.names = FALSE)
SendStatusEmail <- function("Job Status - Step 9 complete", "Final output saved")

#---------------------------------- End of code -----------------------------------#
