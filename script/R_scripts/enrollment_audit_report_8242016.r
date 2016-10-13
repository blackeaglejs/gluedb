# Grab dplyr
library(dplyr)

setwd(~/dev/dchbx/gluedb)
report_8-24_filename <- "enrollment_audit_report_201608241018.csv"

# Read in the data
initial_data_8242016 <- read.csv(report_8-24_filename)

# Get all policies with zero premiums. 
zero_premiums_8242016 <- filter(initial_data, Premium.Total.Jan == 0.0)

# Separate IVL and SHOP
zero_premiums_IVL_8242016 <- filter(zero_premiums,Employer.Name == 'IVL')
zero_premiums_SHOP_8242016 <- filter(zero_premiums,Employer.Name != 'IVL')

# Group out all the SHOP ones by employer and FEIN
# Then get out the counts. 
zero_premiums_SHOP_grouped_8242016 <- group_by(zero_premiums_SHOP,Employer.Name,Employer.FEIN)
by_employer_8242016 <- summarise(zero_premiums_SHOP_grouped,per_employer=n())