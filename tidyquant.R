library(tidyquant)
library(dplyr)
library(lubridate)
library(arrow)

# Create data dirs
dir.create("tidyquant/sp500", showWarnings = F, recursive = T)
dir.create("tidyquant/sp500/parquet", showWarnings = F)
dir.create("tidyquant/sp500/csv", showWarnings = F)

date_string <- format(today(), "%Y%m%d")
parquet_path <- file.path("tidyquant/sp500/parquet", paste0(date_string, ".parquet"))
csv_path <- file.path("tidyquant/sp500/csv", paste0(date_string, ".csv"))


df <- tq_index("SP500")

message(paste0("saving ", date_string))

write_parquet(df_content, parquet_path)
write_csv_arrow(df_content, csv_path)
