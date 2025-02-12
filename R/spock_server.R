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

# Ensure we have files before proceeding
if (length(zip_files) == 0) {
  showNotification("⚠️ No files found to zip! Check the temp directory.", type = "error", duration = 10)
  stop("No files found to zip!")
}

# Debug: Check if each file exists before attempting to zip
for (file in zip_files) {
  if (!file.exists(file)) {
    print(paste("⚠️ Warning: Expected file missing:", file))
    showNotification(paste("⚠️ Missing file:", file), type = "error", duration = 10)
  } else {
    print(paste("✅ File exists and will be added to zip:", file))
  }
}

# Debug: Print zip command
print(paste("🗜️ Attempting to zip files into:", zip_file))

# Try creating the zip file
tryCatch(
  {
    utils::zip(zip_file, files = zip_files, flags = "-j")
    print("✅ Zip command executed successfully.")
  },
  error = function(e) {
    print("❌ Zip creation failed!")
    print(e)
    showNotification("❌ Zipping files failed! See console for details.", type = "error", duration = 10)
    stop("Zipping failed!")
  }
)

# Debug: Check if the zip file was actually created
if (!file.exists(zip_file)) {
  print("❌ Zip file was NOT created! Something went wrong.")
  showNotification("❌ Zip file was NOT created! Check logs.", type = "error", duration = 10)
  stop("Zip file was not created!")
} else {
  print("🎉 Zip file successfully created:", zip_file)
  showNotification("🎉 Zip file created successfully!", type = "message", duration = 10)
}

# Debug: Print final zip file size
zip_size <- file.info(zip_file)$size
if (!is.na(zip_size) && zip_size > 0) {
  print(paste("📦 Zip file size:", zip_size, "bytes"))
} else {
  print("⚠️ Warning: Zip file is empty or unreadable!")
  showNotification("⚠️ Zip file is empty! Check contents.", type = "warning", duration = 10)
}
