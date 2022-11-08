library(tidyquant)
library(dplyr)
library(lubridate)
library(arrow)

date_string <- format(today(), "%Y%m%d")
parquet_path <- file.path("tidyquant/sp500/parquet", paste0(date_string, ".parquet"))
csv_path <- file.path("tidyquant/sp500/csv", paste0(date_string, ".csv"))


df <- tq_index("SP500")

message(paste0("saving ", date_string))

write_parquet(df, parquet_path)
write_csv_arrow(df, csv_path)
