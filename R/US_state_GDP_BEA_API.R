EU <- name2code(EU)
OECD <- name2code(OECD)
code2name(setdiff(OECD, EU))
install.packages('bea.R')
library(bea.R)

beaKey 	<- 'DEBB3E43-690C-4457-A46C-835FF2A36261'
bea_search_results <- beaSearch('gross|product', beaKey)
beaSpecs <- list(
    'UserID' = beaKey ,
    'Method' = 'GetData',
    'datasetname' = 'NIPA',
    'TableName' = 'T10101',
    'Frequency' = 'Q',
    'Year' = 'X',
    'ResultFormat' = 'json'
)
beaPayload <- beaGet(beaSpecs)
beaLong <- beaGet(beaSpecs, asWide = FALSE)
beaStatTab <- beaGet(beaSpecs, iTableStyle = FALSE)
###OK this was actually not needed