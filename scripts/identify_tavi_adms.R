library(tidyverse)

adm_path <- snakemake@input$adm
pop_path <- snakemake@input$pop0

adm <- read_tsv(adm_path, col_types = cols())
pop <- read_tsv(pop_path, col_types = cols())

#direct log file
log <- file(snakemake@log[['check0']], 'wt')
sink(log)

pop1 <- pop %>% 
  select(PID, CPR, PROC_YMD, AVR_SKS) %>% 
  mutate(PROC_YMD = ymd_hms(PROC_YMD, tz = 'CET')) %>% 
  group_by(CPR) %>% 
  add_count(name = 'CPR_COUNT') %>% 
  ungroup()

pop_n <- n_distinct(pop1$CPR)
cat('N unique patients undergoing AVR:', pop_n, "\n")

obs_win <- pop1 %>% 
  summarise(obs_start = min(PROC_YMD),
            obs_end = max(PROC_YMD)
            )

obs_win

tavi_pop <- pop1 %>% 
  filter(str_starts(AVR_SKS, 'KFMD14'))

tavi_n <- n_distinct(tavi_pop$CPR)
cat('\nN unique patients undergoing TAVI:', tavi_n)

tavi1 <- pop1 %>% 
  filter(CPR_COUNT == 1, str_detect(AVR_SKS, 'KFMD14'))

tavi2 <- pop1 %>% 
  filter(CPR_COUNT != 1) %>% 
  arrange(PROC_YMD) %>% 
  distinct(CPR, .keep_all = T) %>% 
  filter(str_detect(AVR_SKS, 'KFMD14')) #exclude patient whose first procedure was not tavi

tavi_comb <- bind_rows(tavi1, tavi2) %>% 
  transmute(PID,
            CPR,
            TAVI_YMD = as.Date(PROC_YMD)
            )

viv <- pop %>% 
  filter(str_starts(AVR_SKS, 'KFMD14'), !PID %in% tavi_comb$PID)

viv_n <- n_distinct(viv$PID)
cat('\nN unique patients excluded owing to ViV:', viv_n)

adm_tavi <- adm %>% 
  filter(CPR %in% tavi_comb$CPR) %>% 
  mutate(ADM_IN = ymd_hms(ADM_IN, tz = 'CET'),
         ADM_OUT = ymd_hms(ADM_OUT, tz = 'CET')
  ) %>% 
  full_join(tavi_comb, by = c('PID', 'CPR')) %>% 
  filter(TAVI_YMD %within% interval(as.Date(ADM_IN), as.Date(ADM_OUT))) %>% 
  group_by(CPR) %>% 
  add_count()

# missing
miss0 <- tavi_comb %>% 
  filter(!CPR %in% adm_tavi$CPR)

### to log file ###
miss_n <- n_distinct(miss0$CPR)
cat('\nN unique TAVI patients with no TAVI admission:', miss_n)

doubles <- adm_tavi %>% 
  filter(n>1) %>% 
  arrange(PID, ADM_IN, ADM_OUT) %>% 
  group_by(PID) %>% 
  mutate(time_diff = as.numeric(difftime(ADM_IN, lag(ADM_OUT), units = 'hours')),
         new_group = if_else(is.na(time_diff) | time_diff >= 5, 1, 0), #we concatenate admissions <5 hrs apart
         group_id = cumsum(new_group)
  ) %>% 
  group_by(PID, group_id) %>% 
  summarise(
    start = min(ADM_IN),
    end   = max(ADM_OUT),
    .groups = "drop"
  ) %>% 
  ungroup()

adm_comb <- adm_tavi %>% 
  arrange(n) %>% 
  distinct(CPR, .keep_all = TRUE) %>% 
  left_join(doubles, by = 'PID') %>% 
  transmute(PID, CPR,
            TAVI_IN = coalesce(start, ADM_IN),
            TAVI_YMD,
            TAVI_OUT = coalesce(end, ADM_OUT)
  ) %>% 
  ungroup() %>%
  distinct() 

write_tsv(adm_comb, snakemake@output$adm_out)
