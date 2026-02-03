rule targets:
    input: "00-format/adm.tsv",
           "01-format/ecg_auto.tsv",
           "01-format/tavi_adms.tsv",
           "01-format/dev_adms.tsv",
           "03-cohort/baseline.tsv",
           "03-cohort/ecgs_prior.tsv",
           "03-cohort/meds_prior.tsv",
           "04-tbls/tbl1.tsv",
           "04-tbls/tbl2.tsv"

rule format_colnames:
   input:
    adm = "../../data/raw/DD3/indlaeggelser.csv",
    popu = "../../data/raw/DD3/population.csv",
    ecg = "../../data/raw/DD2/ekg.csv",
    pm = "../../data/raw/DD3/final/pacemaker.csv",
    med = "../../data/raw/DD3/medicin.csv",
   output:
    adm_out = "00-format/adm.tsv",
    pop_out = "00-format/population.tsv",
    ecg_out = "00-format/ecg.tsv",
    pm_rename = "00-format/devices.tsv",
    med_out = "00-format/medication.tsv",
   log:
    check0 = "logs/00-counts.txt"
   script: "scripts/format_colnames.R"

rule format_free_txt:
   input: 
    ecg_prep = rules.format_colnames.output['ecg_out'],
   output:
    ecg_key = "02-keys/ecgs.tsv",
    ecg_txt = "01-format/ecg_auto.tsv"
   script: "scripts/clean_freetxt_ecgs.R"

rule identify_tavi_adms:
   input:
    adm = rules.format_colnames.output['adm_out'],
    pop0 = rules.format_colnames.output['pop_out']
   output:
    adm_out = "01-format/tavi_adms.tsv",
   log:
    check0 = "logs/01-tavi-counts.txt"
   script: "scripts/identify_tavi_adms.R"

rule identify_dev_adms:
   input:
    adm = rules.format_colnames.output['adm_out'],
    dev = rules.format_colnames.output['pm_rename']
   output:
    key = "02-keys/device.tsv",
    adm_out = "01-format/dev_adms.tsv",
   log:
    check0 = "logs/01-dev-counts.txt"
   script: "scripts/identify_dev_adms.R"

rule define_cohort:
   input:
    pop0 = rules.format_colnames.output['pop_out'],
    tavi = rules.identify_tavi_adms.output['adm_out'],
    dev = rules.identify_dev_adms.output['adm_out']
   output:
    cohort = "03-cohort/baseline.tsv",
   log:
    check0 = "logs/03-counts.txt"
   script: "scripts/define_cohort.R"

rule prepare_ecg_tbl:
   input:
     cohort = rules.define_cohort.output['cohort'],
     ecg = rules.format_colnames.output['ecg_out']
   output:
     prior = "03-cohort/ecgs_prior.tsv"
   script: "scripts/select_ecgs.R"

rule prepare_med_tbl:
   input:
     cohort_in = rules.define_cohort.output['cohort'],
     med_in = rules.format_colnames.output['med_out']
   output:
     med_out = "03-cohort/meds_prior.tsv"
   script: "scripts/select_meds.R"

rule write_tbl1:
   input:
     cohort_in = rules.define_cohort.output['cohort'],
     med_in = rules.prepare_med_tbl.output['med_out']
   output:
     tbl1 = "04-tbls/tbl1.tsv"
   script: "scripts/write_tbl1.R"

rule write_tbl2:
   input:
     cohort_in = rules.define_cohort.output['cohort'],
     ecgs = rules.prepare_ecg_tbl.output['prior'],
     ecg_txt = rules.format_free_txt.output['ecg_txt']
   output:
     tbl2 = "04-tbls/tbl2.tsv",
     tbl3 = "04-tbls/tbl3.tsv"
   log:
     check0 = "logs/04-chisq.txt"
   script: "scripts/write_tbl2.R"

