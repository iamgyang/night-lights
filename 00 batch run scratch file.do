cd "C:/Users/`c(username)'/Dropbox/CGD GlobalSat/HF_measures/code"
pause off
do "00 preliminaries.do"
do "01.3 clean DMSP.do"
do "01.8 clean DMSP.do"
do "03.1 merge_iso3c_yr.do"
do "03.2 iso3c year aggregation.do"
do "03.3 ADM 1 year aggregation.do"
do "03.4 ADM 2 year aggregation.do"
do "04.02 windowed regs.do"
do "04.05 all log levels.do"






do "00 preliminaries.do"
do "01.8 clean DMSP.do"


do "02.80 clean BM - OECD TL3 ADM2 data.do"
do "04.05 all log levels.do"

do "01.7 clean barro data.do"
do "04.17 barro alt measure regs.do"


do "04.16 barro reg.do"
do "02.73 clean subnatl GRP.do"
do "03.1 merge_iso3c_yr.do"
do "03.2 subsets_and_collapsing_iso3c_yr.do"
do "04.11 covid dummy.do"
do "04.02 analysis synthetic GDP.do"
do "04.08 data prep for RIP graph FE.do"
do "04.10 long difference graph.do"
do "04.13 lockdown stringency regs.do"

// run like so:
// cd "C:\Users\gyang\Dropbox\CGD GlobalSat\HF_measures\input"
// "C:\Program Files\Stata16\StataMP-64.exe"  /e do "C:\Users\gyang\Dropbox\CGD GlobalSat\HF_measures\code\00 batch run scratch file.do"

do "04.15 regressions across latitude bands.do"