
library(targets)
library(tarchetypes)
library(tibble)

options(tidyverse.quiet = TRUE)
tar_option_set(packages = c("tidyverse", "dataRetrieval", "urbnmapr", "rnaturalearth", "cowplot"))

# Load functions needed by targets below
source("1_fetch/src/find_oldest_sites.R")
source("1_fetch/src/get_site_data.R")
source("3_visualize/src/map_sites.R")

# Configuration
states <- c('WI','MN','MI','IL')
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
    values = tibble(state_abb = states),
    tar_target(nwis_data, get_site_data(oldest_active_sites, state_abb, parameter))
    # Insert step for tallying data here
    # Insert step for plotting data here
  ),

  # Map oldest sites
  tar_target(
    site_map_png,
    map_sites("3_visualize/out/site_map.png", oldest_active_sites),
    format = "file"
  )
)
