rule targets:
    input: "00-format/adm.tsv"
#           "01-clean/bio_slct.tsv",
#           "01-clean/med_slct.tsv",
#           "01-clean/di48.tsv",
#           "02-keys/ecg_keys.tsv",
#           "01-clean/ecg_text.tsv",
#           "01-clean/ekko_lvef.tsv",
#           "01-clean/avrs.tsv",
#           "03-maps/ekko_meta.tsv",
#           "01-clean/ekko_avs_svi.tsv"

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

#rule clean_biochem:
#   input:
#    bio_in = rules.format_colnames.output['bio_out']
#   output:
#    bioo = "01-clean/bio_slct.tsv",
#    plot = "plots/bio_per_year.pdf"
#   script: "scripts/clean_lab_tsts.R"

#rule select_drugs:
#   input:
#    med_in = rules.format_colnames.output['med_out']
#   output:
#    med_out = "01-clean/med_slct.tsv"
#   script: "scripts/select_medi.R"

#rule select_diags:
#   input:
#    diag = rules.format_colnames.output['diag_out']
#   output:
#    afib = "01-clean/di48.tsv",
#    devi = "01-clean/dz950.tsv"
#   script: "scripts/select_diags.R"
#
#rule clean_ecgs:
#   input:
#    ecg_in = rules.format_colnames.output['ecg_out']
#   output:
#    ecg_ent = "02-keys/ecg_keys.tsv",
#    ecg_out = "01-clean/ecg_wide.tsv",
#    ecg_key = "01-clean/ecg_date.tsv",
#    plot = "plots/ecg_npu_per_year.pdf"
#   script: "scripts/clean_ecg.R"
#
#rule inspect_freetxt:
#   input:
#    wide = rules.clean_ecgs.output['ecg_out']
#   output:
#    text = "01-clean/ecg_text.tsv"
#   script: "scripts/inspect_freetxt.R"
#
#rule extract_lvefs:
#   input:
#    st = rules.format_colnames.output['ekko_std'],
#    ms = rules.format_colnames.output['ekko_quant'],
#    fn = rules.format_colnames.output['ekko_find'],
#    cn = rules.format_colnames.output['ekko_con'],
#   output:
#    test = "01-clean/ekko_lvef.tsv"
#   script: "scripts/extract_lvefs.R"

#rule lvef_map:
#   input:
#    stud = rules.format_colnames.output['ekko_std']
#   output:
#    map = "03-maps/ekko_meta.tsv"
#   script: "scripts/format_ekko_stds.R"
#
#rule extract_vel_svi:
#   input:
#    meas = rules.format_colnames.output['ekko_quant']
#   output:
#    ekko = "02-keys/ekko_meas.tsv",
#    vel_sv = "01-clean/ekko_avs_svi.tsv"
#   script: "scripts/extract_avs_svi.R"
#
#rule clean_prcs:
#   input:
#    popu = rules.format_colnames.output['pop_out']
#   output:
#    pout = "01-clean/avrs.tsv"
#   script: "scripts/clean_avrs.R"
