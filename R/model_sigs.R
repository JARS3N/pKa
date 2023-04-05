model_sigs<-function(mod){
  df<-as.data.frame(cbind(signif(summary(mod)$parameters,digits=5),
                          signif(confint(mod),digits=4)))
  df$attr<-row.names(df)
  row.names(df)<-NULL
  df
}
