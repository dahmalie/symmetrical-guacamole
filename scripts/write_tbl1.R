library(tidyverse)

cohort_path <- snakemake@input$cohort_in
med_path <- snakemake@input$med_in

cohort <- read_tsv(cohort_path, col_types = cols())
med <- read_tsv(med_path, col_types = cols())

cohort1 <- cohort %>% 
  transmute(PID, TAVI_YMD, 
            AGE_TAVI = time_length(DOB %--% TAVI_YMD, 'years'),
            GROUP,
            MALE = case_when(SEX == 'Mand' ~ 1,
                             SEX == 'Kvinde' ~ 0)
            ) %>% 
  left_join(med, by = 'PID') %>% 
  mutate(BB = if_else(is.na(BB), 0, BB),
         Digoxin = if_else(is.na(Digoxin), 0, Digoxin),
         Amiodarone = if_else(is.na(Amiodarone), 0, Amiodarone)
         )

tbl1_bg <- cohort1 %>% 
  group_by(GROUP) %>% 
  summarise(mean_age = mean(AGE_TAVI),
            n = n(),
            n_male = sum(MALE),
            frac_m = n_male/n,
            bb = sum(BB),
            frac_bb = bb/n,
            dig = sum(Digoxin),
            frac_dig = dig/n,
            am = sum(Amiodarone),
            am_frac = am/n
            ) %>% 
  ungroup() %>% 
  mutate(GROUP = fct_inorder(GROUP)) %>% 
  pivot_longer(-GROUP) %>% 
  mutate(value = round(value, 3)) %>% 
  pivot_wider(names_from = 'GROUP', values_from = 'value') 

tbl1_all <- cohort1 %>% 
  summarise(mean_age = mean(AGE_TAVI),
            n = n(),
            n_male = sum(MALE),
            frac_m = n_male/n,
            bb = sum(BB),
            frac_bb = bb/n,
            dig = sum(Digoxin),
            frac_dig = dig/n,
            am = sum(Amiodarone),
            am_frac = am/n
  ) %>% 
  ungroup() %>% 
  mutate(GROUP = 'All') %>% 
  mutate(GROUP = fct_inorder(GROUP)) %>% 
  pivot_longer(-GROUP) %>% 
  mutate(value = round(value, 3)) %>% 
  pivot_wider(names_from = 'GROUP', values_from = 'value') 

comb <- tbl1_bg %>% 
  left_join(tbl1_all, by = 'name')

write_tsv(comb, snakemake@output$tbl1)
