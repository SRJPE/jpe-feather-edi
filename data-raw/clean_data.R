library(tidyverse)
library(knitr)
library(lubridate)
library(googleCloudStorageR)
library(Hmisc)
library(readxl)


# inspect data files ------------------------------------------------------

# catch
catch <- read_xlsx(here::here("data-raw", "feather_catch_edi.xlsx")) |> glimpse()

# trap
trap <- read_xlsx(here::here("data-raw", "feather_trap_edi.xlsx")) |>
  glimpse()
# note: waterVel column is 99.7% NAs, discharge column is 75.8% NAs

# recapture
recapture <- read_xlsx(here::here("data-raw", "feather_recaptures_edi.xlsx")) |>
  glimpse()

# release
releases <- read_xlsx(here::here("data-raw", "feather_releases_edi.xlsx")) |>
  glimpse()

# release fish
# per butte edi example, don't need to upload this right now but keeping available for
# the future
release_fish <- read_xlsx(here::here("data-raw", "feather_releasefish_edi.xlsx")) |>
  glimpse()

