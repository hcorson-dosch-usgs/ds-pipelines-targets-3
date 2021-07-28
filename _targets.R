
library(targets)
library(tarchetypes)
library(tibble)
suppressPackageStartupMessages(library(dplyr))
library(retry)

options(tidyverse.quiet = TRUE)
tar_option_set(packages = c("tidyverse", "dataRetrieval", "urbnmapr",
                            "rnaturalearth", "cowplot", "lubridate",
                            "leaflet", "leafpop", "htmlwidgets"))

# Load functions needed by targets below
source("1_fetch/src/find_oldest_sites.R")
source("1_fetch/src/get_site_data.R")
source("2_process/src/tally_site_obs.R")
source("2_process/src/summarize_targets.R")
source("3_visualize/src/map_sites.R")
source("3_visualize/src/plot_site_data.R")
source("3_visualize/src/plot_data_coverage.R")
source("3_visualize/src/map_timeseries.R")

# Configuration
states <- c('AL','AZ','AR','CA','CO','CT','DE','DC','FL','GA','ID','IL','IN','IA',
            'KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH',
            'NJ','NM','NY','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX',
            'UT','VT','VA','WA','WV','WI','WY','AK','HI','GU','PR')
parameter <- c('00060')

# Targets
list(
  # Identify oldest sites
  tar_target(
    oldest_active_sites,
    find_oldest_sites(states, parameter)
  ),

  tar_target(nwis_inventory,
               oldest_active_sites %>%
                 group_by(state_cd) %>%
                tar_group(),
             iteration = "group"
  ),

  tar_target(nwis_data,
             retry(get_site_data(nwis_inventory, nwis_inventory$state_cd, parameter),
                   when = 'Ugh, the internet data transfer failed! Try again.',
                   max_tries = 30),
             pattern = map(nwis_inventory)
  ),

  # Insert step for tallying data here
  tar_target(tally,
             tally_site_obs(site_data = nwis_data),
             pattern = map(nwis_data)
  ),

  # Insert step for plotting data here
  tar_target(timeseries_png,
             plot_site_data(out_file = sprintf('3_visualize/out/timeseries_%s.png', unique(nwis_data$State)), site_data = nwis_data, parameter = parameter),
             format = 'file',
             pattern = map(nwis_data)
  ),

  # summarize state data targets
  tar_target(
    summary_state_timeseries_csv,
    summarize_targets(
      '3_visualize/log/summary_state_timeseries.csv',
      names(timeseries_png)),
    format = "file"
  ),

  # plot data coverage
  tar_target(
    data_coverage_png,
    plot_data_coverage(
      oldest_site_tallies = tally,
      out_file = '3_visualize/out/data_coverage.png',
      parameter = parameter),
    format = "file"
  ),

  # Map oldest sites
  tar_target(
    site_map_png,
    map_sites("3_visualize/out/site_map.png", oldest_active_sites),
    format = "file"
  ),

  # generate leaflet map of site data
  tar_target(
    timeseries_map_html,
    map_timeseries(
      site_info = oldest_active_sites,
      plot_info_csv = summary_state_timeseries_csv,
      out_file = '3_visualize/out/timeseries_map.html'),
    format = "file"
  )
)
