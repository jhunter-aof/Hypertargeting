# source(setup.R)
# source(app_data.R)

# UPDATE 7-17-2023 ---
# Add filter: All CLO-based/digital working capital applications to date
# Add attributes:
  # Affinity group flag (yes/no) (ie black, hispanic, LMI or Low-income)
# ---

# This script should generate the data asked of point 1 on this page:
# https://opportunityfund.atlassian.net/wiki/spaces/DPS/pages/2442625025/Hypertargeting+Modeling+Phase+Data+Sharing+and+Compliance

# We send Enigma the business name/DBA, physical address, and application 
# date for applicants who applied for $50k+ in working capital.

dat %>% 
  filter(
      (segment_2022 != "Public-Private Partnerships" | is.na(segment_2022)) &
      partner_id_c != "CRFUSA"
    & !open_scorecard_c
    & requested_loan_amount >= 50000) %>% 
  select(
    cohort_created_date,
    business_name,
    street,
    state,
    state_final,
    zip_text,
    requested_loan_amount
  ) %>% 
  rename(
    application_date = cohort_created_date
  )
