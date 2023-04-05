server <- function() {
  library(shiny)
  function(input, output, session)

    observeEvent(input$GO, {
    pKa::process()
    })
  }
