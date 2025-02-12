spock_server <- function() {
  library(shiny)
  library(dplyr)
  library(rmarkdown)
  library(shinyFiles)

  return(function(input, output, session) {
    observeEvent(input$upload, {
      req(input$upload)  # Ensure upload is not NULL

      # Define and clean the temp directory
      temp_dir <- normalizePath(file.path(getwd(), "temp"), winslash = "/")
      if (dir.exists(temp_dir)) unlink(temp_dir, recursive = TRUE)
      dir.create(temp_dir, showWarnings = FALSE)

      # Read the Rmd template inside the function
      Q <- readLines(system.file("spock.rmd", package = "pKa"))

      # Ensure temp_dir uses full path
      temp_dir <- normalizePath(temp_dir, winslash = "/")

      # Copy uploaded files
      uploaded_files <- file.path(temp_dir, input$upload$name)
      file.copy(input$upload$datapath, uploaded_files)

      # Get list of relevant files
      fls <- list.files(temp_dir, pattern = "(xflr|asyr)$", full.names = TRUE)
      if (length(fls) == 0) {
        showNotification("No valid data files found.", type = "error")
        return()
      }

      # Replace placeholders in the Rmd template
      substitute_placeholders <- function(text, replacements) {
        for (key in names(replacements)) {
          text <- gsub(key, replacements[[key]], text, fixed = TRUE)
        }
        return(text)
      }

      replacements <- list(
        "xxxx" = paste(shQuote(fls), collapse = ","),
        "%phfluor%" = input$fluor,
        "%path%" = temp_dir  # Ensure it is the correct full path
      )
      fix <- substitute_placeholders(Q, replacements)

      # Create the new Rmd file
      new_name <- file.path(temp_dir, paste0(input$zip, "_pKa.rmd"))
      writeLines(fix, new_name)

      # Render the Rmd file
      tryCatch(
        {
          rmarkdown::render(new_name, quiet = TRUE)
        },
        error = function(e) {
          showNotification("R Markdown rendering failed. Check LaTeX.", type = "error")
          print(e)
          return()
        }
      )

      # Zip the results
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

      # Ensure zip file exists before allowing download
      output$DL <- downloadHandler(
        filename = function() { paste0(input$zip, ".zip") },
        content = function(file) {
          if (!file.exists(zip_file)) {
            showNotification("Zip file not found!", type = "error")
            stop("Zip file not found!")
          }
          Sys.sleep(1)  # Prevent file access issues
          file.copy(zip_file, file, overwrite = TRUE)
        }
      )

      showNotification("Processing complete. Download your results.", type = "message")
    })
  })
}
