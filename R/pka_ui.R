ui <- function() {
  library(shiny)
  library(shinyFiles)
  
  fluidPage(
    tags$head(tags$link(rel = "icon", type = "image/x-icon", href = "favicon.ico")),
    "Generate pKa Reports from asyr or xflr files",
    mainPanel(
      actionButton("GO", "Select Directory", icon = icon("upload"))
    )
  )
}
