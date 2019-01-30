#!/usr/bin/env Rscript

#------
# File   : summary_brandlist.R
# History: 30-Jan-2019 Zhaozhi created the file
#------
# This file take the <brnad list> and get summary information
# Input  : ~/Desktop/**_date_Brand.txt
# Output : ~/Desktop/Summary_date.Brand.txt
#------

#------
# Workflow and Argument
#------
# Step 1: get data in each .Brand.txt file in dir
#         Line 37 to change dir name
# Step 2: uniq brand names of the same drug
# Step 3: write result to outfile
#         Line 62 to change output file name
#-------

# install and load packages
required_packages=c("tidyverse");
Install_And_Load <- function(required_packages){
  remaining_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])];
  if(length(remaining_packages)){
    install.packages(remaining_packages);
  }
  for(package in required_packages){
    library(package, character.only = TRUE,quietly = TRUE);
  }
}
Install_And_Load(required_packages);

dir    <- "~/Desktop"                                                  # dir name
files  <- paste0(dir,"/",list.files(dir))
lists <- grep("*Brand.txt", files, value = T)
lists <- lists[!grepl("Summary", lists)]
summary <- list()
for (list in lists){
  temp_list <- as_data_frame(read.csv(list, header = T, stringsAsFactors = F))
  temp_list <- temp_list %>%
    select(drug = contains("drug"), brand = contains("brand")) %>%
    mutate(source = list)
  for(i in 1:nrow(temp_list)){
    drug <- tolower(temp_list[i,"drug", drop = T])
    if (nchar(temp_list[i,"brand"])){
      brand <- as.data.frame(temp_list[i,"brand"])
      names(brand) <- "Brand"
      summary[[drug]]["Brand"] <- rbind(summary[[drug]]["Brand"], 
                                        brand
                                        )
    }else{
      summary[[drug]]["Brand"] <- ""
    }
  }
}

date <- format(Sys.time(), "%b_%d_%Y")    
outfile <- paste0("~/Desktop/", "Summary_" , date , "_Brand.txt")     # output filename 
if (file.exists(outfile)){
  file.remove(outfile)
}

write(paste0("drug",",","brand_summary"), file = outfile, append = T)
for (drug in names(summary)){
  uniq_brand <- unique(unlist(summary[[drug]]["Brand"]))
  for (brand in uniq_brand){
    out <- paste(drug, brand, sep = ",")
    write(out, file = outfile, append = T)
  }
}

