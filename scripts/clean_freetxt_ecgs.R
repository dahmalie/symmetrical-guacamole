library(tidyverse)

ecg_path <- snakemake@input$ecg_prep

ecg_raw <- read_tsv(ecg_path, col_types = cols())

# wrangle and write
ecg_raw_key <- ecg_raw %>% 
  distinct(ECG_NPU, COMP_NAME)

write_tsv(ecg_raw_key, snakemake@output$ecg_key)

print('N distinct ECGs:') 
n_distinct(ecg_raw$ECG_ID)

# auto interpretation
auto_all <- ecg_raw %>% 
  filter(ECG_NPU == 21106)

print('N distinct ECGs with auto interpretation:') 
n_distinct(auto_all$ECG_ID)

auto <- ecg_raw %>% 
  filter(ECG_NPU == 21106, !is.na(ECG_TEXT))

print('N distinct ECGs with auto interpretation != NA:') 
n_distinct(auto$ECG_ID)

lbbb <- auto %>% 
  filter(str_detect(ECG_TEXT, 'Venstresidigt grenblok') | 
           str_detect(ECG_TEXT, 'venstresidigt grenblok')) %>% 
  mutate(LBBB = 1)

rbbb <- auto %>% 
  filter(str_detect(ECG_TEXT, 'jresidigt grenblok') |
           str_detect(ECG_TEXT, 'jresidigt grenblok')  ) %>% 
  mutate(RBBB = 1)

facs <- auto %>% 
  filter(str_detect(ECG_TEXT, 'asikul') | str_detect(ECG_TEXT, 'ascikul'))

facs_ant <- facs %>% 
  filter(str_detect(ECG_TEXT, 'nteriort')) %>% 
  mutate(LAFB = 1)

facs_other <- facs %>% 
  anti_join(facs_ant) %>% 
  mutate(LPFB = 1)

combine <- auto %>% 
  left_join(select(lbbb, ECG_ID, LBBB), by = 'ECG_ID') %>% 
  left_join(select(rbbb, ECG_ID, RBBB), by = 'ECG_ID') %>% 
  left_join(select(facs_ant, ECG_ID, LAFB), by = 'ECG_ID') %>% 
  left_join(select(facs_other, ECG_ID, LPFB), by = 'ECG_ID') %>% 
  select(PID, ECG_ID, 11:14) %>% 
  filter(LBBB == 1 | RBBB == 1 | LAFB == 1 | LPFB == 1) %>% 
  mutate_if(is.numeric, replace_na, replace = 0)

write_tsv(combine, snakemake@output$ecg_txt)
