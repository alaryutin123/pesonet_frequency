# PESONet account transaction frequency validation

Very simple native app for MacOS and Windows to check how many times the account is present in the processed file(s).
The frequency is something to validate, depending on the risk requirements

#Usage 

--file=<filename>     File to process. Can only be a .CSV file from Pesonet or the directory containing the CSV files.
                      (defaults to ".")
--freq=<frequency>    Check the frequency. Any account with above or equal to this frequency of entries will be highlighted in the script output
                      (defaults to "3")
