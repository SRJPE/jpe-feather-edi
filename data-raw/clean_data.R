library(tidyverse)
library(knitr)
library(lubridate)
library(googleCloudStorageR)
library(Hmisc)
library(readxl)

# inspect data files ------------------------------------------------------

# catch
catch <- read_xlsx(here::here("data-raw", "feather_catch_edi.xlsx")) |> glimpse()
write_csv(catch, here::here("data","feather_catch.csv"))

# trap
trap <- read_xlsx(here::here("data-raw", "feather_trap_edi.xlsx")) |>
  glimpse()
write_csv(trap, here::here("data","feather_trap.csv"))

# recapture
recapture <- read_xlsx(here::here("data-raw", "feather_recaptures_edi.xlsx")) |> glimpse()
write_csv(recapture, here::here("data","feather_recapture.csv"))


# release
releases <- read_xlsx(here::here("data-raw", "feather_releases_edi.xlsx")) |> glimpse()
write_csv(releases, here::here("data","feather_release.csv"))

# release fish
# per butte edi example, don't need to upload this right now but keeping available for
# the future
release_fish <- read_xlsx(here::here("data-raw", "feather_releasefish_edi.xlsx")) |>
  glimpse()
write_csv(release_fish, here::here("data","feather_releasefish.csv"))


# look at clean data ------------------------------------------------------

catch <- read_csv(here::here("data", "feather_catch.csv")) |> glimpse()
trap <- read_csv(here::here("data", "feather_trap.csv")) |> glimpse()
recaptures <- read_csv(here::here("data", "feather_recapture.csv")) |> glimpse()
release <- read_csv(here::here("data", "feather_release.csv")) |> glimpse()
