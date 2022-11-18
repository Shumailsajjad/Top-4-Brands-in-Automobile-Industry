*Name: Group 1
*Purpose: Group Project
*Date: 4/10/2022

	/*
	Edit History: 5/9/2022
	*/
	
	clear all
	set more off
	pause off
	mat drop _all
	
	// opening csv data file
	global car "C:\Users\Shumail Sajjad\Dropbox\ECON 330_Project_G1\01 Data\03 csv"
	import delimited "$car/CAR_DATA", clear
	
	br
	d
	codebook
	
	// dropping all the rows with missing values (if any)
	drop if missing(brand, condition, kmsdriven, model, price, registeredcity, transactiontype, year)
	
	tab brand, m
	tab condition, m
	// generating byte variables for top 4 brands and condition of car
	gen byte types = 0 if condition=="Used"
	replace types = 1 if condition=="New"
	
	label variable types "Condition status of car"
	label define types 0 "Used" 1 "New"
	label values types types 
	tab types, nolab
	
	gen byte top_4_brand = 0 if brand=="Daihatsu"
	replace top_4_brand = 1 if brand=="Honda"
	replace top_4_brand = 2 if brand=="Suzuki"
	replace top_4_brand = 3 if brand=="Toyota"
	
	label variable top_4_brand "Top 4 brands"
	label define top_4_brand 0 "Daihatsu" 1 "Honda" 2 "Suzuki" 3 "Toyota"
	label values top_4_brand top_4_brand 
	tab top_4_brand, nolab
	
	// generating car age
	gen int car_age = 2022- year
	label variable car_age "Age of car"
	tab car_age
	
	d
	br
	// generating all 8 categories (to cater for interaction)
	gen byte brand_type = 0 if brand=="Suzuki" & types ==0
	replace brand_type = 1 if brand=="Suzuki" & types ==1
	replace brand_type = 2 if brand=="Honda" & types ==0
	replace brand_type = 3 if brand=="Honda" & types ==1
	replace brand_type = 4 if brand=="Daihatsu" & types ==0
	replace brand_type = 5 if brand=="Daihatsu" & types ==1
	replace brand_type = 6 if brand=="Toyota" & types ==0
	replace brand_type = 7 if brand=="Toyota" & types ==1
	
	label variable brand_type "brand type"
	label define brand_type 0 "UsedSuzuki" 1 "NewSuzuki" 2 "UsedHonda" 3 "NewHonda" 4 "UsedDaihatsu" 5 "NewDaihatsu" 6 "UsedToyota" 7 "NewToyota"	
	label values brand_type brand_type
	tab brand_type
	
	regress price i.brand_type
	
	// for price vs log(price)
	histogram price, normal
	twoway scatter price brand_type || lfit price brand_type
	
	gen ln_price = log(price)
	regress ln_price i.brand_type 
	histogram ln_price, normal
	twoway scatter ln_price brand_type || lfit ln_price brand_type
	// so we will have a log-level relationship
	
	
	// more control variables (kmsdriven)
	//ln_kmsdriven vs kmsdriven
	regress ln_price i.brand_type kmsdriven 
	gen ln_kmsdriven = log(kmsdriven)
	regress ln_price i.brand_type ln_kmsdriven 
	twoway scatter ln_price ln_kmsdriven ||lfit ln_price ln_kmsdriven
	
	corr ln_price ln_kmsdriven
	// As R^2 adj of model is higher when ln_kmsdriven is used, we will use this functional form.	
	
	// test for multicollinearity
	vif //since all values of VIF are less than 2, multicollinearity is not an issue.
	
	// correlation matrix
	forvalues i=1/7 {
		gen brand_type`i'= `i'.brand_type
	}
	
	br
	correlate brand_type1 brand_type2 brand_type3 brand_type4  brand_type5 brand_type6 brand_type7 ln_kmsdriven 
	
	//test for biasedness + consistency 
	predict uhat, residual
	summ uhat
	correlate uhat brand_type1 brand_type2 brand_type3 brand_type4  brand_type5 brand_type6 brand_type7 ln_kmsdriven 	
	// So my estimates are consistent. What about bias?
	
	predict predicted_ln_price
	twoway scatter predicted_ln_price ln_price ||lfit 	predicted_ln_price ln_price // shows heteroskedasticity but linearity property is satisfied
	
	br
	
	ovtest //ramsay test
	//Since p value is less than 5%, we reject Ho and thus, our model has omitted variable bias. Estimates are biased. The functional form is also misspecified..
	// Omitted variable bias could be due to a) Measurement errors of explanatory variables--> CEV assumptions b) Omission of important variables such as: fuel average, car mpg etc 
	
	// test for homoskedasticity
	gen sq_uhat = uhat * uhat
	regress sq_uhat i.brand_type ln_kmsdriven
	test 1.brand_type 2.brand_type 3.brand_type 4.brand_type 5.brand_type 6.brand_type 7.brand_type ln_kmsdriven
	// the p-value is less than 5%, we cannot reject null. Model is jointly significant i.e., my square errors are related with the regressors. so the model is heteroskedastic
	
	
	// to counter heteroskedasticity
	regress ln_price i.brand_type ln_kmsdriven, robust
	
	//qq-plot (for errors normality)
	predict errors, residual
	qnorm errors // errors are normally distributed 
	
		// f-tests (test for overall significance) only accurate if model is unbiased and homoskedastic...
	regress ln_price i.brand_type ln_kmsdriven , robust
	test 1.brand_type 2.brand_type 3.brand_type 4.brand_type 5.brand_type 6.brand_type 7.brand_type ln_kmsdriven 
	
	// so the model is jointly signifcant.
	
	test 3.brand_type ln_kmsdriven
	test ln_kmsdriven
	test 1.brand_type 2.brand_type
	summ predicted_ln_price
	ttest ln_kmsdriven == predicted_ln_price
	
	br
	
	// Outputting regression results
	cd "C:\Users\Shumail Sajjad\Dropbox\ECON 330_Project_G1\03 Output"


	regress price i.brand_type , robust
	est store c1
	
	regress ln_price i.brand_type, robust
	est store c2
	
	regress ln_price i.brand_type kmsdriven, robust
	est store c3
	
	regress ln_price i.brand_type ln_kmsdriven, robust
	est store c4
	
	outreg2 [c*] using "Output_1", word label replace addstat (Adj R^2, e(r2_a))
	
	