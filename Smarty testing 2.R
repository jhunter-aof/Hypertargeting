# Smartly testing 2

smarty_dataframe <- read.csv("Smarty output 20230808.tsv", sep = "\t")

smarty_dataframe <- smarty_dataframe %>% 
  mutate_at(which(str_starts(names(smarty_dataframe), "smarty_components_")), str_to_upper) %>% 
  mutate(
    smarty_street = paste(smarty_components_primary_number, smarty_components_street_name, smarty_components_street_suffix)
  )

# Look at zip mismatches
smarty_dataframe %>% 
  filter(smarty_results == 1 & zip != smarty_components_zipcode) %>% 
  select(street, smarty_street, 
       city, smarty_components_city_name, 
       state, smarty_components_state_abbreviation,
       zip, smarty_components_zipcode) %>% 
  View("ZIP changes")

# Look at city mismatches
smarty_dataframe %>% 
  filter(smarty_results == 1 & city != smarty_components_city_name) %>% 
  select(street, smarty_street, 
         city, smarty_components_city_name, 
         state, smarty_components_state_abbreviation,
         zip, smarty_components_zipcode) %>% 
  View("City changes")

# Look at state mismatches
smarty_dataframe %>% 
  filter(smarty_results == 1 & state != smarty_components_state_abbreviation) %>% 
  select(street, smarty_street, 
         city, smarty_components_city_name, 
         state, smarty_components_state_abbreviation,
         zip, smarty_components_zipcode) %>% 
  View("State changes")
