spock<-function(){
  shiny::shinyApp(pKa::spock_ui(),pKa::spock_server())
}
