library(EMLaide)
library(tidyverse)
library(readxl)
library(EML)

datatable_metadata <-
  dplyr::tibble(filepath = c("data/environmental.csv",
                             "data/catch.csv",
                             "data/mark_existing.csv",
                             "data/release.csv",
                             "data/trap.csv"),
                attribute_info = c("data-raw/metadata/camp_environmental_metadata.xlsx",
                                   "data-raw/metadata/camp_catch_metadata.xlsx",
                                   "data-raw/metadata/camp_markexisting_metadata.xlsx",
                                   "data-raw/metadata/camp_release_metadata.xlsx",
                                   "data-raw/metadata/camp_trap_metadata.xlsx"),
                datatable_description = c("Environmental covariates",
                                          "Daily catch",
                                          "Existing marks on catch",
                                          "Release trial summary",
                                          "Daily trap operations"),
                datatable_url = paste0("https://raw.githubusercontent.com/FlowWest/jpe-feather-edi/main/data/",
                                       c("environmental.csv",
                                         "catch.csv",
                                         "mark_existing.csv",
                                         "release.csv",
                                         "trap.csv")))
# save cleaned data to `data/`
excel_path <- "data-raw/metadata/camp_metadata.xlsx"
sheets <- readxl::excel_sheets(excel_path)
metadata <- lapply(sheets, function(x) readxl::read_excel(excel_path, sheet = x))
names(metadata) <- sheets

abstract_docx <- "data-raw/metadata/abstract.docx"
methods_docx <- "data-raw/metadata/method.docx"

#edi_number <- reserve_edi_id(user_id = Sys.getenv("EDI_USER_ID"), password = Sys.getenv("EDI_PASSWORD"))
edi_number <- "edi.1239.1"

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
# custom_units <- data.frame(id = c("number of fish", "rotations per minute", "rotations", "nephelometric turbidity units", "day"),
#                            unitType = c("density", "dimensionless", "dimensionless", "dimensionless", "dimensionless"),
#                            parentSI = c(NA, NA, NA, NA, NA),
#                            multiplierToSI = c(NA, NA, NA, NA, NA),
#                            description = c("Fish density in the enclosure, number of fish in total enclosure space",
#                                            "Number of trap rotations in one minute",
#                                            "Total rotations",
#                                            "Nephelometric turbidity units, common unit for measuring turbidity",
#                                            "The day sampling occured"))

# unitList <- EML::set_unitList(custom_units)

eml <- list(packageId = edi_number,
            system = "EDI",
            access = add_access(),
            dataset = dataset
            # additionalMetadata = list(metadata = list(unitList = unitList))
            )
edi_number
EML::write_eml(eml, "edi.1239.1.xml")
EML::eml_validate("edi.1239.1.xml")

# EMLaide::evaluate_edi_package(Sys.getenv("user_ID"), Sys.getenv("password"), "edi.1047.1.xml")
# EMLaide::upload_edi_package(Sys.getenv("user_ID"), Sys.getenv("password"), "edi.1047.1.xml")
doc <- read_xml("edi.1239.1.xml")
edi_number<- data.frame(edi_number = doc %>% xml_attr("packageId"))
update_number <- edi_number %>%
  separate(edi_number, c("edi","package","version"), "\\.") %>%
  mutate(version = as.numeric(version) + 1)
edi_number <- paste0(update_number$edi, ".", update_number$package, ".", update_number$version)