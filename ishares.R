# Load libraries
library(dplyr)
library(lubridate)
library(httr)
library(data.table)
library(arrow)

# Create data dirs
dir.create("ishares", showWarnings = F)
dir.create("ishares/sp500/parquet", showWarnings = F)
dir.create("ishares/sp500/csv", showWarnings = F)

date_string <- format(today(), "%Y%m%d")
parquet_path <- file.path("ishares/sp500/parquet", paste0(date_string, ".parquet"))
csv_path <- file.path("ishares/sp500/csv", paste0(date_string, ".csv"))

url <- paste0("https://www.ishares.com/us/products/239726/ishares-core-sp-500-etf/1467271812596.ajax?tab=all&fileType=json")
result <- httr::GET(url)
json_content <- content(result)
df_content <- setDF(rbindlist(json_content$aaData))

if(nrow(df_content) < 300) {stop(paste0("Number of rows less than 300 on date ", date_string, ". Perhaps the script is broken?"))}

df_content <- df_content |>
  filter(!grepl("[$]",V5))

df_content <- df_content |>
  rename(symbol = V1,
         name = V2,
         sector = V3,
         asset_class = V4,
         market_value = V5,
         weight_pct = V6,
         notional_value = V7,
         shares = V8,
         CUSIP = V9,
         ISIN = V10,
         SEDOL = V11,
         price = V12,
         location = V13,
         exchange = V14,
         market_currency = V15,
         fx_rate = V16,
         accrual_date = V17) |>
  mutate(market_value = as.numeric(market_value),
         weight_pct = as.numeric(weight_pct),
         notional_value = as.numeric(notional_value),
         shares = as.numeric(shares),
         price = as.numeric(price),
         fx_rate = as.numeric(fx_rate)) |>
  mutate(date = today())

message(paste0("saving ", date_string))

write_parquet(df_content, parquet_path)
write_csv_arrow(df_content, csv_path)
