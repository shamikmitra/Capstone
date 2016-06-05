library(shiny)
library(gtools)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
    theme = "bootstrap.css",
    title = "Predicting Next Word",
    fluidRow(
        column(3),
        column(6,
               h1("Predicting the next word", align="center"),
               h4("Submission for the Data Science Capstone assignment", align="center"),
               h4("A Natural Language Processing project by Shamik Mitra", align="center")
        ),
        column(3)
    ),
    fluidRow(
        column(3),
        column(6,
               br(),
               br(),
               textInput(inputId="input_text", label = "", value = "Loading the data. Please wait ...", width = '100%', placeholder = "Enter any text you want and the boxes below will try to suggest the next word"),
               br()),
        column(3)
    ),
    fluidRow(
        column(3),
        column(2,
               uiOutput("Suggestion1")),
        column(2,
               uiOutput("Suggestion2")),
        column(2,
               uiOutput("Suggestion3")),
        column(3)
    ),
    fluidRow(
        column(3),
        column(6, br(),br(),br(),br(),br(),br(),br(),
               h6(a("View the slides for this application",href="http://rpubs.com/shamik_mitra/PredictNextWord", target="_blank")),
               h6(a("Access the source code in GitHub",href="https://github.com/shamikmitra/Capstone", target="_blank")),
               br(),
               h6(paste("Copyright",chr(169),"2016 Shamik Mitra. All rights reserved."))),
        column(3)
    )
  
))
