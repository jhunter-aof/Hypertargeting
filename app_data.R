## Get apps_detail ----
# This used to be the https://github.com/Accion-Opportunity-Fund/axp-weekly-reporting query
apps_detail <- sqlQuery(
  con,
  "
with json_data as (
	select
		jsc.EventData_applicantID,
		jsc.[EventData_diagnosticReport_offerDiagnostics_offerAmount],
		jsc.[EventData_diagnosticReport_offerDiagnostics_cappedRates_12],
		jsc.[EventData_diagnosticReport_offerDiagnostics_cappedRates_24],
		jsc.[EventData_diagnosticReport_offerDiagnostics_cappedRates_36],
		jsc.[EventData_diagnosticReport_offerDiagnostics_cappedRates_60],
		jsc.[EventData_underwriterReport_personalIncomeUsed] as personal_income_used, /*flag if personal income was used in final loan amont*/
    jsc.[EventData_diagnosticReport_offerDiagnostics_mlaScratchpad_annualPersonalIncome] as total_personal_income, /*total personal income (haven't validated this field but fairly certain)*/
    jsc.[EventData_diagnosticReport_offerDiagnostics_mlaScratchpad_maxPersIncomeLoanBridge] as amt_added_to_offer_from_personal_income  /*amount added to offer amount based on pers income (haven't validated this field but fairly certain)*/
	from
		[DataMapping].[dbo].[Json_scorecard] JSC INNER JOIN
			(
				select 
					EventData_applicantId,
					MAX(EventData_timestamp) as EventData_timestamp
				from [DataMapping].[dbo].[Json_scorecard]
				where [EventData_decisionReport_decision] <> 'COMMREQ'
				group by EventData_applicantId
			) LastRun 
			on 
				JSC.EventData_applicantID = LastRun.EventData_applicantID 
				and LastRun.EventData_timestamp = JSC.EventData_timestamp
)

select  
	clo_events.[App_Id]
	,clo_events.[Loan Number]
	,clo_events.[Status]
	,clo_events.[Status Order]
	,clo_events.[Date]
	,clo_events.[Cohort_CreatedDate] AS [Cohort (Created Date)]
	,apps.Open_Scorecard__c
	,apps.Requested_Loan_Amount__c as [requested_loan_amount]
	,apps.genesis__CL_Purpose__c
	,apps.partner_id__c
	,loans.[Segment 2022]
	,loans.[Sub Segment 2022]
	,loans.[First Note Loan Amount]
	,apps.Calculated_Offer_Amount__c
	,json_data.[EventData_diagnosticReport_offerDiagnostics_offerAmount] AS offer_amount
	,json_data.[EventData_diagnosticReport_offerDiagnostics_cappedRates_12] as offer_rate_12_month
	,json_data.[EventData_diagnosticReport_offerDiagnostics_cappedRates_24] as offer_rate_24_month
	,json_data.[EventData_diagnosticReport_offerDiagnostics_cappedRates_36] as offer_rate_36_month
	,json_data.[EventData_diagnosticReport_offerDiagnostics_cappedRates_60] as offer_rate_60_month
	,json_data.personal_income_used
	,json_data.total_personal_income
	,json_data.amt_added_to_offer_from_personal_income
	,acct.Id as 'account_id'
	,acct.[Name] as 'business_name'
	,acct.[BillingStreet] as 'street'
	,acct.[BillingCity] as 'city'
	,acct.[BillingState] AS [State]
	,CAST(acct.[BillingPostalCode] AS varchar) AS [zip_text]
	,acct.Annualized_Cash_Flow__c AS 'revenue'
	,acct.Annual_Profit_Verified__c as 'profit'
	,acct.[Previous_Year_Gross_Annual_Sale__c] as 'prev_year_gross_sales'
from
	[DataMart].[dbo].[CLO_Events_Table] clo_events
	left join CDATA.[SF-CLS-Prod].Genesis__applications__c apps
		on clo_events.App_Id = apps.Id
	left join json_data
		on clo_events.App_Id = json_data.EventData_applicantId
	left join DataMart.dbo.Loans loans
		on clo_events.[Loan Number] = loans.[Current Loan Number]
	left join [CDATA].[SF-CLS-PROD].[Account] acct
		on apps.[genesis__Account__c] = acct.[Id]
  ")

apps_detail <- clean_names(apps_detail) %>% 
  mutate(
    date = as.Date(date),
    cohort_created_date = as.Date(cohort_created_date),
    revenue = pmax(revenue, profit, na.rm = T)
  )

## Get credit_data ----

credit_data <- sqlQuery(con, read_file("C:/Users/jhunter/OneDrive - Accion Opportunity Fund Inc/Documents/R/Flexible Loan Segment Explorer/colins_credit_query.txt"))
credit_data <- clean_names(credit_data)

## Get zip_codes ----
zip_codes <- read_csv("C:/Users/jhunter/OneDrive - Accion Opportunity Fund Inc/Documents/R/Acquisition Analytics/us_zip_codes.csv")

## Merge apps_detail, credit_data, and zip_codes ----
dat <- apps_detail %>% 
  group_by(app_id) %>% 
  slice_max(status_order) %>% 
  mutate(
    zip_text = as.character(zip_text)) %>% 
  left_join(zip_codes)

# this is to adjust for the ET table which gives us too many outputs
# it's not a perfect fix but it's close
dat <- distinct(dat)

dat <- ungroup(dat)
