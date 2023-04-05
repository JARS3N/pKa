ui<-function(){
  library(shiny)
  library(shinyFiles)
  fluidPage( "Generate pKa Reports from asyr or xflr files",
  mainPanel(
    actionButton("GO", "Select Directory",icon = icon("upload"))
  ))
}
