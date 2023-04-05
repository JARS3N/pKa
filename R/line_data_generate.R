line_data_generate<-function(model,pHval){
  data.frame(
  val=predict(model,data.frame(pH=pHval))[seq_along(pHval)],
  pH=pHval)
}
