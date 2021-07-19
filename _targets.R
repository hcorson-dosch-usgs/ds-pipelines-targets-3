
library(targets)
library(tarchetypes)
library(tibble)
suppressPackageStartupMessages(library(dplyr))

options(tidyverse.quiet = TRUE)
tar_option_set(packages = c("tidyverse", "dataRetrieval", "urbnmapr", "rnaturalearth", "cowplot", "lubridate"))

# Load functions needed by targets below
source("1_fetch/src/find_oldest_sites.R")
source("1_fetch/src/get_site_data.R")
source("2_process/src/tally_site_obs.R")
source("3_visualize/src/map_sites.R")
source("3_visualize/src/plot_site_data.R")

# Configuration
states <- c('WI','MN','MI','IL','IN','IA')
parameter <- c('00060')

# Targets
list(
  # Identify oldest sites
  tar_target(
    oldest_active_sites,
    find_oldest_sites(states, parameter)
  ),

  # PULL SITE DATA
  tar_map(
    values = tibble(state_abb = states,
                    state_plot_files = sprintf('3_visualize/out/timeseries_%s.png', state_abb)),
    names = state_abb,
    tar_target(nwis_inventory,
               {
                 oldest_active_sites %>%
                   filter(state_cd == state_abb)
               }
    ),
    tar_target(nwis_data,
               get_site_data(
                 nwis_inventory,
                 state_abb,
                 parameter)
    ),
    # Insert step for tallying data here
    tar_target(tally,
               tally_site_obs(
                 site_data = nwis_data
               )
    ),
    # Insert step for plotting data here
    tar_target(timeseries_png,
               plot_site_data(
                 out_file = state_plot_files,
                 site_data = nwis_data,
                 parameter = parameter
               ),
               format = 'file'
    )
  ),

  # Map oldest sites
  tar_target(
    site_map_png,
    map_sites("3_visualize/out/site_map.png", oldest_active_sites),
    format = "file"
  )
)
