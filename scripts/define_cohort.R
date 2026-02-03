library(tidyverse)

tavi_path <- snakemake@input$tavi
dev_path <- snakemake@input$dev
pop_path <- snakemake@input$pop0

tavi_adm <- read_tsv(tavi_path, col_types = cols())
dev_adm <- read_tsv(dev_path, col_types = cols())
pop_in <- read_tsv(pop_path, col_types = cols())

#direct log file
log <- file(snakemake@log[['check0']], 'wt')
sink(log)

tavi_dev <- dev_adm %>% 
  inner_join(tavi_adm, by = c('PID', 'CPR')) %>% 
  transmute(PID, CPR, 
            GROUP = case_when((DEV_OUT < TAVI_IN) | DEV_DATE < TAVI_YMD ~ 'Known',
                              time_length(TAVI_OUT %--% DEV_IN, 'days') > 0 & 
                                time_length(TAVI_OUT %--% DEV_IN, 'days') <= 30 ~ 'Late',
                              TAVI_YMD == DEV_DATE ~ 'Early',
                              DEV_DATE %within% interval(TAVI_YMD, TAVI_OUT) ~ 'Early',
                              time_length(TAVI_OUT %--% DEV_IN, 'days') > 30 ~ 'Censored')
            )

tavi_dev %>% 
  count(GROUP)

cohort <- tavi_adm %>% 
  left_join(tavi_dev, by = c('PID', 'CPR')) %>% 
  transmute(PID, CPR, TAVI_YMD, TAVI_OUT, 
            GROUP = if_else(is.na(GROUP) | GROUP == 'Censored', 'None', GROUP)) %>% 
  filter(GROUP != 'Known') %>% 
  left_join(select(pop_in, PID, DOB, DOD, SEX), by = 'PID') %>% 
  mutate(DOB = as.Date(DOB),
         DOD = as.Date(DOD)
         )

n_pat <- n_distinct(cohort$PID)
cat('\nN distinct patients in cohort:', n_pat)

write_tsv(cohort, snakemake@output$cohort)
