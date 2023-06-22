spock_server<-function() {
  library(shiny)
  require(dplyr)
  library(rmarkdown)
  library(shinyFiles)
  Q <- readLines(system.file("start.rmd",package="pKa"))
  function(input, output, session)
    observeEvent(input$upload, {
      IP <<- input$upload
      if (dir.exists("temp")) {
        unlink("temp", recursive = T)
      }
      dir.create("temp")
      file.copy(input$upload$datapath,
                file.path("temp", input$upload$name))
      fls <-
        list.files(file.path(getwd(), "temp"),
                   pattern = '(xflr|asyr)$',
                   full.names = T)
      files <- paste0(shQuote(fls), collapse = ",")
      print(files)
      fix <- gsub("xxxx", files, Q) %>%
        gsub("%phfluor%", input$fluor, .) %>%
        gsub("%path%", getwd(), .)
      new_name <-
        file.path("temp", paste(input$zip, "pKa.rmd", sep = "_"))
      writeLines(fix, new_name)
      rmarkdown::render(new_name)
      #zip::zip("zippy.zip",files=list.files("temp",full.names = T))
      utils::zip("zippy.zip",
                 files = list.files("temp", full.names = T),
                 flags = "-j")
      output$DL <- downloadHandler(
        filename = function() {
          paste0(input$zip, ".zip")
        },
        content = function(file) {
          file.copy("zippy.zip", file)
        }
      )
    })
}
