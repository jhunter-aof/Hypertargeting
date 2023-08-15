# parsing Smartly output

library(rjson)

smartly_json <- fromJSON(file = "Smartly test run/output/a5n3g00000009aBAAQ.json")

smartly_dataframe <- data.frame(
  app_id = as.character(),
  smartly_street = as.character(),
  smartly_city = as.character(),
  smartly_state = as.character(),
  smartly_zip = as.character(),
  smartly_matchcode = as.character()
)

for(smartly_file_name in list.files("Smartly test run/output/")){
  
  smartly_json <- fromJSON(file = paste0("Smartly test run/output/", smartly_file_name))
  
  if(length(smartly_json) > 0){
    smartly_dataframe <- rbind(
      smartly_dataframe,
      data.frame(
        app_id = str_sub(smartly_file_name, end = -6),
        smartly_street = paste(
          str_to_upper(smartly_json[[1]]$components$primary_number),
          str_to_upper(smartly_json[[1]]$components$street_name),
          str_to_upper(smartly_json[[1]]$components$street_suffix)
        ),
        smartly_city = str_to_upper(smartly_json[[1]]$components$city_name),
        smartly_state = str_to_upper(smartly_json[[1]]$components$state_abbreviation),
        smartly_zip = str_to_upper(smartly_json[[1]]$components$zipcode),
        smartly_matchcode = smartly_json[[1]]$analysis$dpv_match_code
      )
    )
  }
  
}

# Analyze ----

smartly_test <- smartly_dataframe %>% 
  left_join(
    export %>% 
      select(app_id, street, city, state_final, zip)
  ) %>% 
  select(
    app_id,
    street, smartly_street,
    city, smartly_city,
    state_final, smartly_state,
    zip, smartly_zip,
    smartly_matchcode
  )
