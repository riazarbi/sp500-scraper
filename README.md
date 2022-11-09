# sp500-scraper

Constituent history of the S&P 500 from various data sources. 

## Usage

Each data source is queried once a day, during weekdays. The data is saved in two formats - `csv` and `parquet`. Generally, each run is saved with the file name convention `YYYYMMDD`. I prefer to interact with this data using `arrow`.

First clone the repo:

```bash
git clone https://github.com/riazarbi/sp500-scraper
```

Then, in R (adapt to your language)

```R
library(arrow)
open_dataset("sp500-scraper/wikipedia/sp500/parquet, unify_schemas = TRUE")
```

## Data Source Notes

How far back this data goes depends on how far back I could parse data from websites. 

### iShares

STATUS: working  
FIRST DATE: 2006-10-31

The iShares symbols differ sometimes from SEC tickers (see, for example, Visa Corp in each dataset). This source does include ISIN though.


### Wikipedia

STATUS: working  
FIRST DATE: 2007-03-07

Seems to conform to SEC tickers. The data structure has evolved over time; I've kept all the columns but tried to rename to line them up as best as possible. CIK was added on 2014-05-12, which makes symbol joining much easier. 

Pre 2022-11-01 was collected by traversing Wikipedia commit history. We pulled all the revisions, omitted any changes that changed a large percentage of symbols, or were themselves overwritten within 12 hours. We hope this will eliminate spurious changes.

Post 2022-11-01 parsed html tables, pre 2022-11-01 parsed wikitext.

### Tidyquant

STATUS: working  
FIRST DATE: 2022-11-08

We simply run `tidyquant::tq_index("SP500")` and save the result to file. It contains the SEDOL and CUSIP numbers.

## Useful links

SEC ticker <-> CIK mappings : https://www.sec.gov/include/ticker.txt

