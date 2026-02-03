library(tidyverse)

cohort_path <- snakemake@input$cohort_in
ecgs_path <- snakemake@input$ecgs
ecg_txt_path <- snakemake@input$ecg_txt

cohort <- read_tsv(cohort_path, col_types = cols())
ecgs <- read_tsv(ecgs_path, col_types = cols())
ecg_txt <- read_tsv(ecg_txt_path, col_types = cols())

#direct log file
log <- file(snakemake@log[['check0']], 'wt')
sink(log)

cohort1 <- cohort %>% 
  select(PID, GROUP) %>% 
  left_join(ecgs, by = 'PID') %>% 
  left_join(select(ecg_txt, -PID), by = c('ECG_ID')) %>% 
#  select(PID, GROUP, ECG_ID, x21094, x21095, x21096, LBBB, RBBB, LAFB, LPFB) %>% 
  transmute(PID, GROUP, ECG_ID,
            Brady = if_else(x21094 < 50, 1, 0),
            AVB = if_else(x21095 > 240, 1, 0),
            BBB = if_else(x21096 > 120, 1, 0),
            LBBB = if_else(is.na(LBBB) & !is.na(ECG_ID), 0, LBBB),
            RBBB = if_else(is.na(RBBB) & !is.na(ECG_ID), 0, RBBB),
            LAFB = if_else(is.na(LAFB) & !is.na(ECG_ID), 0, LAFB),
            LPFB = if_else(is.na(LPFB) & !is.na(ECG_ID), 0, LPFB)
            )

tbl2 <- cohort1 %>% 
  group_by(GROUP) %>% 
  summarize(miss = sum(is.na(ECG_ID)),
            n = n(),
            miss_frac = miss/n,
            brady = sum(Brady, na.rm = TRUE),
            frac_brad = brady/n,
            avb = sum(AVB, na.rm = TRUE),
            frac_avb = avb/n,
            bbb = sum(BBB, na.rm = TRUE),
            frac_bbb = bbb/n,
            lbbb = sum(LBBB, na.rm = TRUE),
            frac_lbbb = lbbb/bbb,
            rbbb = sum(RBBB, na.rm = TRUE),
            frac_rbbb = rbbb/bbb,
            unspec = bbb-lbbb-rbbb,
            frac_unspec = unspec/bbb
            ) %>% 
  mutate(GROUP = fct_inorder(GROUP)) %>% 
  pivot_longer(-GROUP) %>% 
  mutate(value = round(value, 3)) %>% 
  pivot_wider(names_from = 'GROUP', values_from = 'value')

tbl2_t <- cohort1 %>% 
  summarize(miss = sum(is.na(ECG_ID)),
            n = n(),
            miss_frac = miss/n,
            brady = sum(Brady, na.rm = TRUE),
            frac_brad = brady/n,
            avb = sum(AVB, na.rm = TRUE),
            frac_avb = avb/n,
            bbb = sum(BBB, na.rm = TRUE),
            frac_bbb = bbb/n,
            lbbb = sum(LBBB, na.rm = TRUE),
            frac_lbbb = lbbb/bbb,
            rbbb = sum(RBBB, na.rm = TRUE),
            frac_rbbb = rbbb/bbb,
            unspec = bbb-lbbb-rbbb,
            frac_unspec = unspec/bbb
  ) %>% 
  mutate(GROUP = 'All') %>% 
  pivot_longer(-GROUP) %>% 
  mutate(value = round(value, 3)) %>% 
  pivot_wider(names_from = 'GROUP', values_from = 'value')

tbl2_comb <- tbl2 %>% 
  left_join(tbl2_t, by = 'name')

write_tsv(tbl2_comb, snakemake@output$tbl2)

abnormal <- cohort1 %>% 
  filter(!is.na(ECG_ID)) %>% 
  transmute( GROUP, Brady,
        AVB = if_else(is.na(AVB), 0, AVB),
        BBB,
        ABN = if_else(Brady + AVB + BBB >= 1, 1, 0)
         )

abnormal_tbl <- abnormal %>% 
  group_by(GROUP) %>% 
  summarize(abn = sum(ABN),
            n = n(),
            abn_frac = abn/n,
            norm = n - abn,
            norm_frac = norm/n) %>% 
  mutate(GROUP = fct_inorder(GROUP)) %>% 
  pivot_longer(-GROUP) %>% 
  mutate(value = round(value, 3)) %>% 
  pivot_wider(names_from = 'GROUP', values_from = 'value')

abnormal_tbl2 <- abnormal %>% 
  summarize(abn = sum(ABN),
            n = n(),
            abn_frac = abn/n,
            norm = n - abn,
            norm_frac = norm/n) %>% 
  mutate(GROUP = 'All') %>% 
  pivot_longer(-GROUP) %>% 
  mutate(value = round(value, 3)) %>% 
  pivot_wider(names_from = 'GROUP', values_from = 'value')

abn_comb <- left_join(abnormal_tbl, abnormal_tbl2, by = 'name')

write_tsv(abn_comb, snakemake@output$tbl3)

chisq.test(table(abnormal$GROUP, abnormal$ABN))
            