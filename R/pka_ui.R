ui <- function() {
  fluidPage(
    tags$head(tags$link(rel = "icon", href = "data:,")), # Suppress favicon error
    "Generate pKa Reports from asyr or xflr files",
    mainPanel(
      actionButton("GO", "Select Directory", icon = icon("upload"))
    )
  )}
