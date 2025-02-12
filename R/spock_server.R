spock_server <- function() {
  library(shiny)
  library(dplyr)
  library(rmarkdown)
  library(shinyFiles)

  # Return the server function explicitly
  return(function(input, output, session) {
    observeEvent(input$upload, {
      req(input$upload)  # Ensure upload is not NULL

      # Read the RMD template inside the function to avoid scope issues
      Q <- readLines(system.file("start.rmd", package = "pKa"))

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

      # Replace placeholders using a helper function
      substitute_placeholders <- function(text, replacements) {
        for (key in names(replacements)) {
          text <- gsub(key, replacements[[key]], text, fixed = TRUE)
        }
        return(text)
      }

      # Ensure placeholders are replaced correctly
      replacements <- list(
        "xxxx" = files,
        "%phfluor%" = input$fluor,
        "%path%" = temp_dir
      )
      fix <- substitute_placeholders(Q, replacements)

      # Correctly name the Rmd file
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

      # Ensure zip file exists before allowing download
      output$DL <- downloadHandler(
        filename = function() {
          paste0(input$zip, ".zip")
        },
        content = function(file) {
          zip_file <- file.path(temp_dir, "zippy.zip")

          if (!file.exists(zip_file)) {
            showNotification("Zip file not found!", type = "error")
            stop("Zip file not found!")
          }

          Sys.sleep(1)  # Prevent file access issues
          success <- file.copy(zip_file, file, overwrite = TRUE)

          if (!success) {
            showNotification("File copy failed!", type = "error")
            stop("File copy failed!")
          }

          print("File successfully copied.")
        }
      )

      showNotification("Processing complete. Download your results.", type = "message")
    })
  })
}
