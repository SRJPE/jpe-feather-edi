library(tidyverse)
library(knitr)
library(lubridate)
library(googleCloudStorageR)
library(Hmisc)
library(readxl)

# inspect data files ------------------------------------------------------

# catch
catch <- read_xlsx(here::here("data-raw", "feather_catch_edi.xlsx")) |> glimpse()
write_csv(catch, here::here("data","feather_catch_edi.csv"))

# trap
trap <- read_xlsx(here::here("data-raw", "feather_trap_edi.xlsx")) |>
  glimpse()
write_csv(trap, here::here("data","feather_trap_edi.csv"))

# recapture
recapture <- read_xlsx(here::here("data-raw", "feather_recaptures_edi.xlsx"),
                       col_types = c("numeric", "numeric", "numeric",
                                     "text", "numeric", "text",
                                     "text", "text", "text",
                                     "numeric", "numeric", "numeric",
                                     "numeric", "date", "text",
                                     "text", "text", "text",
                                     "text", "text", "text")) |>
  glimpse()
write_csv(recapture, here::here("data","feather_recaptures_edi.csv"))


# release
releases <- read_xlsx(here::here("data-raw", "feather_releases_edi.xlsx"),
                      col_types = c("numeric", "numeric", "date",
                                    "text", "text", "text",
                                    "text", "text", "text",
                                    "text", "numeric", "numeric",
                                    "text", "text", "text",
                                    "text", "text")) |>
  glimpse()
write_csv(releases, here::here("data","feather_releases_edi.csv"))

# release fish
# per butte edi example, don't need to upload this right now but keeping available for
# the future
release_fish <- read_xlsx(here::here("data-raw", "feather_releasefish_edi.xlsx")) |>
  glimpse()
write_csv(release_fish, here::here("data","feather_releasefish_edi.csv"))


# look at clean data ------------------------------------------------------

catch <- read_csv(here::here("data", "feather_catch_edi.csv")) |> glimpse()
trap <- read_csv(here::here("data", "feather_trap_edi.csv")) |> glimpse()
recaptures <- read_csv(here::here("data", "feather_recaptures_edi.csv")) |> glimpse()
release <- read_csv(here::here("data", "feather_releases_edi.csv")) |> glimpse()
