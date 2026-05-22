# Save the iShares Core S&P 500 ETF (IVV) holdings.
#
# Background: iShares retired the old `*.ajax?fileType=json` holdings endpoint
# some time in 2026 -- it now returns the product-page HTML instead of JSON.
# This script uses the JSON API that powers the "Holdings" table on the product
# page itself (https://www.ishares.com/us/products/239726/ishares-core-sp-500-etf).
# That API exposes every column the old feed did, including CUSIP/ISIN/SEDOL.
#
# Omitting `asOfDate` returns the most recent holdings available. The response
# reports its own as-of date, which we use to name the output files and as the
# `date` column -- so the file date is the true data date (it lags the run
# date by ~1 trading day), and re-running is idempotent.

library(httr)
library(jsonlite)
library(lubridate)
library(arrow)

# Create data dirs
dir.create("ishares", showWarnings = FALSE)
dir.create("ishares/sp500", showWarnings = FALSE)
dir.create("ishares/sp500/parquet", showWarnings = FALSE)
dir.create("ishares/sp500/csv", showWarnings = FALSE)

# portfolioId 239726 == iShares Core S&P 500 ETF (IVV).
url <- paste0(
  "https://www.blackrock.com/varnish-api/blk-one01-product-data/product-data",
  "/api/v2/get-product-data",
  "?appType=PRODUCT_PAGE&appSubType=ISHARES&targetSite=us-ishares",
  "&locale=en_US&portfolioId=239726&userType=individual&component=holdings"
)

result <- httr::GET(url, httr::timeout(60))
httr::stop_for_status(result, task = "fetch iShares S&P 500 holdings")

if (!grepl("json", httr::http_type(result), ignore.case = TRUE)) {
  stop("Expected a JSON response but got '", httr::http_type(result),
       "'. The iShares holdings API may have changed.")
}

# simplifyVector = TRUE turns each data point's `value` array into an atomic
# vector, with JSON nulls becoming NA.
json <- jsonlite::fromJSON(
  httr::content(result, as = "text", encoding = "UTF-8"),
  simplifyVector = TRUE
)

dp <- json$componentsByNameMap$holdings$containersByNameMap$all$dataPointsByNameMap
if (is.null(dp)) {
  stop("Could not locate holdings data in the API response. ",
       "The response structure may have changed.")
}

# As-of date reported by the API, e.g. 20260521.
as_of_int <- dp$asOfDate$value[1]
if (is.null(as_of_int) || is.na(as_of_int)) {
  stop("API response did not include an as-of date.")
}
as_of_date  <- lubridate::ymd(as_of_int)
date_string <- format(as_of_date, "%Y%m%d")

# The holdings table stores each field as a column of parallel arrays. Pull one
# field, checking it is present and aligned with the others.
n_rows <- length(dp$ticker$value)
col <- function(field, key = "value") {
  v <- dp[[field]][[key]]
  if (is.null(v) || length(v) != n_rows) {
    stop("Field '", field, "' is missing or misaligned in the API response.")
  }
  v
}

df_content <- data.frame(
  symbol          = col("ticker"),
  name            = col("issueName"),
  sector          = col("sectorName"),
  asset_class     = col("assetClass"),
  market_value    = col("marketValue"),
  weight_pct      = col("holdingPercent"),
  notional_value  = col("notionalValue"),
  shares          = col("unitsHeld"),
  CUSIP           = col("cusip"),
  ISIN            = col("isin"),
  SEDOL           = col("sedol"),
  price           = col("unitPrice"),
  location        = col("countryOfRisk"),
  exchange        = col("exchange"),
  market_currency = col("currencyCode"),
  fx_rate         = col("localFxRate"),
  # accrualDate's `value` is an integer (or null); its formattedValue is the
  # human-readable string the old feed produced (and "-" when absent).
  accrual_date    = col("accrualDate", "formattedValue"),
  stringsAsFactors = FALSE
)

if (nrow(df_content) < 300) {
  stop("Number of rows less than 300 on date ", date_string,
       ". Perhaps the script is broken?")
}

# The old feed used "-" as the missing-value sentinel for text fields (e.g.
# CUSIP/ISIN/SEDOL for non-US-domiciled holdings); the new API uses null.
# Convert back so the schema is unchanged.
char_cols <- c("symbol", "name", "sector", "asset_class", "CUSIP", "ISIN",
               "SEDOL", "location", "exchange", "market_currency", "accrual_date")
df_content[char_cols] <- lapply(df_content[char_cols], function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "-"
  x
})

num_cols <- c("market_value", "weight_pct", "notional_value", "shares",
              "price", "fx_rate")
df_content[num_cols] <- lapply(df_content[num_cols], as.numeric)

df_content$date <- as_of_date

parquet_path <- file.path("ishares/sp500/parquet", paste0(date_string, ".parquet"))
csv_path     <- file.path("ishares/sp500/csv", paste0(date_string, ".csv"))

message("saving ", date_string)

write_parquet(df_content, parquet_path)
write_csv_arrow(df_content, csv_path)
