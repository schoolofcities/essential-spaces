library(tidyverse)

df <- read.csv("equity_data/ct-data-all-csdjoin.csv")

weighted.mean(df$Total_count, df$Popu_2021)



r <- df %>% 
  mutate(across(everything(), ~replace_na(., 0))) %>%
  mutate(
    pop_immig = Popu_2021 * Immigrant. / 100,
    pop_immig_not = Popu_2021 * (100 - Immigrant.) / 100,
    pop_vm = Popu_2021 * VM. / 100,
    pop_vm_not = Popu_2021 * (100 - VM.) / 100,
    pop_spf = Popu_2021 * X1.ParentFam. / 100,
    pop_spf_not = Popu_2021 * (100 -  X1.ParentFam.) / 100,
    pop_mbm = Popu_2021 * MBM. / 100,
    pop_mbm_not = Popu_2021 * (100 - MBM.) / 100,
    pop_lim = Popu_2021 * LIM. / 100,
    pop_lim_not = Popu_2021 * (100 - LIM.) / 100,
    pop_wkp = Popu_2021 * X.ofWP / 100,
    pop_wkp_not = Popu_2021 * (100 - X.ofWP) / 100,
    pop_stw = Popu_2021 * ShortTerm. / 100,
    pop_stw_not = Popu_2021 * (100 -ShortTerm.) / 100,
    pop_ufh = Popu_2021 * X.Affordable / 100,
    pop_ufh_not = Popu_2021 * (100 - X.Affordable) / 100,
    pop_chn = Popu_2021 * X.CHN / 100,
    pop_chn_not = Popu_2021 * (100 - X.CHN) / 100,
    pop_neet = Popu_2021 * Neet. / 100,
    pop_neet_not = Popu_2021 * (100 - Neet.) / 100,
  ) %>%
  group_by(
    CDNAME
  ) %>%
  summarise(
    total_pop = weighted.mean(Total_count, Popu_2021, na.rm = TRUE),
    immig = weighted.mean(Total_count, pop_immig, na.rm = TRUE),
    immig_not = weighted.mean(Total_count, pop_immig_not, na.rm = TRUE),
    vm = weighted.mean(Total_count, pop_vm, na.rm = TRUE),
    vm_not = weighted.mean(Total_count, pop_vm_not, na.rm = TRUE),
    spf = weighted.mean(Total_count, pop_spf, na.rm = TRUE),
    spf_not = weighted.mean(Total_count, pop_spf_not, na.rm = TRUE),
    mbm = weighted.mean(Total_count, pop_mbm, na.rm = TRUE),
    mbm_not = weighted.mean(Total_count, pop_mbm_not, na.rm = TRUE),
    lim = weighted.mean(Total_count, pop_lim, na.rm = TRUE),
    lim_not = weighted.mean(Total_count, pop_lim_not, na.rm = TRUE),
    pop_wkp = weighted.mean(Total_count, pop_wkp, na.rm = TRUE),
    pop_wkp_not = weighted.mean(Total_count, pop_wkp_not, na.rm = TRUE),
    pop_stw = weighted.mean(Total_count, pop_stw, na.rm = TRUE),
    pop_stw_not = weighted.mean(Total_count, pop_stw_not, na.rm = TRUE),
    pop_neet = weighted.mean(Total_count, pop_neet, na.rm = TRUE),
    pop_neet_not = weighted.mean(Total_count, pop_neet_not, na.rm = TRUE),
    pop_ufh = weighted.mean(Total_count, pop_ufh, na.rm = TRUE),
    pop_ufh_not = weighted.mean(Total_count, pop_ufh_not, na.rm = TRUE),
    pop_chn = weighted.mean(Total_count, pop_chn, na.rm = TRUE),
    pop_chn_not = weighted.mean(Total_count, pop_chn_not, na.rm = TRUE),
  ) %>%
  { as.data.frame(t(.)) } %>%
  `colnames<-`(.[1, ]) %>%       # Set first row as column names
    slice(-1)  %>%
  mutate(across(everything(), as.numeric))   


q <- df %>%
  # Calculate quintiles
  mutate(quintile = ntile(Equity.Index, 5)) %>%
  group_by(quintile, CDNAME) %>%
  summarise(weighted_avg = weighted.mean(Total_count, Popu_2021, na.rm = TRUE)) %>%
  pivot_wider(names_from = CDNAME, values_from = weighted_avg) %>%
  select(-1)
q <- as.data.frame(q)
rownames(q) <- q$quintile
q <- q[, -1]


write.csv(bind_rows(q, r), "summary_data/avg_total_region.csv")




r <- df %>% 
  mutate(across(everything(), ~replace_na(., 0))) %>%
  mutate(
    pop_immig = Popu_2021 * Immigrant. / 100,
    pop_immig_not = Popu_2021 * (100 - Immigrant.) / 100,
    pop_vm = Popu_2021 * VM. / 100,
    pop_vm_not = Popu_2021 * (100 - VM.) / 100,
    pop_spf = Popu_2021 * X1.ParentFam. / 100,
    pop_spf_not = Popu_2021 * (100 -  X1.ParentFam.) / 100,
    pop_mbm = Popu_2021 * MBM. / 100,
    pop_mbm_not = Popu_2021 * (100 - MBM.) / 100,
    pop_lim = Popu_2021 * LIM. / 100,
    pop_lim_not = Popu_2021 * (100 - LIM.) / 100,
    pop_wkp = Popu_2021 * X.ofWP / 100,
    pop_wkp_not = Popu_2021 * (100 - X.ofWP) / 100,
    pop_stw = Popu_2021 * ShortTerm. / 100,
    pop_stw_not = Popu_2021 * (100 -ShortTerm.) / 100,
    pop_ufh = Popu_2021 * X.Affordable / 100,
    pop_ufh_not = Popu_2021 * (100 - X.Affordable) / 100,
    pop_chn = Popu_2021 * X.CHN / 100,
    pop_chn_not = Popu_2021 * (100 - X.CHN) / 100,
    pop_neet = Popu_2021 * Neet. / 100,
    pop_neet_not = Popu_2021 * (100 - Neet.) / 100,
  ) %>%
  summarise(
    total_pop = weighted.mean(Total_count, Popu_2021, na.rm = TRUE),
    immig = weighted.mean(Total_count, pop_immig, na.rm = TRUE),
    immig_not = weighted.mean(Total_count, pop_immig_not, na.rm = TRUE),
    vm = weighted.mean(Total_count, pop_vm, na.rm = TRUE),
    vm_not = weighted.mean(Total_count, pop_vm_not, na.rm = TRUE),
    spf = weighted.mean(Total_count, pop_spf, na.rm = TRUE),
    spf_not = weighted.mean(Total_count, pop_spf_not, na.rm = TRUE),
    mbm = weighted.mean(Total_count, pop_mbm, na.rm = TRUE),
    mbm_not = weighted.mean(Total_count, pop_mbm_not, na.rm = TRUE),
    lim = weighted.mean(Total_count, pop_lim, na.rm = TRUE),
    lim_not = weighted.mean(Total_count, pop_lim_not, na.rm = TRUE),
    pop_wkp = weighted.mean(Total_count, pop_wkp, na.rm = TRUE),
    pop_wkp_not = weighted.mean(Total_count, pop_wkp_not, na.rm = TRUE),
    pop_stw = weighted.mean(Total_count, pop_stw, na.rm = TRUE),
    pop_stw_not = weighted.mean(Total_count, pop_stw_not, na.rm = TRUE),
    pop_neet = weighted.mean(Total_count, pop_neet, na.rm = TRUE),
    pop_neet_not = weighted.mean(Total_count, pop_neet_not, na.rm = TRUE),
    pop_ufh = weighted.mean(Total_count, pop_ufh, na.rm = TRUE),
    pop_ufh_not = weighted.mean(Total_count, pop_ufh_not, na.rm = TRUE),
    pop_chn = weighted.mean(Total_count, pop_chn, na.rm = TRUE),
    pop_chn_not = weighted.mean(Total_count, pop_chn_not, na.rm = TRUE),
  ) %>%
  { as.data.frame(t(.)) } %>%
  `colnames<-`(.[1, ]) %>%       # Set first row as column names
  slice(-1)  %>%
  mutate(across(everything(), as.numeric))  


q <- df %>%
  # Calculate quintiles
  mutate(quintile = ntile(Equity.Index, 5)) %>%
  group_by(quintile) %>%
  summarise(weighted_avg = weighted.mean(Total_count, Popu_2021, na.rm = TRUE)) %>%
  select(-1)
q <- as.data.frame(q)

write.csv(bind_rows(q, r), "summary_data/avg_total_overall.csv")
# 