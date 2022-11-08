library(WikipediR)
library(rvest)
library(arrow)
library(dplyr)
library(lubridate)

# Create data dirs
dir.create("wikipedia", showWarnings = F)

dir.create("wikipedia/sp500/parquet", showWarnings = F)
dir.create("wikipedia/sp500/csv", showWarnings = F)

date_string <- format(today(), "%Y%m%d")
parquet_path <- file.path("wikipedia/sp500/parquet", paste0(date_string, ".parquet"))
csv_path <- file.path("wikipedia/sp500/csv", paste0(date_string, ".csv"))

wiki <- page_content("en","wikipedia", page_name = "List of S&P 500 companies")

wiki_html <- wiki$parse$text
wiki_parsed <- read_html(wiki_html$`*`)
df <- wiki_parsed |>
  html_element("#constituents") |>
  html_table() |>
  mutate(date = today())

write_parquet(df, parquet_path)
write_csv_arrow(df, csv_path)
