process<-function(dir=choose_directory()){
require(dplyr)
library(rmarkdown)
#x<-gsub("\\\\","/",dir)
x<-normalizePath(dir, winslash = "/", mustWork = FALSE)
Q<-readLines(system.file('rebuild.rmd',package="pKa"))
fix<-gsub("%path%",x,Q) %>%
  gsub("%phfluor%",
       basename(dirname(x)),.
  )
Lot<-gsub(" PKA","",basename(x))
pH<-basename(dirname(x))
new_name <-file.path(x,file.path(paste0(pH,"-",Lot,".Rmd")))
writeLines(fix,new_name)
rmarkdown::render(new_name)
}
