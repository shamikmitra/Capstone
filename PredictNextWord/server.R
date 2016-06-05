library(shiny)
library(stringr)
library(stringi)

InitialLoad <- TRUE
nGrams <- read.csv("nGrams.csv", stringsAsFactors = FALSE)
ApostropheWords <- read.csv("apostrophewords.csv", stringsAsFactors = FALSE)
# Default first words
DefaultWord <- c("I","The","You")

makeNextWordSuggestions <- function(Suggested = matrix()) {
    SearchedString <- ""
    Word <- DefaultWord
    
    SuggestWords <- function(SearchString) {
        ##################### Prediction algo start #####################
        # Clean the input
        x <- SearchString
        x <- gsub("\\d","",x)
        x <- gsub("    "," ",x)
        x <- gsub("   "," ",x)
        x <- gsub("  "," ",x)
        x <- gsub(intToUtf8(226),intToUtf8(39), x)
        x <- unlist(strsplit(x, split = ".", fixed = TRUE))
        x <- unlist(strsplit(x, split = ":", fixed = TRUE))
        x <- unlist(strsplit(x, split = ";", fixed = TRUE))
        x <- unlist(strsplit(x, split = '"', fixed = TRUE))
        x <- gsub("[^[:alnum:]///' ]", "", x)
        x <- str_replace_all(x,"[[:punct:]]","")
        x <- x[!x %in% c(" ","")]
        x <- str_trim(x)
        
        # Take only the last sentence. Whats before that doesnt matter
        x <- x[length(x)]
        
        # If the input has mostly upper case letters, then the output will be all upper case. Set the flag for that now
        UpperCase = TRUE
        if(x=="I" || sum(grepl("[a-z]",unlist(strsplit(x,"")))) > sum(grepl("[A-Z]",unlist(strsplit(x,""))))) UpperCase = FALSE
        
        # Convert all of it to loweracse
        x <- stri_trans_tolower(x)
        
        # Split the string by individual words
        x <- unlist(strsplit(x, split = " ", fixed = TRUE))
        
        # Create the last n-1 words, and look up in the corresponding n gram table
        if((length(x)==1) && (x[1]=="")) Word <- DefaultWord
        else {
            MaxWords <- ifelse(length(x)>5,5,length(x))
            Output <- NA
            for(i in MaxWords:1) {
                Output <- c(Output,nGrams[nGrams$nGram==paste(x[(length(x)-i+1):(length(x))],collapse = " "),3])
            }
            
            Output <- Output[-1]
            Output <- unique(Output)
            Output <- Output[1:3]
            for(i in 1:3) {
                if(is.na(Output[i])) Output[i] = ""
                else {
                    if(nrow(ApostropheWords[ApostropheWords$woApostrophe==Output[i],])>0) Output[i] <- ApostropheWords[ApostropheWords$woApostrophe==Output[i],2]
                }
            }
        
            # If the input was mostly upper case (flag set above) then convert the output to upper case
            if(UpperCase) Output <- toupper(Output)
            for(i in 1:3) if(Output[i]=="i") Output[i]=="I"
        }
        
        Word <<- Output
        
        ###################### Prediction algo end ######################
        SearchedString <<- SearchString
    }
    
    GetWord <- function(n) Word[n]
    
    GetSearchedString <- function() SearchedString
    
    list(GetWord = GetWord,
         SuggestWords = SuggestWords,
         GetSearchedString = GetSearchedString)
}

SuggestedWord <- function(WordSuggestions,InputString,WordNum) {
    if(InputString=="") {
        Output <- DefaultWord[WordNum]
    } else
    {
        if(InputString!=WordSuggestions$GetSearchedString()) WordSuggestions$SuggestWords(InputString)
        
        Output <- WordSuggestions$GetWord(WordNum)
    }
    Output
}

Suggestions <- makeNextWordSuggestions("")

server = function(input, output, session){
    output$status_message <- renderText("Loading ...")
    
    output$Suggestion1 <- renderUI({
        actionButton(inputId = "Word1", label = SuggestedWord(Suggestions, input$input_text,1), width = '100%')
    })
    output$Suggestion2 <- renderUI({
        actionButton(inputId = "Word2", label = SuggestedWord(Suggestions, input$input_text,2), width = '100%')
    })
    output$Suggestion3 <- renderUI({
        actionButton(inputId = "Word3", label = SuggestedWord(Suggestions, input$input_text,3), width = '100%')
    })

    observeEvent(input$Word1, {
        updateTextInput(session, "input_text", value = paste(str_trim(string=input$input_text, side = "right"), SuggestedWord(Suggestions, input$input_text,1)))
    })    
    
    observeEvent(input$Word2, {
        updateTextInput(session, "input_text", value = paste(str_trim(string=input$input_text, side = "right"), SuggestedWord(Suggestions, input$input_text,2)))
    })    
    
    observeEvent(input$Word3, {
        updateTextInput(session, "input_text", value = paste(str_trim(string=input$input_text, side = "right"), SuggestedWord(Suggestions, input$input_text,3)))
    })
    
    if(InitialLoad) {
        InitialLoad <- FALSE
        updateTextInput(session, "input_text", value="")
    }
}
