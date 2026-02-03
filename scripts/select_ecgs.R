library(tidyverse)

cohort_path <- snakemake@input$cohort
ecg_path <- snakemake@input$ecg

cohort <- read_tsv(cohort_path, col_types = cols())
ecg <- read_tsv(ecg_path, col_types = cols())

ecg0 <- ecg %>% 
  filter(PID %in% cohort$PID) %>% 
  mutate(ECG_YMDHMS = ymd_hms(ECG_YMDHMS, tz = 'CET'))

# identify "usable" ecgs
complete <- ecg0 %>% 
  select(ECG_ID, ECG_NPU) %>% 
  arrange(ECG_NPU) %>% 
  mutate(ECG_NPU = as.character(ECG_NPU),
         ECG_NPU = paste0('x',ECG_NPU),
         n = 1) %>% 
  pivot_wider(names_from = 'ECG_NPU', values_from = n, values_fill = 0) %>% 
  mutate(sum = rowSums(across(c(x16985:x21343))))

# require that at least 12/16 values are extracted from SP (can be NA)
# we exclude 1489 analyses
select_ids <- complete %>% 
  filter(sum >= 12) %>% #arbitrary
  distinct(ECG_ID) %>% 
  pull(ECG_ID)

select_ecg <- ecg0 %>% 
  filter(ECG_ID %in% select_ids)

# post-procedural pre-TAVI ECG
select_ecg_prior <- select_ecg %>% 
  left_join(select(cohort, PID, TAVI_YMD, TAVI_OUT), by = 'PID', relationship = 'many-to-many') %>% 
  filter(as.Date(ECG_YMDHMS) %within% interval(TAVI_YMD, TAVI_OUT)) %>% 
  mutate(dist = time_length(ECG_YMDHMS %--% TAVI_OUT, 'days')) %>% 
#  filter(dist > 1) %>% 
  arrange(dist) %>% 
  distinct(PID, .keep_all = TRUE)

# ecg before TAVI, but closest to TAVI
ecg_id_analyze <- select_ecg_prior %>% 
  filter(dist < 150) %>%  # arbitrary as of now
  pull(ECG_ID)

select_ecg_prior_unique <- ecg0 %>% 
  filter(ECG_ID %in% ecg_id_analyze)

tab1 <- select_ecg_prior_unique %>% 
  select(PID, ECG_ID, ECG_NPU, ECG_TEXT) %>%
  arrange(ECG_NPU) %>% 
  mutate(ECG_NPU = as.character(ECG_NPU),
         ECG_NPU = paste0('x',ECG_NPU)
  ) %>% 
  pivot_wider(names_from = 'ECG_NPU', values_from = 'ECG_TEXT', values_fill = 'TX')

write_tsv(tab1, snakemake@output$prior)
