# profile_data.R
#
# this script is used to transform the raw excel files from the school report
# cards website and create the following dataframes in the kysrc package:
#
# sch_profile
# dist_profile
# state_profile
#
# this script is included in .Rbuildignore along with all of
# the assocaited excel files.
#
# data obtained on 2016-07-22 from:
# https://applications.education.ky.gov/src/

# load data ####

# load packages
library(devtools)
library(readxl)
library(dplyr)
library(tidyr)
library(stringr)

# profile data for state, dist, and school levels

profile12 <- read_excel("data12/PROFILE.xlsx", sheet = 2)
profile13 <- read_excel("data13/PROFILE.xlsx", sheet = 2)
profile14 <- read_excel("data14/PROFILE.xlsx")
profile15 <- read_excel("data15/PROFILE.xlsx")

# clean data ####

# filter out unneeded columns
prof12 <- profile12 %>%
  select(SCH_CD, DIST_NAME, SCH_NAME, LONGITUDE, LATITUDE ,SCH_YEAR, ENROLLMENT) %>%
  rename(sch_id = SCH_CD, dist_name = DIST_NAME, sch_name = SCH_NAME, long = LONGITUDE,
         lat = LATITUDE, year = SCH_YEAR, enroll = ENROLLMENT)

prof13 <- profile13 %>%
  select(SCH_CD, DIST_NAME, SCH_NAME, LONGITUDE, LATITUDE ,SCH_YEAR, ENROLLMENT) %>%
  rename(sch_id = SCH_CD, dist_name = DIST_NAME, sch_name = SCH_NAME, long = LONGITUDE,
         lat = LATITUDE, year = SCH_YEAR, enroll = ENROLLMENT)

prof14 <- profile14 %>%
  select(SCH_CD, DIST_NAME, SCH_NAME, LONGITUDE, LATITUDE ,SCH_YEAR, MEMBERSHIP) %>%
  rename(sch_id = SCH_CD, dist_name = DIST_NAME, sch_name = SCH_NAME, long = LONGITUDE,
         lat = LATITUDE, year = SCH_YEAR, enroll = MEMBERSHIP)

prof15 <- profile15 %>%
  select(SCH_CD, DIST_NAME, SCH_NAME, LONGITUDE, LATITUDE ,SCH_YEAR, MEMBERSHIP) %>%
  rename(sch_id = SCH_CD, dist_name = DIST_NAME, sch_name = SCH_NAME, long = LONGITUDE,
         lat = LATITUDE, year = SCH_YEAR, enroll = MEMBERSHIP)

# bind profile data from all years into one dataframe
prof_data <- bind_rows(prof12, prof13, prof14, prof15)

# remove old dataframes
rm(profile12, profile13, profile14, profile15, prof12, prof13, prof14, prof15)

# clean data formatting
prof_data_clean <- prof_data %>%
  mutate(long = as.numeric(str_trim(long)),
         lat = as.numeric(str_trim(lat)),
         year = factor(year, levels = c("20112012", "20122013", "20132014", "20142015"),
                          labels = c("2011-2012", "2012-2013", "2013-2014", "2014-2015")),
         enroll = as.integer(str_replace_all(enroll, ",","")))

# select state profile data
state_profile <- prof_data_clean %>%
  filter(sch_id == 999) %>% # filter for state id number
  mutate(dist_name = "State Total") %>% # clean labels
  select(-sch_name) # remove redundant column - all values are "State Total"

# select district profile data
dist_profile <- prof_data_clean %>%
  filter(sch_id != 999) %>% # exclude state id number
  filter(str_length(sch_id) == 3) %>% # only include id numbers w/ 3 chars
  select(-sch_name) %>% # remove redundant col - all values are "District Total"
  mutate(long = ifelse(long < 100, long, NA),
         lat = ifelse(lat < 100, lat, NA)) %>%
  group_by(sch_id) %>%
  mutate(long = min(long, na.rm = TRUE), # impute lat and long for
         lat = min(lat, na.rm = TRUE)) %>% # years w/ missing data
  ungroup() %>% # beechwood longitude needs to be negative
  mutate(long = ifelse(dist_name == "Beechwood Independent",
                       long * -1, long))


# select school profile data
sch_profile <- prof_data_clean %>%
  filter(str_length(sch_id) == 6) %>% # only include id numbers w/ 6 chars
  mutate(long = ifelse(long < 100, long, NA),
         lat = ifelse(lat < 100, lat, NA)) %>%
  group_by(sch_id) %>%
  mutate(long = min(long, na.rm = TRUE), # impute lat and long for
         lat = min(lat, na.rm = TRUE)) %>% # years w/ missing data
  ungroup() %>%
  arrange(sch_id)

# use data for package ####
use_data(state_profile, overwrite = TRUE)
use_data(dist_profile, overwrite = TRUE)
use_data(sch_profile, overwrite = TRUE)
