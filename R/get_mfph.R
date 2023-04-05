get_mfph<-function(u){
  #will look for MF/pH info in the database
  nlot<-substr(u,2,nchar(u))
  ctype<-substr(u,1,1)
  try({q<-tbl(con,"lotview") %>%
    filter(`Lot Number`== nlot) %>%
    filter(Type == ctype) %>%
    select(`Barcode Matrix ID`) %>%
    rename(ID=`Barcode Matrix ID`) %>%
    left_join (.,tbl(con,"barcodematrixview")) %>%
    select(.,Multifluor,`pH Fluor`) %>%
    collect() %>%
    select(MF=Multifluor,pH=`pH Fluor`)})
  if(nrow(q)==0){NULL}else{q}
}
