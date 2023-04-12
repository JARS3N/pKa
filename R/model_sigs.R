model_sigs<-function(mod){
  as.data.frame(cbind(signif(summary(mod)$parameters,digits=5),
                      signif(confint(mod),digits=4))) %>%
    tibble::rownames_to_column() %>% 
    dplyr::rename(Parameter=rowname)
}
