## Analyzing the appropriate number of clusters

library(sf)
library(tidyverse)
library(e1071)

ky_house <- st_read('data/shapefiles/kyhouse_districts', 'house_map_shp') # From LRC
ky_summary <- read_csv('data/district-summary.csv') %>% mutate(DISTRICT = factor(DISTRICT)) # see create-cluster.R

# The `cmeans` code comes from City Lab.
# I selected three clusters, but this is the code to create the images for 4, 5, and 6 clusters.

### SIX CLUSTERS - CITY LAB GROUPINGS
cmeans6 <- cmeans(ky_summary %>% select(2:5) %>% as.matrix(), # Select just the population percentage columns
                  6, # Divide the districts into six clusters
                  iter.max = 1000) # Run it a ton of times, if necessary

cluster_names <- cmeans6$centers %>% 
  as_data_frame() %>% 
  rownames_to_column(var = "cluster_number") %>%
  arrange(`High density`) %>%
  mutate(Cluster = c("Pure rural", "Rural-suburban mix", "Sparse suburban", "Dense suburban", "Urban-suburban mix", "Pure urban")) %>%
  select(cluster_number, Cluster) %>%
  arrange(cluster_number)

districts6 <- bind_cols(ky_summary, cmeans6$cluster %>% as.character() %>% 
                          as_data_frame() %>% 
                          set_names("cluster_number"),
                        # Add in columns listing how closely each district matched each cluster
                        as_data_frame(cmeans6$membership) %>% 
                          set_names(cluster_names$Cluster) %>% # Name the columns from cluster_names
                          select("Pure rural", "Rural-suburban mix", "Sparse suburban", "Dense suburban", "Urban-suburban mix", "Pure urban") # Put our columns in the correct order
) %>%
  left_join(cluster_names, by = "cluster_number") %>%
  select(DISTRICT, Cluster, everything(), -cluster_number) %>%
  filter(!is.na(DISTRICT)) %>%
  mutate(Cluster = as.factor(Cluster) %>% fct_relevel("Pure rural", "Rural-suburban mix", "Sparse suburban", "Dense suburban", "Urban-suburban mix", "Pure urban"))

ky_house %>% left_join(districts6 %>% select(DISTRICT, Cluster)) %>% 
  ggplot(aes(fill = factor(Cluster))) +
  geom_sf() +
  theme_void() +
  labs(title = 'KY House - City Lab Project',
       subtitle = 'Six Clusters')

ggsave('img/six-clusters.png')

### FOUR CLUSTERS
cmeans4 <- cmeans(ky_summary %>% select(2:5) %>% as.matrix(), # Select just the population percentage columns
                  4, # Divide the districts into 4 clusters
                  iter.max = 1000) # Run it a ton of times, if necessary

cluster_names4 <- cmeans4$centers %>% 
  as_data_frame() %>% 
  rownames_to_column(var = "cluster_number") %>%
  arrange(`High density`) %>%
  arrange(cluster_number)

districts4 <- bind_cols(ky_summary, cmeans4$cluster %>% as.character() %>% 
                          as_data_frame() %>% 
                          set_names("cluster_number"),
                        # Add in columns listing how closely each district matched each cluster
                        as_data_frame(cmeans4$membership) 
)

ky_house %>% left_join(districts4 %>% select(DISTRICT, cluster_number)) %>% 
  ggplot(aes(fill = cluster_number)) +
  geom_sf() +
  theme_void() +
  labs(title = 'KY House - City Lab Project',
       subtitle = 'Four Clusters')

ggsave('img/four-clusters.png')


### FIVE CLUSTERS
cmeans5 <- cmeans(ky_summary %>% select(2:5) %>% as.matrix(), # Select just the population percentage columns
                  5, # Divide the districts into 5 clusters
                  iter.max = 1000) # Run it a ton of times, if necessary

cluster_names5 <- cmeans5$centers %>% 
  as_data_frame() %>% 
  rownames_to_column(var = "cluster_number") %>%
  arrange(`High density`) %>%
  arrange(cluster_number)

districts5 <- bind_cols(ky_summary, cmeans5$cluster %>% as.character() %>% 
                          as_data_frame() %>% 
                          set_names("cluster_number"),
                        # Add in columns listing how closely each district matched each cluster
                        as_data_frame(cmeans5$membership) 
)

ky_house %>% left_join(districts5 %>% select(DISTRICT, cluster_number)) %>% 
  ggplot(aes(fill = cluster_number)) +
  geom_sf() +
  theme_void() +
  labs(title = 'KY House - City Lab Project',
       subtitle = 'Five Clusters')

ggsave('img/five-clusters.png')
