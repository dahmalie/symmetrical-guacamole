#load packagers and files
library(tidyverse)
library(readr)
library(lubridate)

# define data paths
admit_path <- snakemake@input[['adm']]
pop_path <- snakemake@input[['popu']]

ecg_path <- snakemake@input[['ecg']]
pace_path <- snakemake@input[['pm']]

med_path <- snakemake@input[['med']]

#load files
admit0 <- read_csv(admit_path, col_types = 'ccccc',
                 locale = locale(encoding = 'latin1'),
                 na = c('NA'))

pop0 <- read_csv(pop_path, col_types = cols(),
                 locale = locale(encoding = 'latin1'),
                 na = c('NA'))

ecg0 <- read_csv(ecg_path, col_types = cols(), na=c('NA'))

pm0 <- read_csv(pace_path, col_types = cols(),
               locale = locale(encoding = 'latin1'),
               na = c('NA'))  

med0 <- read_csv(med_path, col_types = cols(),
                locale = locale(encoding = 'latin1'),
                na = c('NA'))

#direct log file
log <- file(snakemake@log[['check0']], 'wt')
sink(log)

#rename columns and write files
admit1 <- admit0 %>% 
  rename(PID=1, CPR = 2, ADM_IN=3, ADM_OUT=4, ADM_HOSP=5, ADM_WARD=6) %>% 
  distinct()

write_tsv(admit1, snakemake@output$adm_out, col_names = T)

### to log file ###
adm_n <- n_distinct(admit1$CPR)
cat('N unique patients in admission file:', adm_n)
###################

pop1 <- pop0 %>% 
   rename(PID = 1, CPR =2, REG = 3, MUN_ID = 4, MUN = 5, ZIP = 6, CITY = 7,
         DOD = 8, DOB = 9, SEX = 10, PROC_YMD = 11, PROC_START = 12, PROC_END = 13,
         AVR_SKS = 14, SKS_NAME = 15, REF_SKS = 16, REF_TEXT = 17) 
 
write_tsv(pop1, snakemake@output$pop_out, col_names = T)

### to log fil ###
pop_n <- n_distinct(pop1$CPR)
cat('\nN people in population:', pop_n)
#################

ecg1 <- ecg0 %>% 
  rename(PID = 1, CPR = 2, ECG_ID = 3, ECG_TYPE = 4, TYPE_NAME = 5,
         ECG_NPU = 6, ECG_YMDHMS = 7, COMP_NAME = 8, ECG_TEXT = 9, 
         COMP_UNIT = 10) 

write_tsv(ecg1, snakemake@output$ecg_out, col_names = T)

### to log fil ###
ecg_n <- n_distinct(ecg1$CPR)
ecg_all <- n_distinct(ecg1$ECG_ID)
cat('\nN people with an ECG:', ecg_n)
cat('\nN ECGs:', ecg_all)
#################

#pacemaker
pm1 <- pm0 %>% rename(PID=1, CPR = 2, DEV_DATE=3, SKS=4, DESCRIPTION=5) 
write_tsv(pm1, snakemake@output$pm_rename, col_names = T)

### to log fil ###
pm_n <- n_distinct(pm1$CPR)
cat('\nN people in device file:', pm_n)

#################

#medication
med1 <- med0 %>% 
  rename(
    PID = 1, CPR = 2, ORD_DATE = 3, START = 4, STOP = 5, DRUG_ID = 6,
    ATC_CODE = 7, DRUG_NAME = 8, DRUG_GEN = 9, SALES_NAME = 10, FORMULA = 11,
    THERA_CLASS = 12, PHARM_CLASS = 13, PHARM_SUBCLASS = 14, STRENGTH = 15,
    STRENGTH_UNIT = 16, DOSAGE = 17, DOSAGE_UNIT = 18, DOSAGE_TEXT = 19, FREQ_TEXT = 20,
    INDICATION = 21
  )

write_tsv(med1, snakemake@output$med_out, col_names = T)
 
### to log fil ###
med_n <- n_distinct(med1$CPR)
cat('\nN patients with in-hospital medication:', med_n)
