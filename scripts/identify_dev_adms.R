library(tidyverse)

adm_path <- snakemake@input$adm
dev_path <- snakemake@input$dev

adm <- read_tsv(adm_path, col_types = cols())
dev <- read_tsv(dev_path, col_types = cols())

#direct log file
log <- file(snakemake@log[['check0']], 'wt')
sink(log)

#BFCA0: Implantation af PM
#BFCA1: Udskiftning af PM
#BFCA2: Opgradering af PM
#BFCA3: Revision af PM
#BFCA4: Fjernelse
#BFCA5: Implantation, aflaesning, fjernelse af ILR
#BFCA6: Implantation af pacelektrode
#BFCA7: Replacering af paceelektrode
#BFCA8: Ekstraktion af pacemaker, elektrode ..
#BFCA9: Anlaeggelse af temporaert system
#BFCB*: ICD-related codes

dev_select <- dev %>% 
  filter(!str_starts(SKS, 'BFCA5'), !str_starts(SKS, 'BFCA9')) #exluces ILRs and tempPM

dev_key <- dev %>% 
  distinct(SKS, DESCRIPTION) %>% 
  arrange(SKS)

write_tsv(dev_key, snakemake@output$key)

dev_select1 <- dev_select %>% 
  arrange(SKS) %>% 
  group_by(PID, CPR, DEV_DATE) %>% 
  summarise(PROCS = list(SKS),
            .groups = "drop") %>% 
  ungroup()

adm_dev <- adm %>% 
  filter(PID %in% dev_select$PID) %>% 
  mutate(ADM_IN = ymd_hms(ADM_IN, tz = 'CET'),
         ADM_OUT = ymd_hms(ADM_OUT, tz = 'CET')
         ) %>% 
  full_join(dev_select1, by = c('PID', 'CPR'), relationship = 'many-to-many') %>% 
  filter(DEV_DATE %within% interval(as.Date(ADM_IN), as.Date(ADM_OUT))) %>% 
  add_count(CPR, DEV_DATE)

doubles <- adm_dev %>% 
  filter(n>1) %>% 
  arrange(PID, ADM_IN, ADM_OUT) %>% 
  group_by(PID) %>% 
  mutate(time_diff = as.numeric(difftime(ADM_IN, lag(ADM_OUT), units = 'hours')),
         new_group = if_else(is.na(time_diff) | time_diff >= 3, 1, 0), #we concatenate admissions <3 hrs apart
         group_id = cumsum(new_group)
  ) %>% 
  group_by(PID, group_id) %>% 
  summarise(
    start = min(ADM_IN),
    end   = max(ADM_OUT),
    .groups = "drop"
  ) %>% 
  ungroup()

#missing
miss0 <- dev_select %>% 
  filter(!PID %in% adm_dev$PID)

### to log file ###
miss_n <- n_distinct(miss0$CPR)
cat('N unique patients with no device admission', miss_n)

adm_comb <- adm_dev %>% 
  arrange(n) %>% 
  distinct(CPR, .keep_all = T) %>% 
  left_join(doubles, by = 'PID') %>% 
  transmute(PID, CPR,
            DEV_IN = coalesce(start, ADM_IN),
            DEV_DATE,
            DEV_OUT = coalesce(end, ADM_OUT), PROCS
  ) %>% 
  ungroup() %>% 
  unnest_wider(PROCS, names_sep = "_")

write_tsv(adm_comb, snakemake@output$adm_out)

