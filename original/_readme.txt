This directory contains the code necessary to reproduce Tables 1-4 and Appendix Tables A1-A6 of Aron-Dine, Einav and Finkelstein
"The RAND Health Insurance Experiment, Three Decades Later" published in the Winter 2013 issue of the Journal of Economic Perspectives.

It consists of one program and one folder of data.

The program tables.do uses the analysis data sets which are stored in the folder "Analysisdata" to produce all of the tables in the paper. The analysis data in turn were created using the underlying RAND data on ICPSR's website (see link in the JEP paper).

Note: running tables.do requires 
1. the installation of the stata program estout
to install it you can type "ssc install estout" at the command prompt in STATA.
2. to set the pathname for the input files and the output tables as directed at the top of the do file.
	
