dm 'odsresults; clear';


libname ile 'C:\Users\bonni\OneDrive\Documents\USF\ILE';

proc import datafile="C:\Users\bonni\OneDrive\Documents\USF\ILE\Healthcare_Associated_Infections-Hospital.xlsx"
	out=hai
	dbms=xlsx
	replace;
run;

data hai_test;
	set hai;
	if facility_id = . then delete;
	if score="Not Available" then delete;
	if footnote ^= ' ' then delete;
run;

proc sort data=hai_test;
    by Facility_ID state;
run;

proc transpose data=hai_test out=hai_test_numbers (drop=_name_);
	by facility_ID state;
	id measure_id;
	var score;
run;

proc transpose data=hai_test suffix=_compared_nat out=hai_test_strings(drop=_name_);
	by  facility_ID state;
	id measure_id;
	var compared_to_national;
run;

data hai_rows (drop=_LABEL_);
  merge hai_test_numbers hai_test_strings;
  by facility_ID state;
run;

proc import datafile="C:\Users\bonni\OneDrive\Documents\USF\ILE\HCAHPS-Hospital.xlsx"
	out=pat
	dbms=xlsx
	replace;
run;

proc sort data=pat;
    by Facility_ID;
run;

data pat_clean;
	set pat;
	if facility_id = . then delete;
	if footnote ^= ' ' then delete;
run;

proc transpose data=pat_clean out=pat_rows;
	by facility_id;
	var HCAHPS_Answer_Percent;
	id HCAHPS_Measure_ID;
run;

proc import datafile="C:\Users\bonni\OneDrive\Documents\USF\ILE\Hospital_General_Information.xlsx"
	out=gen
	dbms=xlsx
	replace;
run;

proc sort data=gen;
    by Facility_ID;
run;

data gen_clean;
	set gen;
	if facility_id = . then delete;
	if footnote ^= ' ' then delete;
run;

data final_set (drop = _label_ _name_);
	merge gen_clean hai_rows pat_rows;
	if missing(HAI_2_SIR_compared_nat) = 1 then delete;
	if missing(hospital_ownership) = 1 then delete;
	if missing(state) = 1 then delete;
	if missing(Hospital_overall_rating) = 1 then delete;
	if missing(HAI_2_SIR) = 1 then delete;
	if missing(H_COMP_3_sn_P) = 1 then delete;
	if missing(H_COMP_3_A_P) = 1 then delete;
	if hospital_overall_rating = 'Not Available' then delete;
	by facility_ID;
	cauti_sir = input(HAI_2_SIR, 10.);
	timelyrare = input(H_COMP_3_sn_P, 10.);
	timelyalways = input(H_COMP_3_A_P, 10.);
	rating = input(Hospital_overall_rating, 10.);
	if missing(cauti_sir) = 1 then delete;
	if missing(timelyrare) = 1 then delete;
	if missing(timelyalways) = 1 then delete;
	if state = 'ME' or state = 'NH' or state = 'VT' or state = 'MA'
		or state = 'CT' or state = 'RI' or state = 'NY' or state = 'PA' or 
		state = 'NJ' then region = 'Northeast';
	if state = 'DE' or state = 'MD' or state = 'DC' or state = 'VA' or
		state = 'WV' or state = 'KY' or state = 'TN' or state = 'NC' or state = 'SC'
		or state = 'GA' or state = 'MS' or state = 'AL' or state = 'FL' or state = 'AR'
		or state = 'LA' or state = 'OK' or state = 'TX' then region = 'South';
	if state = 'OH' or state = 'IN' or state = 'IL' or state = 'WI' or state = 'MI' 
		or state = 'MN' or state = 'IA' or state = 'MO' or state = 'ND'
		or state = 'SD' or state = 'NE' or state = 'KS' then region = 'Midwest';
	if state = 'AK' or state = 'HI' or state = 'MT' or state = 'WA' or state = 'OR'
		or state = 'ID' or state = 'WY' or state = 'CA' or state = 'NV' 
		or state = 'UT' or state = 'CO' or state = 'AZ' or state = 'NM' then region = 'West';
	if state = 'PR' or state = 'VI' then delete;
	catheter_days = input(HAI_2_DOPC, 10.);
	n_cautis = input(HAI_2_NUMERATOR, 10.);
	cauti_rate = n_cautis / catheter_days;
	explainrare = input(H_DOCTOR_EXPLAIN_SN_P, 10.);
run;

proc freq data=final_set;
	tables region hospital_type hospital_ownership hospital_overall_rating;
run;

proc reg data=final_set;
	model cauti_sir = timelyrare;
run;

proc glm data=final_set;
	class region hospital_ownership;
	model cauti_sir = timelyrare region hospital_ownership rating;
run;
quit;

proc glm data=final_set;
	class region;
	model cauti_sir = timelyrare region / solution;
run;
quit;

proc print data=final_set (obs=10);
run;

proc reg data=final_set;
	model cauti_rate = timelyrare;
run;

proc sgplot data=final_set;
	reg x=timelyrare y=cauti_sir;
run;

proc means data=final_set;
	var timelyrare cauti_sir;
run;

proc means data=final_set median qrange;
	var cauti_sir;
run;

proc freq data=final_set;
	tables HAI_2_SIR_compared_nat*region;
run;


proc freq data=final_set;
	tables HAI_2_SIR_compared_nat*hospital_type;
run;

proc freq data=final_set;
	tables HAI_2_SIR_compared_nat*hospital_ownership;
run;

proc freq data=final_set;
	tables HAI_2_SIR_compared_nat*rating;
run;

proc freq data=final_set;
	tables HAI_2_SIR_compared_nat;
run;
