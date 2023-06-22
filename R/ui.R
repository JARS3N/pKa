spock_ui<-function() {
library(shiny)
library(shinyFiles)
fluidPage(titlePanel("Generate pKa Reports from asyr or xflr files"),
          mainPanel(
          textInput("fluor",label="pH Flourophore", value = "",  placeholder = "HP9"),
          textInput("MF",label="multifluor batch", value = "",  placeholder = "mf00000-1"),
          textInput("zip",label="Cartridge Lot", value = "",  placeholder = "zippy"),
          fileInput("upload", "Upload ASYR/XFLR files", multiple = T),
          downloadButton('DL', 'Download link', style="display: block; margin: 0 auto; width: 230px;color: black;")
          ))
}