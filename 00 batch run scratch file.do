cd "C:/Users/`c(username)'/Dropbox/CGD GlobalSat/HF_measures/code"
pause off
do "00 preliminaries.do"
do "04.02 analysis synthetic GDP.do"
do "04.05 all log levels.do"
do "04.08 data prep for RIP graph FE.do"
do "04.10 long difference graph.do"
do "04.11 covid dummy.do"
do "04.13 lockdown stringency regs.do"

// run like so:
// cd "C:\Users\gyang\Dropbox\CGD GlobalSat\HF_measures\input"
// "C:\Program Files\Stata16\StataMP-64.exe"  /e do "C:\Users\gyang\Dropbox\CGD GlobalSat\HF_measures\code\00 batch run scratch file.do"