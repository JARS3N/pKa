results_messaging <- function(cl_model_pka) {
  #cl_model_pka<-filter(split_model_sumary,attr=="pKa",dye=="CL")
  Result <- if (cl_model_pka["97.5%"] <= 6.8) {
    "The pKa modeling fails to meet minimum specification."
  } else if (cl_model_pka["2.5%"] >= 6.8) {
    "The pKa modeling clearly passes acceptance criteria of 6.8."
  } else if (cl_model_pka['Estimate'] >= 6.8) {
    "The pKa model estimate meets the minimum requirement of 6.8 but the true value may still fall below minimum specification as indicated by the low end of the confidence interval. Proceed with caution."
  } else{
    "The pKa estimate fails to meet the minimum requirement."
  }
}
