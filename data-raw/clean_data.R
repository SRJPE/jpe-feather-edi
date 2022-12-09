library(tidyverse)
library(knitr)
library(lubridate)
library(googleCloudStorageR)
library(Hmisc)

gcs_auth(json_file = Sys.getenv("GCS_AUTH_FILE"))
gcs_global_bucket(bucket = Sys.getenv("GCS_DEFAULT_BUCKET"))

gcs_get_object(object_name = "rst/CAMP/feather_river/CAMP.mdb",
               bucket = gcs_get_global_bucket(),
               saveToDisk = here::here("data-raw","CAMP.mdb"),
               overwrite = TRUE)
feather_camp <- (here::here("data-raw", "CAMP.mdb"))

catch_raw <- mdb.get(feather_camp, tables = "CatchRaw")
trap_visit <- mdb.get(feather_camp, tables = "TrapVisit") %>%
  mutate(visitTime = as.POSIXct(visitTime),
         visitTime2 = as.POSIXct(visitTime2))
site_lu <- mdb.get(feather_camp, "Site") %>%
  select(siteName, siteID)
subsite_lu <- mdb.get(feather_camp, "SubSite") %>%
  select(subSiteName, subSiteID, siteID) %>%
  filter(subSiteName != "N/A")
release <- mdb.get(feather_camp, tables = "Release") %>%
  mutate(releaseTime = as.POSIXct(releaseTime))
mark_applied <- mdb.get(feather_camp, tables = "MarkApplied")
mark <-  mdb.get(feather_camp, tables = "MarkExisting")
environmental <- mdb.get(feather_camp, tables = "EnvDataRaw")

# Format trap table for EDI
trap_visit_format <- trap_visit %>%
  select(projectDescriptionID, trapVisitID, trapPositionID, visitTime, visitTime2,
         visitTypeID, fishProcessedID, inThalwegID, trapFunctioningID, counterAtStart,
         counterAtEnd, rpmRevolutionsAtStart, rpmSecondsAtStart, rpmRevolutionsAtEnd,
         rpmSecondsAtEnd, halfConeID, includeCatchID, debrisVolumeCatID, debrisVolume,
         debrisVolumeUnits) %>%
  left_join(subsite_lu, by = c("trapPositionID" = "subSiteID")) %>%
  select(-subSiteName) %>%
  relocate(siteID, .before = trapPositionID)

write_csv(trap_visit_format, here::here("data", "trap.csv"))

# Format catch table for EDI
catch_format <- catch_raw %>%
  select(projectDescriptionID, catchRawID, trapVisitID, taxonID, atCaptureRunID,
         atCaptureRunMethodID, finalRunID, finalRunMethodID, fishOriginID,
         lifeStageID, forkLength, totalLength, weight, n, randomID, actualCountID,
         releaseID, mortID) %>%
  left_join(trap_visit_format %>%
              select(projectDescriptionID, trapVisitID, visitTime, visitTime2, visitTypeID, siteID, trapPositionID),
            by = c("trapVisitID" = "trapVisitID", "projectDescriptionID" = "projectDescriptionID")) %>%
  relocate(releaseID, .before = taxonID)

write_csv(catch_format, here::here("data", "catch.csv"))

# Format release table for EDI
release_format <- release %>%
  select(projectDescriptionID, releaseID, releasePurposeID, markedTaxonID,
         markedRunID, markedLifeStageID, markedFishOriginID, sourceOfFishSiteID,
         releaseSiteID, releaseSubSiteID, nMortWhileHandling, nMortAtCheck,
         nReleased, releaseTime, releaseLightConditionID,
         testDays, includeTestID) %>%
  left_join(mark_applied %>%
              select(projectDescriptionID, releaseID, appliedMarkTypeID, appliedMarkColorID, appliedMarkPositionID, appliedMarkCode),
            by = c("projectDescriptionID" = "projectDescriptionID", "releaseID" = "releaseID"))
write_csv(release_format, here::here("data", "release.csv"))

# Format for mark existing table for EDI
mark_existing_format <- mark %>%
  select(projectDescriptionID, catchRawID, markExistingID, markTypeID, markColorID, markPositionID, markCode)
write_csv(mark_existing_format, here::here("data", "mark_existing.csv"))

# Format for environmental table for EDI
environmental_format <- environmental %>%
  select(projectDescriptionID, envDataRawID, trapVisitID, discharge, dischargeUnitID, dischargeSampleGearID, waterVel, waterVelUnitID,
         waterVelSampleGearID, waterTemp, waterTempUnitID, waterTempSampleGearID, lightPenetration, lightPenetrationUnitID, lightPenetrationSampleGearID,
         turbidity, turbidityUnitID, turbiditySampleGearID) %>%
  left_join(trap_visit_format %>%
              select(projectDescriptionID, trapVisitID, visitTime, visitTime2, visitTypeID, siteID, trapPositionID),
            by = c("trapVisitID" = "trapVisitID", "projectDescriptionID" = "projectDescriptionID"))
write_csv(environmental_format, here::here("data", "environmental.csv"))


# inspect data files ------------------------------------------------------

# catch
catch <- read_csv(here::here("data", "catch.csv")) |>
  glimpse()

# TODO NAs in some columns
# TODO definition for finalRunMethodID?
unique(catch$projectDescriptionID)
unique(catch$catchRawID)
unique(catch$trapVisitID)
unique(catch$releaseID)
unique(catch$taxonID)
unique(catch$atCaptureRunID)
unique(catch$atCaptureRunMethodID)
unique(catch$finalRunID)
sum(is.na(catch$finalRunID))/length(catch$finalRunID) # some NAs here
unique(catch$finalRunMethodID)
sum(is.na(catch$finalRunMethodID))/length(catch$finalRunMethodID) # some NAs here - are these the same columns?
unique(catch$fishOriginID)
unique(catch$lifeStageID)
plot(catch$forkLength)
sum(is.na(catch$forkLength))/length(catch$forkLength) # 0.18 NAs
plot(catch$totalLength)
sum(is.na(catch$totalLength))/length(catch$totalLength) # 0.89 NAs
plot(catch$weight)
sum(is.na(catch$weight))/length(catch$weight) # 0.9998 NAs
plot(catch$n)
unique(catch$randomID)
unique(catch$actualCountID)
unique(catch$mortID)
range(catch$visitTime)
range(catch$visitTime2)
unique(catch$visitTypeID)
unique(catch$siteID)
unique(catch$trapPositionID)

# release
release <- read_csv(here::here("data", "release.csv")) |>
  glimpse()

# TODO: NAs in some columns
unique(release$projectDescriptionID)
unique(release$releaseID)
unique(release$releasePurposeID)
unique(release$markedTaxonID)
unique(release$markedRunID)
unique(release$markedLifeStageID)
sum(is.na(release$markedLifeStageID))/length(release$markedLifeStageID) # 0.81 NAs
unique(release$markedFishOriginID)
unique(release$sourceOfFishSiteID)
sum(is.na(release$sourceOfFishSiteID))/length(release$sourceOfFishSiteID) # 0.54 NAs
unique(release$releaseSiteID)
unique(release$releaseSubSiteID)
sum(is.na(release$releaseSubSiteID))/length(release$releaseSubSiteID) # 0.02 NAs
plot(release$nMortWhileHandling)
sum(is.na(release$nMortWhileHandling))/length(release$nMortWhileHandling) # 0.98 NAs
plot(release$nMortAtCheck)
sum(is.na(release$nMortAtCheck))/length(release$nMortAtCheck) # 0.24 NAs
plot(release$nReleased)
unique(release$releaseTime)
unique(release$releaseLightConditionID)
sum(is.na(release$releaseLightConditionID))/length(release$releaseLightConditionID) # 0.23 NAs
unique(release$testDays)
unique(release$includeTestID)
unique(release$appliedMarkTypeID)
sum(is.na(release$appliedMarkTypeID))/length(release$appliedMarkTypeID) # 0.005 NAs
unique(release$appliedMarkColorID)
sum(is.na(release$appliedMarkColorID))/length(release$appliedMarkColorID) # 0.005 NAs
unique(release$appliedMarkPositionID)
sum(is.na(release$appliedMarkPositionID))/length(release$appliedMarkPositionID) # 0.005 NAs
unique(release$appliedMarkCode) # 100% NAs

# trap
trap <- read_csv(here::here("data", "trap.csv")) |> glimpse()

# TODO some NAs in columns
# TODO Descriptions for several variables: inThalwegID, counterAtStart, counteratEnd, etc.
# TODO units for rpmSecondsAtStart, rpmSecondsAtEnd
# TODO measurement scale for some variables (debris Volume)
unique(trap$projectDescriptionID)
unique(trap$trapVisitID)
unique(trap$siteID)
unique(trap$trapPositionID)
unique(trap$visitTime)
unique(trap$visitTime2)
unique(trap$visitTypeID)
unique(trap$fishProcessedID)
unique(trap$inThalwegID)
unique(trap$trapFunctioningID)
unique(trap$counterAtStart) # 0.94 NAs
unique(trap$counterAtEnd) # 0.34 NAs
unique(trap$rpmRevolutionsAtStart) # 0.14 NAs
unique(trap$rpmSecondsAtStart) # 0.14 NAs
unique(trap$rpmRevolutionsAtEnd) # 0.11 NAs
unique(trap$rpmSecondsAtEnd)
unique(trap$halfConeID)
unique(trap$includeCatchID)
unique(trap$debrisVolumeCatID) # 100% NAs
unique(trap$debrisVolume) # 100% NAs
unique(trap$debrisVolumeUnits) # 100% NAs


# environmental
environmental <- read_csv(here::here("data", "environmental.csv")) |>
  glimpse()

# TODO some columns have NAs
# TODO some descriptions not clear for variables
sum(is.na(environmental$discharge))/nrow(environmental)
sum(is.na(environmental$dischargeUnitID))/nrow(environmental)
sum(is.na(environmental$dischargeSampleGearID))/nrow(environmental)
sum(is.na(environmental$waterVel))/nrow(environmental)
sum(is.na(environmental$waterVelUnitID))/nrow(environmental)
sum(is.na(environmental$waterVelSampleGearID))/nrow(environmental)
sum(is.na(environmental$turbidity))/nrow(environmental)
sum(is.na(environmental$turbidityUnitID))/nrow(environmental)
sum(is.na(environmental$turbiditySampleGearID))/nrow(environmental)

unique(environmental$siteID)

# mark_existing
mark_existing <- read_csv(here::here("data", "mark_existing.csv")) |> glimpse()
# TODO markCode column is 100% NAs
# TODO variable description for markExisting ID
# TODO measurement scale and domain for markCode
