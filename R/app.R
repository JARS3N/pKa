app<-function(){
  shiny::shinyApp(pKa::ui(),pKa::server())
}
