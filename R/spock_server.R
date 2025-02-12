# spock_server<-function() {
#   library(shiny)
#   require(dplyr)
#   library(rmarkdown)
#   library(shinyFiles)
#   Q <- readLines(system.file("start.rmd",package="pKa"))
#   function(input, output, session)
#     observeEvent(input$upload, {
#       IP <<- input$upload
#       if (dir.exists("temp")) {
#         unlink("temp", recursive = T)
#       }
#       dir.create("temp")
#       file.copy(input$upload$datapath,
#                 file.path("temp", input$upload$name))
#       fls <-
#         list.files(file.path(getwd(), "temp"),
#                    pattern = '(xflr|asyr)$',
#                    full.names = T)
#       files <- paste0(shQuote(fls), collapse = ",")
#       print(files)
#       fix <- gsub("xxxx", files, Q) %>%
#         gsub("%phfluor%", input$fluor, .) %>%
#         gsub("%path%", getwd(), .)
#       new_name <-
#         file.path("temp", paste(input$zip, "pKa.rmd", sep = "_"))
#       writeLines(fix, new_name)
#       rmarkdown::render(new_name)
#       #zip::zip("zippy.zip",files=list.files("temp",full.names = T))
#       utils::zip("zippy.zip",
#                  files = list.files("temp", full.names = T),
#                  flags = "-j")
#       output$DL <- downloadHandler(
#         filename = function() {
#           paste0(input$zip, ".zip")
#         },
#         content = function(file) {
#           file.copy("zippy.zip", file)
#         }
#       )
#     })
# }


spock_server <- function() {
  library(shiny)
  library(dplyr)
  library(rmarkdown)
  library(shinyFiles)
  
  Q <- readLines(system.file("start.rmd", package = "pKa"))
  
  # Helper function for replacing multiple placeholders in text
  substitute_placeholders <- function(text, replacements) {
    for (key in names(replacements)) {
      text <- gsub(key, replacements[[key]], text, fixed = TRUE)
    }
    return(text)
  }
  
  function(input, output, session) {
    observeEvent(input$upload, {
      req(input$upload)  # Ensure upload is not NULL
      
      # Define and clean the temp directory
      temp_dir <- file.path(getwd(), "temp")
      if (dir.exists(temp_dir)) unlink(temp_dir, recursive = TRUE)
      dir.create(temp_dir, showWarnings = FALSE)
      
      # Copy uploaded files
      uploaded_files <- file.path(temp_dir, input$upload$name)
      file.copy(input$upload$datapath, uploaded_files)
      
      # Get list of relevant files
      fls <- list.files(temp_dir, pattern = "(xflr|asyr)$", full.names = TRUE)
      if (length(fls) == 0) {
        showNotification("No valid data files found.", type = "error")
        return()
      }
      
      # Format file paths correctly for LaTeX
      temp_dir <- normalizePath(temp_dir, winslash = "/")
      files <- paste(shQuote(fls), collapse = ",")
      
      print(files)  # Debugging output
      
      # Replace placeholders using the helper function
      replacements <- list(
        "xxxx" = files,
        "%phfluor%" = input$fluor,
        "%path%" = temp_dir
      )
      fix <- substitute_placeholders(Q, replacements)
      
      # Create the new Rmd file
      new_name <- file.path(temp_dir, paste0(input$zip, "_pKa.rmd"))
      writeLines(fix, new_name)
      
      # Attempt to render the Rmd file
      tryCatch(
        {
          rmarkdown::render(new_name, quiet = TRUE)  # Suppress unnecessary logs
        },
        error = function(e) {
          showNotification("R Markdown rendering failed. Check LaTeX.", type = "error")
          print(e)
          return()
        }
      )
      
      # Create a zip archive
      zip_file <- file.path(temp_dir, "zippy.zip")
      tryCatch(
        {
          utils::zip(zip_file, files = list.files(temp_dir, full.names = TRUE), flags = "-j")
        },
        error = function(e) {
          showNotification("Zipping files failed.", type = "error")
          print(e)
          return()
        }
      )
      
      # Provide download link
      output$DL <- downloadHandler(
        filename = function() {
          paste0(input$zip, ".zip")
        },
        content = function(file) {
          file.copy(zip_file, file)
        }
      )
      
      showNotification("Processing complete. Download your results.", type = "message")
    })
  }
}
