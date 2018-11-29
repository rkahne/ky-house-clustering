#############################################################################################################
##  CLUSTERING KENTUCKY HOUSE DISTRICTS                                                                     #
##                                                                                                          #
##  Robert Kahne                                                                                            #
##                                                                                                          #
##                                                                                                          #
##  Descriptions: This project is based on an idea from The Atlantic's City Lab and depends heavily on      #
##                their code and data. I have made changes to the number of clusters and descriptions of    #
##                those clusters based on Kentucky's census tracts.                                         #
##                                                                                                          #
##  CityLab Project: https://github.com/theatlantic/citylab-data/tree/master/citylab-congress               #
#############################################################################################################

# Pull KY census tracts from census
library(sf) # For visualization and geographic analysis
library(tigris) # For census data
options(tigris_class = 'sf')

ky_tract <- tracts('kentucky') # Pull census data for KY Tracts

library(tidyverse) # Duh.
library(e1071) # For modeling.

# Map courtesy of Kentucky's Legislative Research Commission.
# I've made some changes to the shapefile on the LRC website to fix the district numbers.
ky_house <- st_read('data/shapefiles/kyhouse_districts', 'house_map_shp') 
tract_demog <- read_csv('data/tract_demog.csv') # Tract demographics from City Lab

ky_tract <- st_transform(ky_tract, st_crs(ky_house)) # Make CRS uniform.

# Create a tibble of KY Census Tracts with surface area, for use in creating density calculation
tract_area <- tibble(GEOID = ky_tract$GEOID,
                     area = st_area(ky_tract)) %>% 
  mutate(area = str_remove_all(area, " m^2") %>% as.numeric() / 2.59e+6)

# Join House Districts to Census Tracts.
ky_joined <- ky_house %>% 
  st_join(ky_tract)

# Create tibble that has each KY House Seat with the classified density of all of the census tracts within the district.
ky_demog <- tibble(
  DISTRICT = ky_joined$DISTRICT,
  GEOID = ky_joined$GEOID
) %>% 
  left_join(tract_demog, by = 'GEOID') %>% 
  left_join(tract_area, by = 'GEOID') %>% 
  mutate(density = households/area,
         type = case_when(
           density < 102 ~ "Very low density",
           density < 800 ~ "Low density",
           density < 2213 ~ "Medium density",
           density >= 2213 ~ "High density",
           TRUE ~ "NA"))

# Summarization of each KY House Seat.  This code is taken almost directly from City Lab.
ky_summary <- ky_demog %>% 
  # For each congressional district, sum up the total population in each type of tract
  group_by(DISTRICT, type) %>%
  summarize(pop = sum(pop, na.rm = TRUE)) %>%
  # Calculate the percentage of each congressional district's population in each type of tract
  group_by(DISTRICT) %>%
  mutate(pct = pop/sum(pop, na.rm = TRUE)) %>%
  select(-pop) %>% # Remove raw population as no longer necessary
  spread(type, pct, fill = 0) %>% # Spread the population percentage data into columns
  select(DISTRICT, `Very low density`, `Low density`, `Medium density`, `High density`) %>% 
  ungroup()

write_csv(ky_summary, 'data/district-summary.csv')

# THREE CLUSTERS was selected as most appropriate for Kentucky (See Readme)
# The algorithm used is the same as the one selected by City Lab.
cmeans3 <- cmeans(ky_summary %>% select(2:5) %>% as.matrix(), # Select just the population percentage columns
                  3, # Divide the districts into 3 clusters
                  iter.max = 1000) # Run it a ton of times, if necessary

cluster_names3 <- cmeans3$centers %>% 
  as_data_frame() %>% 
  rownames_to_column(var = "cluster_number") %>%
  arrange(`High density`) %>%
  mutate(Cluster = c("Rural", "Suburban/Small City", "Urban")) %>%
  select(cluster_number, Cluster) %>%
  arrange(cluster_number)

districts3 <- bind_cols(ky_summary, cmeans3$cluster %>% as.character() %>% 
                          as_data_frame() %>% 
                          set_names("cluster_number"),
                        # Add in columns listing how closely each district matched each cluster
                        as_data_frame(cmeans3$membership) %>% 
                          set_names(cluster_names3$Cluster) %>% # Name the columns from cluster_names
                          select("Rural", "Suburban/Small City", "Urban") # Put our columns in the correct order
) %>%
  left_join(cluster_names3, by = "cluster_number") %>%
  select(DISTRICT, Cluster, everything(), -cluster_number) %>%
  filter(!is.na(DISTRICT)) %>%
  mutate(Cluster = as.factor(Cluster) %>% fct_relevel("Rural", "Suburban/Small City", "Urban"))

# The code below is not necessary to create the output, but is a quick visualization check of the project.
# ky_house %>% left_join(districts3 %>% select(DISTRICT, Cluster)) %>%
#   ggplot(aes(fill = Cluster)) +
#   geom_sf() +
#   theme_void() +
#   labs(title = 'KY House - City Lab Project',
#        subtitle = 'Three Clusters')
# ggsave('img/three-clusters.png')

# Output to file.
write_csv(districts3, 'ky-house-citylab-clusters.csv')
