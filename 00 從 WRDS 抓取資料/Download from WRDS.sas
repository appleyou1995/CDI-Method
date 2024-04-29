
/* Login to WRDS database */ 

%let wrds = wrds-cloud.wharton.upenn.edu 4016;
signon wrds 
	username = irisyu 
	password = "{SAS002}B28693282280808C22DE966B3CD759E521D2B934";



/* Encoding WRDS Password */

/*PROC PWENCODE in='my_password';*/
/*run;*/



/* Set mylib path */
rsubmit;
libname home "~/";


/* define library */

rsubmit;
libname compf '/wrds/comp/sasdata/naa'; /* COMPUSTAT FUNDA*/
libname crspm '/wrds/crsp/sasdata/a_stock'; /*crsp msf*/











/*µn¥X WRDS*/

signoff;