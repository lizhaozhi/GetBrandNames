#!/usr/bin/env Rscript

#------
# File    : brand_by_MySQL.R
# History : 28-Jan-2019 (Zhaozhi Li)
#------
# This file create a MySQL database and get information from ChEBI.
# Then take a drug list and their brand names
# Input   : ~/Desktop/druglist.txt
# Output  : ~/Desktop/MySQL_date_Brand.txt
#------

#------
# Workflow and Argument
#------
# Step 1: build local MySQL database
#         (a) create a local MySQL database 
#             Line 52 to change database name 
#         (b) download dump files from ChEBI (They actually provide .sql files)
#             Line 87 and 93 to change dump files url
#         (c) import data from dump diles to new database
# Step 2: get query data
          drug_list <- readLines("~/Desktop/druglist.txt")         
#         Line 122 to change query 
# Step 3: write result to outfile
#         Line 117 to change output file name
# Step 4: whether delete this database
          delete_database  <- FALSE
#-------

# install and load packages
required_packages=c("RMySQL","dbConnect");
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

# connect to SQL
con <- dbConnect(
  MySQL(),
  dbname   = '', 
  user     = 'root',
  password = 'yw8570lucky'                               #......This is my password....
  )
# create a database to store data
dbname  <- "ChEBI" 
dbSendQuery(con, paste0("CREATE DATABASE ", dbname,";"))
dbSendQuery(con, paste0("use ", dbname, ";"))

# create function to read .sql file and excute statements
execute_sql_file <- function(file) {
  print(paste0("Processing ",file))
  temp_statement <- ""
  statements <- readLines(file)
  statements <- statements[!grepl('^#',statements)]
  statements <- statements[!(statements == "")]
  if (length(statements) == 0){                         # report empty .sql file
    print(paste0("This is a empty file ", file))
  }else{
    for (i in 1:length(statements)){
      if (grepl(";$",statements[i])){                   # comband statement 
        if(i == 1){
          dbSendStatement(con, statement = statements[i])
        }else if(grepl(";$",statements[i-1])){
          dbSendStatement(con, statement = statements[i])
        }else{
          temp_statement <- paste0(temp_statement, statements[i])
          dbSendStatement(con, statement = temp_statement)
          temp_statement <- ""
        }
      }else{
        temp_statement <- paste0(temp_statement, statements[i])
      }
    }
  }
}

# get dump file
temp_dir     <- paste0("~/Downloads/", dbname)            # create temp file and dir to load data
temp_file    <- tempfile()
# create tables
url_create   <- "ftp://ftp.ebi.ac.uk/pub/databases/chebi/generic_dumps/mysql_create_tables.sql"
download.file(url_create, temp_file)
execute_sql_file(temp_file)
unlink(c(temp_file))
# import data           
temp_file  <- tempfile()                                  # create temp file and dir to load data
url_data   <- "ftp://ftp.ebi.ac.uk/pub/databases/chebi/generic_dumps/generic_dump_allstar.zip"
download.file(url_data, temp_file)                        # download dump files
unzip(temp_file, exdir = temp_dir)                        # unzip dump file in temp dir

files      <- paste0(temp_dir,"/",list.files(temp_dir)) 
for (file in grep(".sql.gz$",files,value = T)) {          # unzip all .gz files in dump file
    system(paste0("gunzip ", file))
}

# import data into sql tables
files       <- paste0(temp_dir,"/",list.files(temp_dir))   # include all new gunzip file
sql_files   <- grep(".sql$",files, value = T)              # take each .sql file 
first_file  <- paste0(temp_dir, "/compounds.sql")          # compounds.sql better be the first one, according to chebi website
final_file  <- paste0(temp_dir, "/relation.sql")           # relation file should be the last one
execute_sql_file(first_file)
sql_files <- sql_files[!sql_files %in% c(first_file, final_file)]
n_sql_files <- length(sql_files)                            
for (sql_file in sql_files) {                               
    execute_sql_file(sql_file)
}
execute_sql_file(final_file)
unlink(c(temp_file))   

date    <- format(Sys.time(), "%b_%d_%Y_")                
outfile <- paste0("~/Desktop/", "MySQL_", date, "Brand.txt")     # outfile name

# get brand names
query     <- ""
for (i in 1:length(drug_list)) {
  # MySQL Qeury
  query   <- paste0(
    query,
    "SELECT names.name AS brand_name, compounds.chebi_accession, compounds.name AS drug_compounds_name",
    " FROM names",
    " JOIN compounds",
    " ON compounds.id = names.compound_id",
    " WHERE names.type = 'BRAND NAME' AND compounds.name = '", drug_list[i], "'"
  )
  if(i != length(drug_list)){
    query   <- paste0(query, " union ")
  }else{
    query   <- paste0(query, ";")
  }
}
result  <- dbGetQuery(con, query)                     # Retrive result
write.table(result, file = outfile, row.names=FALSE)
dbDisconnect(con)


# delete database
if (delete_database == TRUE){
  dbSendQuery(paste0("drop database ", dbname))
}
