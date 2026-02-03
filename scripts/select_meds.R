library(tidyverse)

cohort_path <- snakemake@input$cohort_in
med_path <- snakemake@input$med_in

cohort <- read_tsv(cohort_path, col_types = cols())
med <- read_tsv(med_path, col_types = cols()) 

### medication (descrete variables)
# for co-morbidities we use:
#A10: Drugs used in diabetes
#B01A: Anti-thrombotic
#C01AA05: Digoxin
#C01BD01: Amiodarone
#C03: Diuretics
#C07: Beta-blockers
#C08DA01: Verapamil
#C08CA01: Amlodipin
#C08CA02: Felodipin
#C08: Calcium channel blockers
#C09: RAAS
#C10: Lipidmodifying agents

med_cohort <- med %>% 
  filter(PID %in% cohort$PID) %>% 
  filter(str_starts(ATC_CODE, '(A10|B01A|C01AA05|C01BD01|C03|C07|C08|C09|C10)'),
         !str_starts(ATC_CODE, '(A10AB05|B01AX|B01AB|B01AC07|B01AC16|B01AC30|B01AD)') 
  ) %>%  # exclude heparins, arixtra, dipyridamol, and orisantin, NovoRapid 
  transmute(PID, CPR, ORD_DATE = ymd_hms(ORD_DATE, tz = 'CET'), ATC_CODE) %>% 
  left_join(select(cohort, PID, TAVI_YMD), by = 'PID', relationship = 'many-to-many') %>% 
  mutate(dist = time_length(TAVI_YMD %--% as.Date(ORD_DATE), 'years')) %>% 
  filter(ORD_DATE < TAVI_YMD & dist > -1) 


med_tbl <- med_cohort %>% 
  filter(str_starts(ATC_CODE, '(C01AA05|C01BD01|C07)')) %>% 
  mutate(ATC_SHORT = case_when(str_starts(ATC_CODE, 'C01A') ~ 'Digoxin',
                               str_starts(ATC_CODE, 'C01B') ~ 'Amiodarone',
                               str_starts(ATC_CODE, 'C07') ~ 'BB')
         ) %>% 
  distinct(PID, ATC_SHORT) %>% 
  mutate(ATC_SHORT = fct_infreq(ATC_SHORT), n = 1) %>% 
  arrange(ATC_SHORT) %>% 
  pivot_wider(names_from = ATC_SHORT, values_from = n, values_fill = 0)


write_tsv(med_tbl, snakemake@output$med_out)



