#!/usr/bin/env Rscript

#------
# File   : brand_by_scrapping.R
# History: 25-Jan-2019 Zhaozhi created the file
#------
# This file take the <drug list> and get the brand name from <DrugBank>
# Input  : ~/Desktop/drug.list.txt
# Output : ~/Desktop/Scraping_date.brand.txt
#------

#------
# Workflow and Argument
#------
# Step 1: get druglist
#         Line 38 to change druglist file name
# Step 2: get drugbank external links
#         Line 44 and 45 to change drugbank username and password
# Step 3: scrapping and get brand name
# Step 4: write result to outfile
#         Line 55 to change output file name
#-------

# install and load packages
required_packages=c("tidyverse","rvest");
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

# get druglist 
drug.list <- readLines("~/Desktop/druglist.txt")     
# get drugbank links
temp_dir   <- tempfile()
temp_file  <- tempfile()                                          # create temp file and dir to load data
download_db_link <- paste0(
  "curl -Lfv -o ", temp_file,                                     # filename
  " -u ", "username",                                             # drugbank username
  ":", "password",                                                # password
  " ","https://www.drugbank.ca/releases/5-1-2/downloads/all-drug-links"
)
system(download_db_link)
unzip(temp_file, exdir = temp_dir)                                # unzip temp file in temp dir
files     <- paste0(temp_dir,"/",list.files(temp_dir))
drug.bank <- read.csv(files)
unlink(c(temp_file,temp_dir))

date <- format(Sys.time(), "%b_%d_%Y")    
outfile <- paste0("~/GetBrandNames/", "Scraping_" , date , "_Brand.txt") # output filename 
if (file.exists(outfile)){
  file.remove(outfile)
}
write(paste0("drug",",","brand"), file = outfile, append = T)
# Scrapping
for (drug in drug.list) {
  # is drug exits in brugbank
  if (drug %in% drug.bank$Name){
    # get drug.com url
    url <- as.character(drug.bank[drug.bank$Name == drug,"Drugs.com.Link"])
    # get brand names
    brand_name <- (read_html(url) %>%
            html_nodes("p.drug-subtitle") %>%
            html_text() %>%
            strsplit("Brand Name: ")
    )[[1]][-1]
    # write output
    out <- paste(drug,brand_name,sep = ",")
    write(out, file = outfile, append = T)
    
  }else{
    # print message about missing drugs
    print(paste("Can't find DrugBank ID for", drug, sep = " "))
    out <- paste(drug,"",sep = ",")
    write(out, file = outfile, append = T)
  }
}



