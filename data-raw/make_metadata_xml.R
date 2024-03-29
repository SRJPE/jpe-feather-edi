library(EMLaide)
library(dplyr)
library(readxl)
library(EML)

secret_edi_username = Sys.getenv("EDI_USERNAME")
secret_edi_password = Sys.getenv("EDI_PASSWORD")

datatable_metadata <-
  dplyr::tibble(filepath = c("data/feather_catch.csv",
                             "data/feather_recapture.csv",
                             "data/feather_release.csv",
                             "data/feather_trap.csv"),
                attribute_info = c("data-raw/metadata/feather_catch_metadata.xlsx",
                                   "data-raw/metadata/feather_recapture_metadata.xlsx",
                                   "data-raw/metadata/feather_release_metadata.xlsx",
                                   "data-raw/metadata/feather_trap_metadata.xlsx"),
                datatable_description = c("Daily catch",
                                          "Recaptured catch",
                                          "Release trial summary",
                                          "Daily trap operations"),
                datatable_url = paste0("https://raw.githubusercontent.com/SRJPE/jpe-feather-edi/main/data/",
                                       c("feather_catch.csv",
                                         "feather_recapture.csv",
                                         "feather_release.csv",
                                         "feather_trap.csv")))
# save cleaned data to `data/`
excel_path <- "data-raw/metadata/feather_metadata.xlsx"
sheets <- readxl::excel_sheets(excel_path)
metadata <- lapply(sheets, function(x) readxl::read_excel(excel_path, sheet = x))
names(metadata) <- sheets

abstract_docx <- "data-raw/metadata/abstract.docx"
# methods_docx <- "data-raw/metadata/method.docx"
methods_docx <- "data-raw/metadata/methods.md"

#update metadata
catch_df <- readr::read_csv("data/feather_catch.csv")
catch_coverage <- tail(catch_df$visitTime, 1)
metadata$coverage$end_date <- lubridate::floor_date(catch_coverage, unit = "days")

wb <- openxlsx::createWorkbook()
for (sheet_name in names(metadata)) {
  openxlsx::addWorksheet(wb, sheetName = sheet_name)
  openxlsx::writeData(wb, sheet = sheet_name, x = metadata[[sheet_name]], rowNames = FALSE)
}
openxlsx::saveWorkbook(wb, file = excel_path, overwrite=TRUE)

#edi_number <- reserve_edi_id(user_id = Sys.getenv("EDI_USER_ID"), password = Sys.getenv("EDI_PASSWORD"))
# edi_number <- "edi.1239.2"

# Version log for tracking EDI number and versions
vl <- readr::read_csv("data-raw/version_log.csv", col_types = c('c', "D"))
previous_edi_number <- tail(vl['edi_version'], n=1)
previous_edi_number <- previous_edi_number$edi_version
previous_edi_ver <- as.numeric(stringr::str_extract(previous_edi_number, "[^.]*$"))
current_edi_ver <- as.character(previous_edi_ver + 1)
previous_edi_id_list <- stringr::str_split(previous_edi_number, "\\.")
previous_edi_id <- sapply(previous_edi_id_list, '[[', 2)
current_edi_number <- paste0("edi.", previous_edi_id, ".", current_edi_ver)

new_row <- data.frame(
  edi_version = current_edi_number,
  date = as.character(Sys.Date())
)
vl <- bind_rows(vl, new_row)
write.csv(vl, "data-raw/version_log.csv", row.names=FALSE)

dataset <- list() %>%
  add_pub_date() %>%
  add_title(metadata$title) %>%
  add_personnel(metadata$personnel) %>%
  add_keyword_set(metadata$keyword_set) %>%
  add_abstract(abstract_docx) %>%
  add_license(metadata$license) %>%
  add_method(methods_docx) %>%
  add_maintenance(metadata$maintenance) %>%
  add_project(metadata$funding) %>%
  add_coverage(metadata$coverage, metadata$taxonomic_coverage) %>%
  add_datatable(datatable_metadata)

# GO through and check on all units
custom_units <- data.frame(id = c("number of rotations", "NTU", "revolutions per minute", "number of fish", "days"),
                           unitType = c("dimensionless", "dimensionless", "dimensionless", "dimensionless", "dimensionless"),
                           parentSI = c(NA, NA, NA, NA, NA),
                           multiplierToSI = c(NA, NA, NA, NA, NA),
                           description = c("number of rotations",
                                           "nephelometric turbidity units, common unit for measuring turbidity",
                                           "number of revolutions per minute",
                                           "number of fish counted",
                                           "number of days"))

unitList <- EML::set_unitList(custom_units)

eml <- list(packageId = current_edi_number,
            system = "EDI",
            access = add_access(),
            dataset = dataset,
            additionalMetadata = list(metadata = list(unitList = unitList))
            )

EML::write_eml(eml, paste0(current_edi_number, ".xml"))
message("EML Metadata generated")
#EML::eml_validate("edi.1239.2.xml")

# EMLaide::evaluate_edi_package(user_id = Sys.getenv("EDI_USER_ID"),
#                                           password = Sys.getenv("EDI_PASSWORD"),
#                                           eml_file_path = "edi.1239.3.xml")

# EMLaide::upload_edi_package(user_id = Sys.getenv("EDI_USER_ID"),
#                             password = Sys.getenv("EDI_PASSWORD"),
#                             eml_file_path = "edi.1239.2.xml",
#                             environment = "staging")
# EMLaide::update_edi_package(user_id = Sys.getenv("EDI_USER_ID"),
#                             password = Sys.getenv("EDI_PASSWORD"),
#                             eml_file_path = "edi.1239.2.xml",
#                             existing_package_identifier = "edi.1239.1")
# doc <- read_xml("edi.1239.1.xml")
# edi_number<- data.frame(edi_number = doc %>% xml_attr("packageId"))
# update_number <- edi_number %>%
#   separate(edi_number, c("edi","package","version"), "\\.") %>%
#   mutate(version = as.numeric(version) + 1)
# edi_number <- paste0(update_number$edi, ".", update_number$package, ".", update_number$version)

EMLaide::update_edi_package(user_id = secret_edi_username,
                            password = secret_edi_password,
                            eml_file_path = paste0(getwd(), "/", current_edi_number, ".xml"),
                            existing_package_identifier = paste0("edi.",previous_edi_id, ".", previous_edi_ver, ".xml"),
                            environment = "production")
