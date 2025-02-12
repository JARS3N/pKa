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
        print("ERROR: No valid data files found.")
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
          print("R Markdown successfully rendered.")
        },
        error = function(e) {
          showNotification("R Markdown rendering failed. Check LaTeX.", type = "error")
          print("ERROR: R Markdown rendering failed.")
          print(e)
          return()
        }
      )

      # Zip the results
      zip_file <- file.path(temp_dir, "zippy.zip")

      # Ensure zip file does not already exist
      if (file.exists(zip_file)) {
        print(paste("Existing zip file found. Removing:", zip_file))
        file.remove(zip_file)
      }

      # List files to zip
      zip_files <- list.files(temp_dir, full.names = TRUE)

      # Debug: Print full file list
      print("Checking files before zipping:")
      print(zip_files)

      # Ensure there are files before proceeding
      if (length(zip_files) == 0) {
        showNotification("No files found to zip! Check the temp directory.", type = "error", duration = 10)
        print("ERROR: No files found to zip!")
        stop("No files found to zip!")
      }

      # Debug: Check if each file exists before attempting to zip
      for (file in zip_files) {
        if (!file.exists(file)) {
          print(paste("WARNING: Expected file missing:", file))
          showNotification(paste("Missing file:", file), type = "error", duration = 10)
        } else {
          print(paste("File exists and will be added to zip:", file))
        }
      }

      # Debug: Print zip command before execution
      print(paste("Attempting to zip files into:", zip_file))

      # Try creating the zip file
      tryCatch(
        {
          utils::zip(zip_file, files = zip_files, flags = "-j")
          print("Zip command executed successfully.")
        },
        error = function(e) {
          print("ERROR: Zip creation failed!")
          showNotification("Zipping files failed! See console for details.", type = "error", duration = 10)
          print(e)
          stop("Zipping failed!")
        }
      )

      # Debug: Check if the zip file was actually created
      if (!file.exists(zip_file)) {
        print("ERROR: Zip file was NOT created! Something went wrong.")
        showNotification("Zip file was NOT created! Check logs.", type = "error", duration = 10)
        stop("Zip file was not created!")
      } else {
        print(paste("Zip file successfully created:", zip_file))
        showNotification("Zip file created successfully!", type = "message", duration = 10)
      }

      # Debug: Print final zip file size
      zip_size <- file.info(zip_file)$size
      if (!is.na(zip_size) && zip_size > 0) {
        print(paste("Zip file size:", zip_size, "bytes"))
      } else {
        print("WARNING: Zip file is empty or unreadable!")
        showNotification("Zip file is empty! Check contents.", type = "warning", duration = 10)
      }

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
