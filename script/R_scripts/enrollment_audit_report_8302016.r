# Grab dplyr
library(dplyr)

setwd('~/dev/dchbx/gluedb')

data_83016_filename_oct_2015 <- "enrollment_audit_report_201608302220_10-15-2015-10-31-2015.csv"
data_83016_filename_nov_2015 <- "enrollment_audit_report_201608302220_11-01-2015-11-30-2015.csv"
data_83016_filename_dec_2015 <- "enrollment_audit_report_201608302220_12-01-2015-12-31-2015.csv"
data_83016_filename_jan_2016 <- "enrollment_audit_report_201608302220_01-01-2016-01-31-2016.csv"
data_83016_filename_feb_2016 <- "enrollment_audit_report_201608302220_02-01-2016-02-29-2016.csv"
data_83016_filename_mar_2016 <- "enrollment_audit_report_201608302220_03-01-2016-03-31-2016.csv"
data_83016_filename_apr_2016 <- "enrollment_audit_report_201608302220_04-01-2016-04-30-2016.csv"
data_83016_filename_may_2016 <- "enrollment_audit_report_201608302220_05-01-2016-05-31-2016.csv"
data_83016_filename_jun_2016 <- "enrollment_audit_report_201608302220_06-01-2016-06-30-2016.csv"
data_83016_filename_jul_2016 <- "enrollment_audit_report_201608302220_07-01-2016-07-15-2016.csv"

# Read in the data
oct_2015 <- read.csv(data_83016_filename_oct_2015)
nov_2015 <- read.csv(data_83016_filename_nov_2015)
dec_2015 <- read.csv(data_83016_filename_dec_2015)
jan_2016 <- read.csv(data_83016_filename_jan_2016)
feb_2016 <- read.csv(data_83016_filename_feb_2016)
mar_2016 <- read.csv(data_83016_filename_mar_2016)
apr_2016 <- read.csv(data_83016_filename_apr_2016)
may_2016 <- read.csv(data_83016_filename_may_2016)
jun_2016 <- read.csv(data_83016_filename_jun_2016)
jul_2016 <- read.csv(data_83016_filename_jul_2016)

# Combine the datasets
initial_data_8302016 <- rbind(oct_2015,
                              nov_2015,
                              dec_2015,
                              jan_2016,
                              feb_2016,
                              mar_2016,
                              apr_2016,
                              may_2016,
                              jun_2016,
                              jul_2016)

# Get all policies with zero premiums. 
zero_premiums_8302016 <- filter(initial_data_8302016, Premium.Total.Jan == 0.0,
                                                      Premium.Total.Feb == 0.0,
                                                      Premium.Total.Mar == 0.0,             
                                                      Premium.Total.Apr == 0.0,             
                                                      Premium.Total.May == 0.0,             
                                                      Premium.Total.Jun == 0.0,             
                                                      Premium.Total.Jul == 0.0,             
                                                      Premium.Total.Aug == 0.0,             
                                                      Premium.Total.Sep == 0.0,             
                                                      Premium.Total.Oct == 0.0,             
                                                      Premium.Total.Nov == 0.0,             
                                                      Premium.Total.Dec == 0.0)