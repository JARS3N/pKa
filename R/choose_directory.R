# Helper function to load packages, installing them first if necessary
ensure_library <- function(lib.name, verbose = FALSE) {
  if (verbose) message("Checking if package '", lib.name, "' is installed...")
  
  x <- require(lib.name, quietly = !verbose, character.only = TRUE)
  if (!x) {
    if (verbose) message("Package '", lib.name, "' not installed. Attempting to install...")
    tryCatch({
      install.packages(lib.name, dependencies = TRUE, quiet = !verbose)
      x <- require(lib.name, quietly = !verbose, character.only = TRUE)
    }, error = function(e) {
      if (verbose) message("Failed to install package '", lib.name, "': ", e$message)
      x <- FALSE
    })
  }
  
  if (verbose && x) message("Package '", lib.name, "' loaded successfully.")
  if (verbose && !x) message("Package '", lib.name, "' could not be loaded.")
  
  x
}

# Detect and validate available methods
detect_available_methods <- function(verbose = FALSE) {
  methods <- list()
  
  if (verbose) message("Detecting available directory selection methods...")
  
  if (exists("choose.dir", where = "package:utils") && .Platform$OS.type == "windows") {
    methods$choose.dir <- TRUE
    if (verbose) message("Method 'choose.dir' is available.")
  }
  if (ensure_library("rstudioapi", verbose) && rstudioapi::isAvailable() && rstudioapi::getVersion() > "1.1.287") {
    methods$RStudioAPI <- TRUE
    if (verbose) message("Method 'RStudioAPI' is available.")
  }
  if (ensure_library("tcltk", verbose) && class(try({ tt <- tktoplevel(); tkdestroy(tt) }, silent = TRUE)) != "try-error") {
    methods$tcltk <- TRUE
    if (verbose) message("Method 'tcltk' is available.")
  }
  if (ensure_library("gWidgets2", verbose) && ensure_library("RGtk2", verbose)) {
    methods$gWidgets2RGtk2 <- TRUE
    if (verbose) message("Method 'gWidgets2RGtk2' is available.")
  }
  if (ensure_library("shinyFiles", verbose)) {
    methods$shiny <- TRUE
    if (verbose) message("Method 'shiny' is available.")
  }
  
  if (verbose) message("Available methods detected: ", paste(names(methods), collapse = ", "))
  
  methods
}

# Main function to choose a directory
choose_directory <- function(preferred_methods = c("choose.dir", "RStudioAPI", "tcltk", 
                                                   "gWidgets2RGtk2", "shiny"),
                             title = "Select a Directory",
                             verbose = FALSE) {
  available_methods <- detect_available_methods(verbose)
  
  # Try preferred methods in order
  for (method in preferred_methods) {
    if (isTRUE(available_methods[[method]])) {
      if (verbose) message("Attempting method '", method, "'...")
      
      # Execute the method
      tryCatch({
        dir <- switch(
          method,
          "choose.dir" = utils::choose.dir(caption = title),
          "RStudioAPI" = rstudioapi::selectDirectory(caption = title),
          "tcltk" = tcltk::tk_choose.dir(caption = title),
          "gWidgets2RGtk2" = gWidgets2::gfile(type = "selectdir", text = title),
          "shiny" = run_shiny_directory_selector(title, verbose = verbose)
        )
        # Return valid directory if found
        if (!is.null(dir) && dir != "" && dir.exists(dir)) {
          if (verbose) message("Directory selected: ", dir)
          return(normalizePath(dir, winslash = "/", mustWork = TRUE))
        } else if (!is.null(dir)) {
          warning("Invalid directory selected: ", dir)
        }
      }, error = function(e) {
        if (verbose) message("Error with method '", method, "': ", e$message)
      })
    }
  }
  
  stop("No valid directory selection method succeeded.")
}

# Shiny widget for directory selection (fallback)
run_shiny_directory_selector <- function(title = "Select a Directory", verbose = FALSE) {
  if (verbose) message("Launching Shiny directory selector with C: and G: roots...")
  
  library(shiny)
  library(shinyFiles)
  
  ui <- fluidPage(
    titlePanel(title),
    shinyDirButton("dir", "Select Directory", "Please select a directory"),
    verbatimTextOutput("selected_dir")
  )
  
  server <- function(input, output, session) {
    # Restrict to C: and G: drives
    roots <- c(C = "C:/", G = "G:/")
    
    shinyDirChoose(input, "dir", roots = roots, session = session)
    
    selected_dir <- reactive({
      tryCatch({
        parseDirPath(roots, input$dir)
      }, error = function(e) {
        if (verbose) message("Error parsing directory: ", e$message)
        NULL
      })
    })
    
    output$selected_dir <- renderPrint({
      dir <- selected_dir()
      if (!is.null(dir)) normalizePath(dir, winslash = "/") else NULL
    })
    
    observeEvent(input$dir, {
      stopApp(selected_dir())
    })
  }
  
  runApp(shinyApp(ui = ui, server = server))
}

# Example usage
# dir <- choose_directory(preferred_methods = c("choose.dir", "shiny", "tcltk"), verbose = TRUE)
# cat("Selected directory:", dir, "\n")
