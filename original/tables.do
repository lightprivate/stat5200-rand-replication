
/*This file recreates the Tables for "The RAND Health Insurance Experiment, Three Decades Later" (Aron-Dine, Einav, Finkelstein)
*Published in the Journal of Economic Perspectives (Winter 2013)
IN ORDER TO RUN THIS FILE, A GLOBAL AND A LOCAL MUST BE SET AT THE TOP OF THE PROGRAM AS DIRECTED*/ 

clear all
capture program drop ArcElasticity
capture program drop ArcElasticity2
capture program drop myqreg
set more off

set seed 953980945
set matsize 4000

									*****Locals to Set*****
									
global home "replication"  			      // Set this global to the home directory containing the replication materials
										  //	The data should be stored in a subfolder of home (i.e. ${home}/AnalysisData)
local tables "Tables"	// Set this local to the sub-folder wwithin the home directory where table output should be directed
						// This folder must be created as a subfolder of home (i.e. ${home}/Tables)


			****Switches: If set equal to one, they will generate the content described****

scalar step1 = 1 /* Table 1: Plan summary statistics and refusal/attrition/completion */
scalar step2 = 1 /* Appendix Table 4: Covariate balance at completion */ 
scalar step3 = 1 /* Table 2: Effects on Utilization */
scalar step4 = 1 /* Table 4:  Elasticities (arc and usual) */
scalar step5 = 1 /* Appendix Table 1:  Replication of RAND results */
scalar step6 = 1 /* Appendix Table 3:  Covariate balance at assignment */
scalar step7 = 1 /* Appendix Table 2:  Quantile regressions */ 
scalar step8 = 1 /* Table 3 Rows 2 and 3: Sensitivity of Results to Additional Covariates and Bounding Exercise  */ 
scalar step9 = 1 /* Create file of refusers and leavers and append to final person x year file, obtains "reference" estimates, recodes mixed coins as 25% coins for this purpose */ 
scalar step10 = 1 /* Appendix Table 5: Extreme bounding analysis */
scalar step11 = 1 /* Table 3 Row 4: Lee Bounds w. Adjustment for Underreporting */


********************************************************************************************************************
/*Table 1*/
*********************************************************************************************************************
if step1 == 1 {

 use ${home}/AnalysisData/person_years.dta

	capture log close
	log using ${home}/`tables'/Table1PanelA.log, replace 

	**** Panel A ****
	
	* Average out-of-pocket share
	tabstat share_oop, by(rand_plan_group) statistics(mean)
	
	* For table notes:  obtain count of people with 100% v. 95% coins in first year
	count if site == 1 & year == 1 & (rand_plan_group == 5 | rand_plan_group == 6)

clear

use ${home}/AnalysisData/rand_initial_sample.dta

	*** Panel A ***

	* Sample counts (individuals)
	table rand_plan_group if refused == 0, c(freq)
	
	* Dayton enrollees 
	count if site == 1 
	
	* Sample counts: Families by Insurance Plan
	preserve
	* There are2 families with 3 members in one plan and a fourth in another
	* This code reassigns the outlier members to their family plan for the family-level analyses only
		replace rand_plan_group=5 if fam_identifier=="KG102600"
		replace rand_plan_group5=1 if fam_identifier=="KG102600"
		replace rand_plan_group3=0 if fam_identifier=="KG102600"
		replace rand_plan_group=6 if fam_identifier=="KG105854"
		replace rand_plan_group6=1 if fam_identifier=="KG105854"
		replace rand_plan_group1=0 if fam_identifier=="KG105854"

		drop if refused == 1
		collapse (mean) rand_plan_group, by(fam_identifier)
		label values rand_plan_group "rand_plan_group"
		table rand_plan_group, c(freq)
		count
	restore
	
	capture log close
	log using ${home}/RedoingRandMaster.log, append

	**** Panel B ****
	
	* Generate refuse_atrit var
	generate refuse_atrit = 0
	replace refuse_atrit = 1 if ever_atrit == 1 | refused == 1
	
	* Count Dayton exclusions
	count if site == 1
	count if refused == 0
	
	preserve
	drop if site == 1
		
		* Demean dummies (contact month b/c include refusers)
		quietly drop contact_month_site
		quietly generate contact_month_string = string(contact_month)
		quietly generate site_string = string(site)
		quietly egen contact_month_site_string = concat(contact_month_string site_string)
		quietly encode(contact_month_site_string), generate(contact_month_site)
		quietly	drop contact_month_site_string contact_month_string site_string
		quietly tabulate contact_month_site, generate(contact_month_site)
		foreach var of varlist contact_month_site* {
			egen mean_`var' = mean(`var')
			generate demeaned_`var' = `var' - mean_`var'
			drop mean_`var'
		}
		drop demeaned_contact_month_site

		table rand_plan_group, c(freq)
		tabstat refused refuse_atrit, statistics(mean) by(rand_plan_group)
		tabstat ever_atrit if refused == 0, statistics(mean) by(rand_plan_group)
		
		* Regressions
		local vars "refused ever_atrit refuse_atrit"
		foreach var of local vars {
		
			if "`var'" == "refused" | "`var'" == "refuse_atrit" {
				
			eststo:  quietly regress `var' rand_plan_group1 rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group6 rand_plan_group5 demeaned_contact_month_site*, nocons cluster(fam_identifier)
			foreach plan in rand_plan_group1 rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 {
					local `var'_`plan'=_b[`plan']
					di ``var'_`plan''
			}
				}
				
				
			if "`var'" == "ever_atrit" {
				eststo:  quietly regress `var' rand_plan_group1 rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group6 rand_plan_group5 demeaned_contact_month_site* if refused == 0, nocons cluster(fam_identifier) 
			foreach plan in rand_plan_group1 rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 {
					local ever_atrit_`plan'=_b[`plan']
					di `ever_atrit_`plan''
			}
	}	
		

			quietly test rand_plan_group1 == rand_plan_group2 == rand_plan_group3 == rand_plan_group4 == rand_plan_group5 == rand_plan_group6
			estadd scalar p_val_F = r(p)
			quietly test rand_plan_group1 == rand_plan_group5
			estadd scalar p_val_95 = r(p)
			quietly test rand_plan_group1 == rand_plan_group2
			estadd scalar p_val_25 = r(p)
			quietly test rand_plan_group2 == rand_plan_group5
			estadd scalar p_val_mid = r(p)   
			
	}
			
			* Refusal/Attrition for all plans:		
			foreach plan in rand_plan_group1 rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 {
			count if `plan'==1
			local N_`plan'=r(N)
			dis "`N_plan'"
				}
			
			*refused
			local num_refused= (`refused_rand_plan_group1')*(`N_rand_plan_group1') + (`refused_rand_plan_group2')*(`N_rand_plan_group2') + (`refused_rand_plan_group3')*(`N_rand_plan_group3') + (`refused_rand_plan_group4')*(`N_rand_plan_group4') + (`refused_rand_plan_group5')*(`N_rand_plan_group5') + (`refused_rand_plan_group6')*(`N_rand_plan_group6')
			local refused_allplans= `num_refused'/(`N_rand_plan_group1'+ `N_rand_plan_group2' + `N_rand_plan_group3' + `N_rand_plan_group4' + `N_rand_plan_group5' + `N_rand_plan_group6')
			di `refused_allplans'
		
			*attrited 
			local num_attrit= (`ever_atrit_rand_plan_group1')*(`N_rand_plan_group1') + (`ever_atrit_rand_plan_group2')*(`N_rand_plan_group2') + (`ever_atrit_rand_plan_group3')*(`N_rand_plan_group3') + (`ever_atrit_rand_plan_group4')*(`N_rand_plan_group4') + (`ever_atrit_rand_plan_group5')*(`N_rand_plan_group5') + (`ever_atrit_rand_plan_group6')*(`N_rand_plan_group6')
			local attrit_allplans= `num_attrit'/(`N_rand_plan_group1'+ `N_rand_plan_group2' + `N_rand_plan_group3' + `N_rand_plan_group4' + `N_rand_plan_group5' + `N_rand_plan_group6')
			di `attrit_allplans'
		
			*refused or attrited
			local num_refuse_atrit= (`refuse_atrit_rand_plan_group1')*(`N_rand_plan_group1') + (`refuse_atrit_rand_plan_group2')*(`N_rand_plan_group2') + (`refuse_atrit_rand_plan_group3')*(`N_rand_plan_group3') + (`refuse_atrit_rand_plan_group4')*(`N_rand_plan_group4') + (`refuse_atrit_rand_plan_group5')*(`N_rand_plan_group5') + (`refuse_atrit_rand_plan_group6')*(`N_rand_plan_group6')
			local refuse_atrit_allplans= `num_refuse_atrit'/(`N_rand_plan_group1'+ `N_rand_plan_group2' + `N_rand_plan_group3' + `N_rand_plan_group4' + `N_rand_plan_group5' + `N_rand_plan_group6')
			di `refuse_atrit_allplans'
		
		matrix define allplans=J(1,3,.)
		matrix allplans[1,1]=`refused_allplans'
		matrix allplans[1,2]=`attrit_allplans'
		matrix allplans[1,3]=`refuse_atrit_allplans'
		
		matrix colnames allplans= "refused" "ever_atrit" "refuse_atrit"
		matrix rownames allplans= "All Plans"
		
		esttab using ${home}/`tables'/Table1PanelB.csv, drop(demeaned_contact_month_site* o.demean*) replace se nostar stats(N p_val_F p_val_95 p_val_25 p_val_mid)
		esttab matrix(allplans) using ${home}/`tables'/Table1PanelB.csv, append
		
		eststo clear
		
	restore

	clear

}

*******************************************************************************************************************
/* Appendix Table 4 */
********************************************************************************************************************
if step2 == 1 {

use ${home}/AnalysisData/rand_initial_sample.dta

****
drop if refused == 1 | ever_atrit == 1 
****

	* Demean dummies
	quietly drop first_month_site
	quietly generate first_month_string = string(first_month)
	quietly generate site_string = string(site)
	quietly egen first_month_site_string = concat(first_month_string site_string)
	quietly encode(first_month_site_string), generate(first_month_site)
	quietly	drop first_month_site_string site_string first_month_string
	quietly tab first_month_site, generate(first_month_site)
	foreach var of varlist first_month_site* {
		quietly egen mean_`var' = mean(`var')
		quietly generate demeaned_`var' = `var' - mean_`var'
		drop mean_`var'
	}
	drop demeaned_first_month_site
	
	quietly _rmcollright rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 demeaned_first_month*
	local rhs `r(varlist)'

	* Panel A (Utilization variables)
	local util "hosp hosp_missing havemd havemd_missing mdexam mdexam_missing mdvis mdvis_missing log_mdexp log_mdexp_missing any_d_routine any_d_routine_missing any_d_special any_d_special_missing"
	foreach var of local util {
		
		eststo: quietly regress `var' rand_plan_group1 rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group6 rand_plan_group5 demeaned_first_month*, nocons cluster(fam_identifier)
		quietly test rand_plan_group1 == rand_plan_group2 == rand_plan_group3 == rand_plan_group4 == rand_plan_group5 == rand_plan_group6
		quietly estadd scalar p_val_F = r(p)
		quietly test rand_plan_group1 == rand_plan_group5
		quietly estadd scalar p_val_95 = r(p)
		quietly test rand_plan_group1 == rand_plan_group2
		quietly estadd scalar p_val_25 = r(p)
		quietly test rand_plan_group2 == rand_plan_group5
		quietly estadd scalar p_val_mid = r(p)
	
	}
	
	* Panel B (Non-utilization variables)	
	local non_util "female age_6to17 age_18to44 age_45plus white white_missing hs_grad more_than_hs educ_missing city_backgrnd suburb_backgrnd town_backgrnd backgrnd_missing log_fam_income log_fam_income_sq fam_income_missing any_working_fam any_working_fam_missing insured insured_missing workins workins_missing privins privins_missing publins publins_missing exc_health good_health health_status_missing has_pain has_pain_missing has_worry has_worry_missing"

	foreach var of local non_util {
		
		eststo:  quietly regress `var' rand_plan_group1 rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group6 rand_plan_group5 demeaned_first_month*, nocons cluster(fam_identifier)
		quietly test rand_plan_group1 == rand_plan_group2 == rand_plan_group3 == rand_plan_group4 == rand_plan_group5 == rand_plan_group6
		quietly estadd scalar p_val_F = r(p)
		quietly test rand_plan_group1 == rand_plan_group5
		quietly estadd scalar p_val_95 = r(p)
		quietly test rand_plan_group1 == rand_plan_group2
		quietly estadd scalar p_val_25 = r(p)
		quietly test rand_plan_group2 == rand_plan_group5
		quietly estadd scalar p_val_mid = r(p)
	
	}
	
	esttab using ${home}/`tables'/ApTable4.csv, keep(rand_plan_group1 rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group6 rand_plan_group5) se nostar stats(N p_val_F p_val_95 p_val_25 p_val_mid) replace
	eststo clear
	
	capture log close
	log using ${home}/`tables'/ApTable4JointFTestsAndNs.log, replace
	
	* N's for Table 2
	tab rand_plan_group
	
	* Joint F tests
	drop demeaned_first_month_site2 demeaned_first_month_site3 demeaned_first_month_site4 demeaned_first_month_site5 demeaned_first_month_site6 demeaned_first_month_site7 demeaned_first_month_site8 demeaned_first_month_site9 demeaned_first_month_site10 demeaned_first_month_site11 demeaned_first_month_site12 demeaned_first_month_site13 demeaned_first_month_site32

	quietly _rmcollright rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 demeaned_first_month*
	local rhs `r(varlist)'
	
	foreach var of local util {
	
		quietly regress `var' `rhs'
		quietly estimates store `var'
		
	}
	
	foreach var of local non_util {
	
		quietly regress `var' `rhs'
		quietly estimates store `var'
		
	}
	
	quietly suest `util', cluster(fam_identifier)
	testparm rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6
	
	quietly suest `non_util', cluster(fam_identifier)
	testparm rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6
	
	quietly suest `util' `non_util', cluster(fam_identifier)
	testparm rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6

	capture log close
	log using ${home}/RedoingRandMaster.log, append
	
clear

}

********************************************************************************************************************
/* Table 2 */
*********************************************************************************************************************
if step3 == 1 {

use ${home}/AnalysisData/person_years.dta

	* Demean dummies
	quietly generate fam_start_month_string = string(fam_start_month)
	quietly generate site_string = string(site)
	quietly egen fam_start_month_site_string = concat(fam_start_month_string site_string)
	quietly encode(fam_start_month_site_string), generate(fam_start_month_site)
	quietly	drop fam_start_month_site_string fam_start_month_string site_string
	quietly tabulate fam_start_month_site, generate(fam_start_month_site)
	quietly tabulate fam_start_year, generate(cal_year)
	foreach var of varlist fam_start_month_site* cal_year* {
		quietly egen mean_`var' = mean(`var')
		quietly generate demeaned_`var' = `var' - mean_`var'
		quietly drop mean_`var'
	}
	quietly drop demeaned_fam_start_month_site
	
	local vars "spending inp out"
	foreach var of local vars {
		
		eststo:  quietly regress any_`var' rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year*, cluster(ifamily)
		quietly test rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6
		quietly estadd scalar p_val_F = r(p)
		quietly test rand_plan_group5
		quietly estadd scalar p_val_95 = r(p)
		quietly test rand_plan_group2
		quietly estadd scalar p_val_25 = r(p)
		quietly test rand_plan_group2 == rand_plan_group5 
		quietly estadd scalar p_val_mid = r(p)
		
		eststo:  quietly regress `var'_infl rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year*, cluster(ifamily)
		quietly test rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6
		quietly estadd scalar p_val_F = r(p)
		quietly test rand_plan_group5
		quietly estadd scalar p_val_95 = r(p)
		quietly test rand_plan_group2
		quietly estadd scalar p_val_25 = r(p)
		quietly test rand_plan_group2 == rand_plan_group5 
		quietly estadd scalar p_val_mid = r(p)
	
	if "`var'" != "inp" {
		* Note: These baseline regressions are not presented in Table 2; however, they are included in Tables 3 and A5. 
		eststo:  quietly regress log_`var' rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year*, cluster(ifamily)
		quietly test rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6
		quietly estadd scalar p_val_F = r(p)
		quietly test rand_plan_group5
		quietly estadd scalar p_val_95 = r(p)
		quietly test rand_plan_group2
		quietly estadd scalar p_val_25 = r(p)
		quietly test rand_plan_group2 == rand_plan_group5 
		quietly estadd scalar p_val_mid = r(p)
		
	}
	}
	
	esttab using ${home}/`tables'/Table2.csv, drop(demeaned_fam_start_month_site* demeaned_cal_year* o.demeaned*) se replace nostar stats(N p_val_F p_val_95 p_val_25 p_val_mid)
	eststo clear	
	
clear

}

*********************************************************************************************************************
/* Table 4 */
********************************************************************************************************************
if step4 == 1 {

/* Arc Elasticities Based on the Coinsurance Rate */
program ArcElasticity 

	version 10.1
	syntax [varlist] [if] [in] [,*]
	
	tokenize `varlist'
	local lhsvar `1'
	macro shift 1
	local rhsvars "`*'"
	
	if replay() {
		_coef_table, `options'
		exit
	}
	
	_rmcollright `rhsvars', noconstant
	local rhs `r(varlist)'
	regress `lhsvar' `rhs' `if' `in', `options'
	tempname bb_regress
	matrix `bb_regress' = e(b)
	tempname bb 
	matrix `bb' = J(1,18,0)
	matrix `bb'[1,1] = (`bb_regress'[1,2] - `bb_regress'[1,1])/(`bb_regress'[1,2] + `bb_regress'[1,1])
	matrix `bb'[1,2] = (`bb_regress'[1,3] - `bb_regress'[1,1])/(`bb_regress'[1,3] + `bb_regress'[1,1])
	matrix `bb'[1,3] = (`bb_regress'[1,4] - `bb_regress'[1,1])/(`bb_regress'[1,4] + `bb_regress'[1,1])
	matrix `bb'[1,4] = (`bb_regress'[1,5] - `bb_regress'[1,1])/(`bb_regress'[1,5] + `bb_regress'[1,1])
	matrix `bb'[1,5] = (`bb_regress'[1,6] - `bb_regress'[1,1])/(`bb_regress'[1,6] + `bb_regress'[1,1])
	matrix `bb'[1,6] = ((`bb_regress'[1,3] - `bb_regress'[1,2])/(`bb_regress'[1,3] + `bb_regress'[1,2]))/((31.897 - 25)/(31.897 + 25))
	matrix `bb'[1,7] = ((`bb_regress'[1,4] - `bb_regress'[1,2])/(`bb_regress'[1,4] + `bb_regress'[1,2]))/((50-25)/(50 + 25))
	matrix `bb'[1,8] = ((`bb_regress'[1,5] - `bb_regress'[1,2])/(`bb_regress'[1,5] + `bb_regress'[1,2]))/((95-25)/(95 + 25))
	matrix `bb'[1,9] = ((`bb_regress'[1,6] - `bb_regress'[1,2])/(`bb_regress'[1,6] + `bb_regress'[1,2]))/((57.67825-25)/(57.67825 + 25))
	matrix `bb'[1,10] = ((`bb_regress'[1,4] - `bb_regress'[1,3])/(`bb_regress'[1,4] + `bb_regress'[1,3]))/((50-31.897)/(50 + 31.897))
	matrix `bb'[1,11] = ((`bb_regress'[1,5] - `bb_regress'[1,3])/(`bb_regress'[1,5] + `bb_regress'[1,3]))/((95-31.897)/(95 + 31.897))
	matrix `bb'[1,12] = ((`bb_regress'[1,6] - `bb_regress'[1,3])/(`bb_regress'[1,4] + `bb_regress'[1,3]))/((57.67825-31.897)/(57.67825 + 31.897))
	matrix `bb'[1,13] = ((`bb_regress'[1,5] - `bb_regress'[1,4])/(`bb_regress'[1,5] + `bb_regress'[1,4]))/((95-50)/(95 + 50))
	matrix `bb'[1,14] = ((`bb_regress'[1,6] - `bb_regress'[1,4])/(`bb_regress'[1,6] + `bb_regress'[1,4]))/((57.67825-50)/(57.6825 + 50))
	matrix `bb'[1,15] = ((`bb_regress'[1,6] - `bb_regress'[1,5])/(`bb_regress'[1,6] + `bb_regress'[1,5]))/((57.67825-95)/(57.6825 + 95))
	matrix `bb'[1,16] = (9201*`bb'[1,1] + 8542*`bb'[1,2] + 8241*`bb'[1,3] + 10564*`bb'[1,4] + 11015*`bb'[1,5] + 4063*`bb'[1,6] + 3762*`bb'[1,7] + 6085*`bb'[1,8] + 6536*`bb'[1,9] + 3103*`bb'[1,10] + 5426*`bb'[1,11] + 5877*`bb'[1,12] + 5125*`bb'[1,13] + 5576*`bb'[1,14] + 7899*`bb'[1,15])/101015
	matrix `bb'[1,17] = (4063*`bb'[1,6] + 3762*`bb'[1,7] + 6085*`bb'[1,8] + 6536*`bb'[1,9] + 3103*`bb'[1,10] + 5426*`bb'[1,11] + 5877*`bb'[1,12] + 5125*`bb'[1,13] + 5576*`bb'[1,14] + 7899*`bb'[1,15])/53452
	matrix `bb'[1,18] = (4063*`bb'[1,6] + 3762*`bb'[1,7] + 6085*`bb'[1,8] + 3103*`bb'[1,10] + 5426*`bb'[1,11] + 5125*`bb'[1,13])/27564
	matrix colnames `bb' = 25vFC MixedvFC 50vFC 95vFC IDvFC 25vMixed 25v50 25v95 25vID Mixedv50 Mixedv95 MixedvID 50v95 50vID 95vID AllPlansAvr NotFC NotFCID
	tempvar mySamp
	gen `mySamp' = e(sample)
	ereturn post `bb', esample(`mySamp')
	
end

/* Arc Elasticities Based on (Person-Weighted) Average Out-of-Pocket Share */ 
program ArcElasticity2

	version 10.1
	syntax [varlist] [if] [in] [,*]
	
	tokenize `varlist'
	local lhsvar `1'
	macro shift 1
	local rhsvars "`*'"
	
	if replay() {
		_coef_table, `options'
		exit
	}
	
	_rmcollright `rhsvars', noconstant
	local rhs `r(varlist)'
	regress `lhsvar' `rhs' `if' `in', `options'
	tempname bb_regress
	matrix `bb_regress' = e(b)
	tempname bb 
	matrix `bb' = J(1,18,0)
	matrix `bb'[1,1] = (`bb_regress'[1,2] - `bb_regress'[1,1])/(`bb_regress'[1,2] + `bb_regress'[1,1])
	matrix `bb'[1,2] = (`bb_regress'[1,3] - `bb_regress'[1,1])/(`bb_regress'[1,3] + `bb_regress'[1,1])
	matrix `bb'[1,3] = (`bb_regress'[1,4] - `bb_regress'[1,1])/(`bb_regress'[1,4] + `bb_regress'[1,1])
	matrix `bb'[1,4] = (`bb_regress'[1,5] - `bb_regress'[1,1])/(`bb_regress'[1,5] + `bb_regress'[1,1])
	matrix `bb'[1,5] = (`bb_regress'[1,6] - `bb_regress'[1,1])/(`bb_regress'[1,6] + `bb_regress'[1,1])
	
	matrix `bb'[1,6] = ((`bb_regress'[1,3] - `bb_regress'[1,2])/(`bb_regress'[1,3] + `bb_regress'[1,2]))/((28.24802 - 22.91352)/(28.24802 + 22.91352))
	matrix `bb'[1,7] = ((`bb_regress'[1,4] - `bb_regress'[1,2])/(`bb_regress'[1,4] + `bb_regress'[1,2]))/((43.98293-22.91352)/(43.98293 + 22.91352))
	matrix `bb'[1,8] = ((`bb_regress'[1,5] - `bb_regress'[1,2])/(`bb_regress'[1,5] + `bb_regress'[1,2]))/((75.50636-22.91352)/(75.50636 + 22.91352))
	matrix `bb'[1,9] = ((`bb_regress'[1,6] - `bb_regress'[1,2])/(`bb_regress'[1,6] + `bb_regress'[1,2]))/((59.02172-22.91352)/(59.02172 + 22.91352))
	
	matrix `bb'[1,10] = ((`bb_regress'[1,4] - `bb_regress'[1,3])/(`bb_regress'[1,4] + `bb_regress'[1,3]))/((43.98293-28.24802)/(43.98293 + 28.24802))
	matrix `bb'[1,11] = ((`bb_regress'[1,5] - `bb_regress'[1,3])/(`bb_regress'[1,5] + `bb_regress'[1,3]))/((75.50636-28.24802)/(75.50636 + 28.24802))
	matrix `bb'[1,12] = ((`bb_regress'[1,6] - `bb_regress'[1,3])/(`bb_regress'[1,4] + `bb_regress'[1,3]))/((59.02172-28.24802)/(59.02172 + 28.24802))
	
	matrix `bb'[1,13] = ((`bb_regress'[1,5] - `bb_regress'[1,4])/(`bb_regress'[1,5] + `bb_regress'[1,4]))/((75.50636-43.98293)/(75.50636 + 43.98293))
	matrix `bb'[1,14] = ((`bb_regress'[1,6] - `bb_regress'[1,4])/(`bb_regress'[1,6] + `bb_regress'[1,4]))/((59.02172-43.98293)/(59.02172 + 43.98293))
	
	matrix `bb'[1,15] = ((`bb_regress'[1,6] - `bb_regress'[1,5])/(`bb_regress'[1,6] + `bb_regress'[1,5]))/((59.02172-75.50636)/(59.02172 + 75.50636))
	
	matrix `bb'[1,16] = (9201*`bb'[1,1] + 8542*`bb'[1,2] + 8241*`bb'[1,3] + 10564*`bb'[1,4] + 11015*`bb'[1,5] + 4063*`bb'[1,6] + 3762*`bb'[1,7] + 6085*`bb'[1,8] + 6536*`bb'[1,9] + 3103*`bb'[1,10] + 5426*`bb'[1,11] + 5877*`bb'[1,12] + 5125*`bb'[1,13] + 5576*`bb'[1,14] + 7899*`bb'[1,15])/101015
	matrix `bb'[1,17] = (4063*`bb'[1,6] + 3762*`bb'[1,7] + 6085*`bb'[1,8] + 6536*`bb'[1,9] + 3103*`bb'[1,10] + 5426*`bb'[1,11] + 5877*`bb'[1,12] + 5125*`bb'[1,13] + 5576*`bb'[1,14] + 7899*`bb'[1,15])/53452
	matrix `bb'[1,18] = (4063*`bb'[1,6] + 3762*`bb'[1,7] + 6085*`bb'[1,8] + 3103*`bb'[1,10] + 5426*`bb'[1,11] + 5125*`bb'[1,13])/27564
	matrix colnames `bb' = 25vFC MixedvFC 50vFC 95vFC IDvFC 25vMixed 25v50 25v95 25vID Mixedv50 Mixedv95 MixedvID 50v95 50vID 95vID AllPlansAvr NotFC NotFCID
	tempvar mySamp
	gen `mySamp' = e(sample)
	ereturn post `bb', esample(`mySamp')
	
end

use ${home}/AnalysisData/person_years.dta

	* Demean dummies
	quietly generate fam_start_month_string = string(fam_start_month)
	quietly generate site_string = string(site)
	quietly egen fam_start_month_site_string = concat(fam_start_month_string site_string)
	quietly encode(fam_start_month_site_string), generate(fam_start_month_site)
	quietly	drop fam_start_month_site_string fam_start_month_string site_string
	quietly tabulate fam_start_month_site, generate(fam_start_month_site)
	quietly tabulate fam_start_year, generate(cal_year)
	foreach var of varlist fam_start_month_site* cal_year* {
		quietly egen mean_`var' = mean(`var')
		quietly generate demeaned_`var' = `var' - mean_`var'
		quietly drop mean_`var'
		quietly summarize demeaned_`var'
	}
	quietly drop demeaned_fam_start_month_site

capture log close
log using ${home}/`tables'/Table4part1.log, replace // Look here for Panel A and the first and third columns of Panel B

* COMMENT TO USER: note that below we have set only 5 replications of the bootstrap to save time; the paper is based on 500 replciations.

/*THIS TABLE SHOWS THE PAIR WISE ARC ELASTICITIES IN TABLE 4 PANEL A. THE LAST THREE ROWS SHOW THE ARC ELASTICITIES IN 
TABLE 4 PANEL B, COLUMN 1*/
* Elasticities based on the coinsurance rate
quietly ArcElasticity spending rand_plan_group1 rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year*, nocons
bs, cluster(ifamily) reps(5):  ArcElasticity spending rand_plan_group1 rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year*, nocons

/*THE LAST THREE ROWS OF THIS TABLE SHOW THE ARC ELASTICITIES IN TABLE 4 PANEL B, COLUMN 3*/
* Elasticities based on (person-weighted) average end-of-year price
quietly ArcElasticity2 spending rand_plan_group1 rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year*, nocons
bs, cluster(ifamily) reps(5):  ArcElasticity2 spending rand_plan_group1 rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year*, nocons

capture log close
log using ${home}/RedoingRandMaster.log, append

**** Usual Elasticities ****

drop if rand_plan_group == 1 

	* Generate price variables
	generate log_sticker_price = log(sticker_price)
	egen avg_oop_share = mean(share_oop), by(rand_plan_group)
	generate log_avg_oop_share = log(avg_oop_share)
	egen total_spending_plan = sum(spending), by(rand_plan_group)
	egen total_oop_plan = sum(out_of_pocket), by(rand_plan_group)
	generate dollar_avg_oop_share = total_oop_plan/total_spending_plan
	generate log_dollar_oop_share = log(dollar_avg_oop_share)
	generate log_expected_price = log(expected_price)
	
	* Regressions for Table 5 Panel B
	local prices "log_sticker_price log_avg_oop_share"
	foreach price of local prices {
	
		eststo:  quietly regress log_spending `price' demeaned_fam_start_month_site* demeaned_cal_year*, cluster(ifamily)
		eststo:  quietly regress log_spending `price' demeaned_fam_start_month_site* demeaned_cal_year* if rand_plan_group != 6, cluster(ifamily)
		
	}
		esttab using ${home}/`tables'/Table4part2.csv, drop(demeaned_fam_start_month_site* demeaned_cal_year* o.demeaned*) replace se nostar nocons noobs // Look here for the second and fourth columns of Panel B
		eststo clear

clear

}



*****************************************************************************************************************
/* Appendix Table 1 */
******************************************************************************************************************
if step5 == 1 {

use ${home}/AnalysisData/person_years.dta

	* Combine mixed coins with 25% to match Rand
	replace rand_plan_group2 = 1 if rand_plan_group3 == 1
	replace rand_plan_group = 2 if rand_plan_group == 3
	
	capture log close
	log using ${home}/`tables'/ApTable1Ns.log, replace
	
	* Ns for table
	tabulate rand_plan_group
	
	capture log close
	log using ${home}/RedoingRandMaster.log, append
	
	* Demean site*first_month dummies
	quietly drop first_month_site
	quietly generate first_month_string = string(first_month)
	quietly generate site_string = string(site)
	quietly egen first_month_site_string = concat(first_month_string site_string)
	quietly encode(first_month_site_string), generate(first_month_site)
	quietly	drop first_month_site_string site_string first_month_string

	quietly tabulate first_month_site, generate(first_month_site)
	foreach var of varlist first_month_site* {
		quietly egen mean_`var' = mean(`var')
		quietly generate demeaned_`var' = `var' - mean_`var'
		drop mean_`var'
	}
	drop demeaned_first_month_site
	
	* Regressions
	local vars "any_mdcl out_rand_infl any_inp mdcl_infl inp_infl"
	foreach var of local vars {
	
		eststo:  regress `var' rand_plan_group1 rand_plan_group2 rand_plan_group4 rand_plan_group5 rand_plan_group6, nocons cluster(ifamily)
		quietly test rand_plan_group1 == rand_plan_group2 == rand_plan_group4 == rand_plan_group5 == rand_plan_group6
		quietly estadd scalar p_val_F = r(p)
		quietly test rand_plan_group1 == rand_plan_group5
		quietly estadd scalar p_val_95 = r(p)
	
	}
	
esttab using ${home}/`tables'/ApTable1.csv, se replace nostar stats(N p_val_F p_val_95)
eststo clear

clear

}


*********************************************************************************************************************
/* Appendix Table 3 */
*********************************************************************************************************************
if step6 == 1 {

use ${home}/AnalysisData/rand_initial_sample.dta

local finite_sample "log_fam_size share_female age_0to5_fam age_6to17_fam age_18to44_fam age_fam_missing white_fam white_fam_missing male_hs_grad male_more_than_hs educ_male_missing female_hs_grad female_more_than_hs educ_female_missing log_income_rand fam_income_missing any_working_fam any_working_fam_missing max_hourly_wage_fam max_hourly_wage_fam_missing insured_fam insured_fam_missing exc_health_fam good_health_fam health_status_fam_missing has_pain_fam has_pain_fam_missing has_worry_fam has_worry_fam_missing hosp_fam hosp_fam_missing mdvis_adult_fam mdvis_adult_fam_missing mdvis_kid_fam mdvis_kid_fam_missing"
local insurance "privins_fam privins_fam_missing workins_fam workins_fam_missing publins_fam publins_fam_missing"
local other "city_backgrnd_fam suburb_backgrnd_fam town_backgrnd_fam backgrnd_missing_fam havemd_fam havemd_fam_missing mdexam_fam mdexam_fam_missing log_mdexp_fam log_mdexp_fam_missing any_d_routine_fam any_ddental_fam_missing any_d_special_fam any_sdental_fam_missing"

******
drop if site == 1
******

	capture log close
	log using ${home}/`tables'/ApTable3JointFTestsandNs.log, replace

	* Rename dental vars 
	quietly rename any_d_routine_fam_missing any_ddental_fam_missing
	quietly rename any_d_special_fam_missing any_sdental_fam_missing

		quietly drop contact_month_site
		* Assign the earliest contact month within each family to all family members
		bysort fam_identifier: egen contact_month_fam = min(contact_month)
		drop contact_month
		rename contact_month_fam contact_month
		*Generate unique contact month*site interaction terms
		quietly generate contact_month_string = string(contact_month)
		quietly generate site_string = string(site)
		quietly egen contact_month_site_string = concat(contact_month_string site_string)
		quietly encode(contact_month_site_string), generate(contact_month_site)
		quietly	drop contact_month_site_string site_string contact_month_string
		
		*Fix the 2 families with members recorded as being in two plans to reassign outlier member to family plan		
		replace rand_plan_group=5 if fam_identifier=="KG102600"
		replace rand_plan_group5=1 if fam_identifier=="KG102600"
		replace rand_plan_group3=0 if fam_identifier=="KG102600"
		replace rand_plan_group=6 if fam_identifier=="KG105854"
		replace rand_plan_group6=1 if fam_identifier=="KG105854"
		replace rand_plan_group1=0 if fam_identifier=="KG105854"


	* Collapse to run regressions at family level
	sort fam_identifier contact_month
	quietly collapse (mean) `finite_sample' `insurance' `other' (first) rand_plan_group* contact_month_site site contact_month, by(fam_identifier)

	tab contact_month_site
	bysort contact_month_site: gen size_contact_month_site = _N
	* Note: We drop people who are in a contact month*site combination with fewer than 9 observations due to multicollinearity problems
	drop if size_contact_month_site<9

	* Get N's
	tab rand_plan_group
	
	* Demean dummies 
	quietly tab contact_month_site, generate(contact_month_site)
	foreach var of varlist contact_month_site* {
		quietly egen mean_`var' = mean(`var')
		quietly generate demeaned_`var' = `var' - mean_`var'
		drop mean_`var'
	}
	drop demeaned_contact_month_site

	quietly _rmcollright rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 demeaned_contact_month_site*
	local rhs `r(varlist)'
	
	* Panel A
	foreach var of local finite_sample {
	
		eststo: quietly regress `var' rand_plan_group1 rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group6 rand_plan_group5 demeaned_contact_month_site*, nocons robust
		quietly test rand_plan_group1 == rand_plan_group2 == rand_plan_group3 == rand_plan_group4 == rand_plan_group5 == rand_plan_group6
		quietly estadd scalar p_val_F = r(p)
		quietly test rand_plan_group1 == rand_plan_group5
		quietly estadd scalar p_val_95 = r(p)
		quietly test rand_plan_group1 == rand_plan_group2 
		quietly estadd scalar p_val_25 = r(p)
		quietly test rand_plan_group2 == rand_plan_group5 
		quietly estadd scalar p_val_mid = r(p)
		
		quietly regress `var' `rhs'
		quietly estimates store `var'
		
	}
	
	quietly esttab using ${home}/`tables'/ApTable3PanelA.csv, drop(demeaned_contact_month* o.demeaned*) replace se nostar stats(N p_val_F p_val_95 p_val_25 p_val_mid)
	eststo clear
	
	* Joint F test panel A
	quietly suest `finite_sample', vce(robust)
	testparm rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6

	* Panel B
	foreach var of local insurance {
	
		eststo:  quietly regress `var' rand_plan_group1 rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group6 rand_plan_group5 demeaned_contact_month*, nocons robust
		quietly test rand_plan_group1 == rand_plan_group2 == rand_plan_group3 == rand_plan_group4 == rand_plan_group5 == rand_plan_group6
		quietly estadd scalar p_val_F = r(p)
		quietly test rand_plan_group1 == rand_plan_group5
		quietly estadd scalar p_val_95 = r(p)
		quietly test rand_plan_group1 == rand_plan_group2 
		quietly estadd scalar p_val_25 = r(p)
		quietly test rand_plan_group2 == rand_plan_group5 
		quietly estadd scalar p_val_mid = r(p)
		
		quietly regress `var' `rhs'
		estimates store `var'
		
	}

	foreach var of local other {
	
		eststo:  quietly regress `var' rand_plan_group1 rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group6 rand_plan_group5 demeaned_contact_month*, nocons robust
		quietly test rand_plan_group1 == rand_plan_group2 == rand_plan_group3 == rand_plan_group4 == rand_plan_group5 == rand_plan_group6
		quietly estadd scalar p_val_F = r(p)
		quietly test rand_plan_group1 == rand_plan_group5
		quietly estadd scalar p_val_95 = r(p)
		quietly test rand_plan_group1 == rand_plan_group2 
		quietly estadd scalar p_val_25 = r(p)
		quietly test rand_plan_group2 == rand_plan_group5 
		quietly estadd scalar p_val_mid = r(p)
		
		quietly regress `var' `rhs'
		estimates store `var'
		
	}
	
	quietly esttab using ${home}/`tables'/ApTable3PanelB.csv, drop(demeaned_contact_month* o.demeaned*) replace se nostar stats(N p_val_F p_val_95 p_val_25 p_val_mid)
	eststo clear
	
	* Joint F test panels B (with and without the 50% coinsurance rate plan)
	quietly suest `insurance' `other', vce(robust)
	testparm rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6
	testparm rand_plan_group2 rand_plan_group3 rand_plan_group5 rand_plan_group6

	capture log close
	log using ${home}/RedoingRandMaster.log, append

clear

}

********************************************************************************************************************
/* Appendix Table 2 */
******************************************************************************************************************** 
if step7 == 1 {

**** Programs for Quantile Regressions ****


program myqreg

	version 10.1
	syntax [varlist] [if] [in] [,*]
	
	tokenize `varlist'
	local lhsvar `1'
	macro shift 1
	local rhsvars "`*'"
	
	if replay() {
		_coef_table, `options'
		exit
	}
	
	_rmcollright `rhsvars'
	local rhs `r(varlist)'
	qreg `lhsvar' `rhs' `if' `in', `options'
	tempname bb_qreg
	matrix `bb_qreg' = e(b)
	tempname bb 
	matrix `bb' = J(1,6,0)
	matrix `bb'[1,1] = `bb_qreg'[1,1]
	matrix `bb'[1,2] = `bb_qreg'[1,2]
	matrix `bb'[1,3] = `bb_qreg'[1,3]
	matrix `bb'[1,4] = `bb_qreg'[1,4]
	matrix `bb'[1,5] = `bb_qreg'[1,5]
	matrix `bb'[1,6] = `bb_qreg'[1,"_cons"]
	matrix colnames `bb' = rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 _cons
	tempvar mySamp
	gen `mySamp' = e(sample)
	ereturn post `bb', esample(`mySamp')
	
end

********

use ${home}/AnalysisData/person_years.dta

	capture log close
	log using ${home}/`tables'/ApTable2.log, replace

	* Demean dummies
	quietly generate fam_start_month_string = string(fam_start_month)
	quietly generate site_string = string(site)
	quietly egen fam_start_month_site_string = concat(fam_start_month_string site_string)
	quietly encode(fam_start_month_site_string), generate(fam_start_month_site)
	quietly	drop fam_start_month_site_string fam_start_month_string site_string
	quietly tabulate fam_start_month_site, generate(fam_start_month_site)
	quietly tabulate fam_start_year, generate(cal_year)

	foreach var of varlist fam_start_month_site* cal_year* {
		quietly egen mean_`var' = mean(`var')
		quietly generate demeaned_`var' = `var' - mean_`var'
		quietly drop mean_`var'
		quietly summarize demeaned_`var'
	}
	quietly drop demeaned_fam_start_month_site

	local qs "10 20 30 40 50 60 70 80 90"
	foreach q of local qs {
	
	display "quantile `q'"

	quietly myqreg spending_infl rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year*, quantile(`q')
	bs, cluster(ifamily) reps(2): myqreg spending_infl rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year*, quantile(`q')

}

	capture log close
	log using ${home}/RedoingRandMaster.log, append

clear
		
}


******************************************************************************************************************
/* Table 3 */
********************************************************************************************************************
if step8 == 1 {

use ${home}/AnalysisData/person_years.dta

	* Demean dummies
	quietly generate fam_start_month_string = string(fam_start_month)
	quietly generate site_string = string(site)
	quietly egen fam_start_month_site_string = concat(fam_start_month_string site_string)
	quietly encode(fam_start_month_site_string), generate(fam_start_month_site)
	quietly	drop fam_start_month_site_string fam_start_month_string site_string
	quietly tabulate fam_start_month_site, generate(fam_start_month_site)
	quietly tabulate fam_start_year, generate(cal_year)
	foreach var of varlist fam_start_month_site* cal_year* {
		quietly egen mean_`var' = mean(`var')
		quietly generate demeaned_`var' = `var' - mean_`var'
		quietly drop mean_`var'
	}
	quietly drop demeaned_fam_start_month_site
	
	*Sample sizes
	count if rand_plan_group==1
	local freecare_N=r(N)
	count if rand_plan_group==2
	local twentyfivecoinsure_N=r(N)
	count if rand_plan_group==5
	local ninetyfivecoinsure_N=r(N)
	
	local PanelA_N= `freecare_N' + `ninetyfivecoinsure_N'
	local PanelB_N= `freecare_N' + `twentyfivecoinsure_N'
	local PanelC_N= `ninetyfivecoinsure_N' + `twentyfivecoinsure_N'
	
	capture quietly log close
	quietly log using ${home}/`tables'/Table3N.log, text replace
	
	di "PanelA_N" " " `PanelA_N'
	di "PanelB_N" " " `PanelB_N'
	di "PanelC_N" " " `PanelC_N'
	
	local vars "spending inp out"
	foreach var of local vars {
	
		eststo:  quietly regress any_`var' rand_plan_group1 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year*, cluster(ifamily)
		
		eststo:  quietly regress `var'_infl rand_plan_group1 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year*, cluster(ifamily)
		
		if "`var'" != "inp" {
		
		eststo:  quietly regress log_`var' rand_plan_group1 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year*, cluster(ifamily)
	
		}
		
	}
	
	esttab using ${home}/`tables'/Table3PanelCrow1.csv, keep(rand_plan_group5) replace se nostar noobs
	eststo clear

	* Adjustment for underfiling of claims
		local vars "out out_rand out_infl"
		foreach var of local vars {
			replace `var' = `var'*1.04 if rand_plan_group == 1 
			replace `var' = `var'*1.06 if rand_plan_group == 2 | rand_plan_group == 3 | rand_plan_group == 4
			replace `var' = `var'*1.14 if rand_plan_group == 5
			replace `var' = `var'*1.11 if rand_plan_group == 6
		}
		replace mdcl = mdcl + out_rand*.04 if rand_plan_group == 1
		replace mdcl = mdcl + out_rand*.06 if rand_plan_group == 2 | rand_plan_group == 3 | rand_plan_group == 4
		replace mdcl = mdcl + out_rand*.14 if rand_plan_group == 5
		replace mdcl = mdcl + out_rand*.11 if rand_plan_group == 6
		replace spending = spending + out*.04 if rand_plan_group == 1 
		replace spending = spending + out*.06 if rand_plan_group == 2 | rand_plan_group == 3 | rand_plan_group == 4
		replace spending = spending + out*.14 if rand_plan_group == 5 
		replace spending = spending + out*.11 if rand_plan_group == 6
		
		replace mdcl_infl = mdcl_infl + out_rand_infl*.04 if rand_plan_group == 1
		replace mdcl_infl = mdcl_infl + out_rand_infl*.06 if rand_plan_group == 2 | rand_plan_group == 3 | rand_plan_group == 4
		replace mdcl_infl = mdcl_infl + out_rand_infl*.14 if rand_plan_group == 5
		replace mdcl_infl = mdcl_infl + out_rand_infl*.11 if rand_plan_group == 6
		replace spending_infl = spending_infl + out_infl*.04 if rand_plan_group == 1 
		replace spending_infl = spending_infl + out_infl*.06 if rand_plan_group == 2 | rand_plan_group == 3 | rand_plan_group == 4

		replace spending_infl = spending_infl + out_infl*.14 if rand_plan_group == 5 
		replace spending_infl = spending_infl + out_infl*.11 if rand_plan_group == 6
		
		local vars "out inp spending mdcl"
		foreach var of local vars {
			replace log_`var' = log(`var' + 1)
		}
		local vars "out spending mdcl"
		foreach var of local vars {
			replace any_`var' = any_`var'*1.04 if rand_plan_group == 1
			replace any_`var' = any_`var'*1.06 if rand_plan_group == 2 | rand_plan_group == 3 | rand_plan_group == 4
			replace any_`var' = any_`var'*1.14 if rand_plan_group == 5 
			replace any_`var' = any_`var'*1.11 if rand_plan_group == 6
		}

	capture quietly log close
	quietly log using ${home}/RedoingRandMaster.log, append
	
	**** 95% and 25% versus Free Care ****
	local vars "spending inp out"
	foreach var of local vars {
	
		eststo:  quietly regress any_`var' rand_plan_group5 rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year*, cluster(ifamily)
		
		eststo:  quietly regress `var'_infl rand_plan_group5 rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year*, cluster(ifamily)
		
		if "`var'" != "inp" { 
		
		eststo:  quietly regress log_`var' rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year*, cluster(ifamily)
	
		}
		
	}
	
	esttab using ${home}/`tables'/Table3PanelsAandBrow2.csv, keep(rand_plan_group5 rand_plan_group2) replace se nostar noobs
	eststo clear
	**** 95% versus 25% ****
	local vars "spending inp out"
	foreach var of local vars {
	
		eststo:  quietly regress any_`var' rand_plan_group1 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year*, cluster(ifamily)
		
		eststo:  quietly regress `var'_infl rand_plan_group1 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year*, cluster(ifamily)
		
		if "`var'" != "inp" {
		
		eststo:  quietly regress log_`var' rand_plan_group1 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year*, cluster(ifamily)
	
		}
		
	}
	
	esttab using ${home}/`tables'/Table3PanelCrow2.csv, keep(rand_plan_group5) replace se nostar noobs
	eststo clear
	
	**** Add Covariates ****
	
	* Demean covariates
	local covs "hosp hosp_missing havemd havemd_missing mdexam mdexam_missing mdvis mdvis_missing log_mdexp log_mdexp_missing any_d_routine any_d_routine_missing any_d_special any_d_special_missing female age_6to17 age_18to44 age_45plus white white_missing hs_grad more_than_hs educ_missing city_backgrnd suburb_backgrnd town_backgrnd backgrnd_missing log_fam_income log_fam_income_sq fam_income_missing any_working_fam any_working_fam_missing insured insured_missing workins workins_missing privins privins_missing publins publins_missing exc_health good_health health_status_missing has_pain has_pain_missing has_worry has_worry_missing"
	foreach cov of local covs {
		replace `cov' = -1 if `cov' == .
		egen mean_`cov' = mean(`cov')
		replace `cov' = `cov' - mean_`cov'
		drop mean_`cov'
	}
	
	_rmcollright  rand_plan_group5 rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year* `covs'
	local rhs1 `r(varlist)'
	_rmcollright  rand_plan_group5 rand_plan_group1 rand_plan_group3 rand_plan_group4 rand_plan_group6 demeaned_fam_start_month* demeaned_cal_year* `covs'
	local rhs2 `r(varlist)'
	
	**** 95% versus 25% ****
	
	local vars "spending inp out"
	foreach var of local vars {
	
		eststo:  quietly regress any_`var' `rhs2', cluster(ifamily)
		
		eststo:  quietly regress `var'_infl `rhs2', cluster(ifamily)
		
		if "`var'" != "inp" {
		
		eststo:  quietly regress log_`var' `rhs2', cluster(ifamily)
		
		}
		
	}
	
	esttab using ${home}/`tables'/Table3PanelCrow3.csv, keep(rand_plan_group5) replace se nostar noobs
	eststo clear
	
	**** 95% and 25% versus Free Care ****
	local vars "spending inp out"
	foreach var of local vars {
	
		eststo:  quietly regress any_`var' `rhs1', cluster(ifamily)
		
		eststo:  quietly regress `var'_infl `rhs1', cluster(ifamily)
		
		if "`var'" != "inp" { 
		
		eststo:  quietly regress log_`var' `rhs1', cluster(ifamily)
		
		}
		
	}
	
	esttab using ${home}/`tables'/Table3PanelsAandBrow3.csv, keep(rand_plan_group5 rand_plan_group2) replace se nostar noobs
	eststo clear
	
clear	

}

*
**********************************************************************************************************************
/* Step 9 (Data Step)*/
**********************************************************************************************************************
if step9 == 1 {

use ${home}/AnalysisData/rand_initial_sample.dta

	* Obtain last family identifier available to use for creation of ifamily variables for refusers/attriters
	quietly generate last_id = fam_identifier 
	local years "1 2 3 4 5"
	foreach yr of local years {
	quietly  replace last_id = ifamily`yr' if ifamily`yr' != "" 
	}
	
	* Reshape long and create indicator for having refused/attrited
	reshape long full_year, i(person) j(year)
	drop if enrterm == 3 & (year == 4 | year == 5)
	drop if full_year == 1
	generate ref_at = 1
	
append using ${home}/AnalysisData/person_years.dta

	replace ref_at = 0 if ref_at == .

	* Retrofit first month for refusers:  contact_month + median(lag) by site and enrterm (or median first_month if contact_month == .)
	quietly replace contact_month = . if contact_month == 1000 /* Indicates contact_month was originally missing */
	quietly generate start_lag = first_month - contact_month
	quietly egen median_start_lag = median(start_lag), by(site enrterm)
	quietly replace first_month = contact_month + median_start_lag if first_month == .
	quietly egen median_first_month = median(first_month), by(site enrterm)
	quietly replace first_month = median_first_month if first_month == .
	assert first_month != .
	drop start_lag median_start_lag median_first_month
		
	quietly drop first_month_site
	quietly generate first_month_string = string(first_month)
	quietly generate site_string = string(site)
	quietly egen first_month_site_string = concat(first_month_string site_string)
	quietly encode(first_month_site_string), generate(first_month_site)
	quietly	drop first_month_site_string site_string first_month_string
		
	quietly tab first_month ref_at /* Check for similar distributions */
	quietly replace fam_start_month = month(first_month) if fam_start_month == .
	assert fam_start_month != . 

	* Retrofit start_month for refusers and attriters
	local years "1 2 3 4 5"
	foreach yr of local years {
		scalar yr_minus = `yr' - 1 
		quietly replace start_month = first_month + 12*yr_minus if start_month == . & year == `yr'
	}
	assert start_month != .
	
	quietly drop start_month_site
	quietly generate start_month_string = string(start_month)
	quietly generate site_string = string(site)
	quietly egen start_month_site_string = concat(start_month_string site_string)
	quietly encode(start_month_site_string), generate(start_month_site)
	quietly	drop start_month_site_string start_month_string site_string

	quietly tab start_month ref_at /* Check for similar distributions */
	
	* Retrofit fam_start_year
	quietly generate years_temp = start_month/12
	quietly replace fam_start_year = floor(years_temp) + 1960 if fam_start_year == . 
	drop years_temp
	quietly tab fam_start_year ref_at /* Check for similar distributions */
	assert fam_start_year != .

	* Retrofit ifamily for refusers and attriters
	quietly replace ifamily = last_id if ref_at == 1 & ifamily == ""
	assert ifamily != ""

	* Create numeric family identifier var
	sort ifamily person year
	sort ifamily
	generate fam_id = .
	replace fam_id = 1 if _n == 1
	replace fam_id = fam_id[_n-1] + (ifamily[_n] != ifamily[_n-1]) if _n > 1 

save ${home}/AnalysisData/bounds_sample.dta, replace

clear

}


**********************************************************************************************************************
/* Appendix Table 5 */
**********************************************************************************************************************
if step10 == 1 {

use ${home}/AnalysisData/bounds_sample.dta

	* Adjustment for underfiling of claims
		
		local vars "out out_rand out_infl"
		foreach var of local vars {
			replace `var' = `var'*1.04 if rand_plan_group == 1 
			replace `var' = `var'*1.06 if rand_plan_group == 2 | rand_plan_group == 3 | rand_plan_group == 4
			replace `var' = `var'*1.14 if rand_plan_group == 5
			replace `var' = `var'*1.11 if rand_plan_group == 6
		}
		replace mdcl = mdcl + out_rand*.04 if rand_plan_group == 1
		replace mdcl = mdcl + out_rand*.06 if rand_plan_group == 2 | rand_plan_group == 3 | rand_plan_group == 4
		replace mdcl = mdcl + out_rand*.14 if rand_plan_group == 5
		replace mdcl = mdcl + out_rand*.11 if rand_plan_group == 6
		replace spending = spending + out*.04 if rand_plan_group == 1 
		replace spending = spending + out*.06 if rand_plan_group == 2 | rand_plan_group == 3 | rand_plan_group == 4
		replace spending = spending + out*.14 if rand_plan_group == 5 
		replace spending = spending + out*.11 if rand_plan_group == 6
		
		replace mdcl_infl = mdcl_infl + out_rand_infl*.04 if rand_plan_group == 1
		replace mdcl_infl = mdcl_infl + out_rand_infl*.06 if rand_plan_group == 2 | rand_plan_group == 3 | rand_plan_group == 4
		replace mdcl_infl = mdcl_infl + out_rand_infl*.14 if rand_plan_group == 5
		replace mdcl_infl = mdcl_infl + out_rand_infl*.11 if rand_plan_group == 6
		replace spending_infl = spending_infl + out_infl*.04 if rand_plan_group == 1 
		replace spending_infl = spending_infl + out_infl*.06 if rand_plan_group == 2 | rand_plan_group == 3 | rand_plan_group == 4
		replace spending_infl = spending_infl + out_infl*.14 if rand_plan_group == 5 
		replace spending_infl = spending_infl + out_infl*.11 if rand_plan_group == 6
		
		local vars "out inp spending mdcl"
		foreach var of local vars {
			replace log_`var' = log(`var' + 1)
		}
		local vars "out spending mdcl"
		foreach var of local vars {
			replace any_`var' = any_`var'*1.04 if rand_plan_group == 1
			replace any_`var' = any_`var'*1.06 if rand_plan_group == 2 | rand_plan_group == 3 | rand_plan_group == 4
			replace any_`var' = any_`var'*1.14 if rand_plan_group == 5 
			replace any_`var' = any_`var'*1.11 if rand_plan_group == 6
		}

	* Create extreme value variables for discrete variables
	local vars "any_spending any_mdcl any_inp any_out"
	foreach var of local vars {
		quietly generate `var'_high = 1
		quietly generate `var'_low = 0
	}
	
	* Create extreme value variables for continuous variables
	local vars "log_spending spending_infl log_mdcl mdcl_infl log_inp inp_infl log_out out_infl"
	foreach var of local vars {
		quietly generate `var'_high = `var'
		quietly generate `var'_low = `var'
	}
	
	/* Note:  assign percentiles of log variables directly, since doesn't matter:  
	* the log transformation is rank-preserving, and so the 95th percentile of log spending corresponds to the 95th percentile of spending */
	local years "1974 1975 1976 1977 1978 1979 1980 1981"
	local vars "log_spending spending_infl log_mdcl mdcl_infl log_inp inp_infl log_out out_infl"
	foreach yr of local years {
		foreach var of local vars {
			quietly summarize `var' if fam_start_year == `yr' & ref_at == 0, detail
			quietly replace `var'_high = r(p95) if fam_start_year == `yr' & ref_at == 1
			quietly replace `var'_low = 0 if fam_start_year == `yr' & ref_at == 1
			quietly summarize `var'_high if ref_at == 1
			quietly summarize `var'_low if ref_at == 1
		}
	}
	
	* Demean dummies
	quietly generate fam_start_month_string = string(fam_start_month)
	quietly generate site_string = string(site)
	quietly egen fam_start_month_site_string = concat(fam_start_month_string site_string)
	quietly encode(fam_start_month_site_string), generate(fam_start_month_site)
	quietly	drop fam_start_month_site_string fam_start_month_string site_string
	quietly tabulate fam_start_month_site, generate(fam_start_month_site)
	quietly tabulate fam_start_year, generate(cal_year)
	foreach var of varlist fam_start_month_site* cal_year* {
		quietly egen mean_`var' = mean(`var')
		quietly generate demeaned_`var' = `var' - mean_`var'
		drop mean_`var'
	}
	drop demeaned_fam_start_month_site
	
	
	**** 95% versus Free Care, Small Magnitude ****
	local vars "any_spending spending_infl log_spending any_inp inp_infl any_out out_infl log_out"
	
	foreach var of local vars {
		quietly replace `var' = `var'_low if rand_plan_group == 1 & ref_at == 1
		quietly replace `var' = `var'_high if rand_plan_group == 5 & ref_at == 1
		
		eststo: quietly regress `var' rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year*, cluster(ifamily)
		
	}
	count if rand_plan_group == 1 | rand_plan_group == 5
	esttab using ${home}/`tables'/ApTable5PanelA.csv, keep(rand_plan_group5) replace se nostar
	eststo clear


	**** 25% versus Free Care, Small Magnitude ****
	local vars "any_spending spending_infl log_spending any_inp inp_infl any_out out_infl log_out"
	
	foreach var of local vars {
		quietly replace `var' = `var'_low if rand_plan_group == 1 & ref_at == 1
		quietly replace `var' = `var'_high if rand_plan_group == 2 & ref_at == 1
		
		eststo: quietly regress `var' rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year*, cluster(ifamily)
		
	}
	count if rand_plan_group == 1 | rand_plan_group == 2
	esttab using ${home}/`tables'/ApTable5PanelB.csv, keep(rand_plan_group2) replace se nostar
	eststo clear
	
	**** 95% versus 25%, Small Magnitude ****
	local vars "any_spending spending_infl log_spending any_inp inp_infl any_out out_infl log_out"
	
	foreach var of local vars {
		quietly replace `var' = `var'_low if rand_plan_group == 2 & ref_at == 1
		quietly replace `var' = `var'_high if rand_plan_group == 5 & ref_at == 1
		
		eststo: quietly regress `var' rand_plan_group1 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year*, cluster(ifamily)
			
	}
	count if rand_plan_group == 2 | rand_plan_group == 5
	esttab using ${home}/`tables'/ApTable5PanelC.csv, keep(rand_plan_group5) replace se nostar
	eststo clear

clear

}

**********************************************************************************************************************
/* Table 3, Row 4 */
**********************************************************************************************************************
if step11 == 1 {

use ${home}/AnalysisData/bounds_sample.dta

* Adjustment for underfiling of claims
		local vars "out out_rand"
		foreach var of local vars {
			replace `var' = `var'*1.04 if rand_plan_group == 1 
			replace `var' = `var'*1.06 if rand_plan_group == 2 | rand_plan_group == 3 | rand_plan_group == 4
			replace `var' = `var'*1.14 if rand_plan_group == 5
			replace `var' = `var'*1.11 if rand_plan_group == 6
		}
		replace mdcl = mdcl + out_rand*.04 if rand_plan_group == 1
		replace mdcl = mdcl + out_rand*.06 if rand_plan_group == 2 | rand_plan_group == 3 | rand_plan_group == 4
		replace mdcl = mdcl + out_rand*.14 if rand_plan_group == 5
		replace mdcl = mdcl + out_rand*.11 if rand_plan_group == 6
		replace spending = spending + out*.04 if rand_plan_group == 1 
		replace spending = spending + out*.06 if rand_plan_group == 2 | rand_plan_group == 3 | rand_plan_group == 4
		replace spending = spending + out*.14 if rand_plan_group == 5 
		replace spending = spending + out*.11 if rand_plan_group == 6
		
		replace mdcl_infl = mdcl_infl + out_rand_infl*.04 if rand_plan_group == 1
		replace mdcl_infl = mdcl_infl + out_rand_infl*.06 if rand_plan_group == 2 | rand_plan_group == 3 | rand_plan_group == 4
		replace mdcl_infl = mdcl_infl + out_rand_infl*.14 if rand_plan_group == 5
		replace mdcl_infl = mdcl_infl + out_rand_infl*.11 if rand_plan_group == 6
		replace spending_infl = spending_infl + out_infl*.04 if rand_plan_group == 1 
		replace spending_infl = spending_infl + out_infl*.06 if rand_plan_group == 2 | rand_plan_group == 3 | rand_plan_group == 4
		replace spending_infl = spending_infl + out_infl*.14 if rand_plan_group == 5 
		replace spending_infl = spending_infl + out_infl*.11 if rand_plan_group == 6
		
		
		local vars "out inp spending mdcl"
		foreach var of local vars {
			replace log_`var' = log(`var' + 1)
		}
		local vars "out spending mdcl"
		foreach var of local vars {
			replace any_`var' = any_`var'*1.04 if rand_plan_group == 1
			replace any_`var' = any_`var'*1.06 if rand_plan_group == 2 | rand_plan_group == 3 | rand_plan_group == 4
			replace any_`var' = any_`var'*1.14 if rand_plan_group == 5 
			replace any_`var' = any_`var'*1.11 if rand_plan_group == 6
		}


preserve
drop if site == 1 
drop if born_during_expt == 1

* Obtain retention shares by plan
local plans "1 2 5"
local years "1 2 3 4 5"
foreach plan of local plans {
	foreach yr of local years {
		quietly summarize full_year if rand_plan_group == `plan' & year == `yr', detail
		local mean_`plan'_`yr' `r(mean)'
		display `mean_`plan'_`yr''
		local num_`plan'_`yr' `r(N)'
	}
}


local years "1 2 3 4 5"
foreach yr of local years {
	local free_`yr' = (`mean_1_`yr'' - `mean_5_`yr'')*(1/`mean_1_`yr'')*`num_1_`yr''
	display `free_`yr''
}

foreach yr of local years {
	local low_`yr' = (`mean_1_`yr'' - `mean_2_`yr'')*(1/`mean_1_`yr'')*`num_1_`yr''
	display `low_`yr''
}

foreach yr of local years {
	local mid_`yr' = (`mean_2_`yr'' - `mean_5_`yr'')*(1/`mean_2_`yr'')*`num_2_`yr''
	display `mid_`yr''
}


restore

	* Restrict to people who stayed
	drop if ref_at == 1
	tab year

	* Demean dummies
	quietly generate fam_start_month_string = string(fam_start_month)
	quietly generate site_string = string(site)
	quietly egen fam_start_month_site_string = concat(fam_start_month_string site_string)
	quietly encode(fam_start_month_site_string), generate(fam_start_month_site)
	quietly	drop fam_start_month_site_string fam_start_month_string site_string
	quietly tabulate fam_start_month_site, generate(fam_start_month_site)
	quietly tabulate fam_start_year, generate(cal_year)
	foreach var of varlist fam_start_month_site* cal_year* {
		egen mean_`var' = mean(`var')
		generate demeaned_`var' = `var' - mean_`var'
		drop mean_`var'
	}
	drop demeaned_fam_start_month_site

	generate temp_var = uniform()
	

	**** 95% versus Free Care - Low ****
	
	local vars "any_spending spending_infl log_spending any_inp inp_infl any_out out_infl log_out"
	foreach var of local vars {
	
		preserve
		local years "1 2 3 4 5"
		foreach yr of local years {
			generate not_year = 0
			replace not_year = 1 if year != `yr'
			generate not_plan = 0
			replace not_plan = 1 if rand_plan_group != 1
			gsort +not_plan +not_year -`var' temp_var 
			dis "`free_`yr''"
			drop if _n < `free_`yr''
			drop not_year not_plan	
		}
		
		eststo: quietly regress `var' rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year*, cluster(ifamily)
			
		count if rand_plan_group == 1 | rand_plan_group == 5
		
		restore
 
	}
	
	esttab using ${home}/`tables'/Table3PanelARow4.csv, keep(rand_plan_group5) replace se nostar noobs
	eststo clear

	
	**** 25% versus FC% - Low ****
	
	local vars "any_spending spending_infl log_spending any_inp inp_infl any_out out_infl log_out"
	foreach var of local vars {
	
		preserve

		local years "1 2 3 4 5"
		foreach yr of local years {
			generate not_year = 0
			replace not_year = 1 if year != `yr'
			generate not_plan = 0
			replace not_plan = 1 if rand_plan_group != 1
			gsort +not_plan +not_year -`var' temp_var
			drop if _n < `low_`yr''
			drop not_year not_plan
			
		}
		
		eststo: quietly regress `var' rand_plan_group2 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year*, cluster(ifamily)

		count if rand_plan_group == 1 | rand_plan_group == 2
		restore
	}
	esttab using ${home}/`tables'/Table3PanelBRow4.csv, keep(rand_plan_group2) replace se nostar noobs
	eststo clear

	
	**** 95% versus 25% - Low ****
	
	local vars "any_spending spending_infl log_spending any_inp inp_infl any_out out_infl log_out"
	foreach var of local vars {
	
		preserve

		local years "1 2 3 4 5"
		foreach yr of local years {
			generate not_year = 0
			replace not_year = 1 if year != `yr'
			generate not_plan = 0
			replace not_plan = 1 if rand_plan_group != 2
			gsort +not_plan +not_year -`var' temp_var
			drop if _n < `mid_`yr''
			drop not_year not_plan
			
		}
		
		eststo: quietly regress `var' rand_plan_group1 rand_plan_group3 rand_plan_group4 rand_plan_group5 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year*, cluster(ifamily)
			
		count if rand_plan_group == 2 | rand_plan_group == 5
		restore
	}
	esttab using ${home}/`tables'/Table3PanelCRow4.csv, keep(rand_plan_group5) replace se nostar noobs
	eststo clear
	
clear

}


*
