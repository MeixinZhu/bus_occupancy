###########################################################################################
# This file includes software codes to aggregate the average bus occupany rate from three
# different bus types (e.g., transit bus, school bus, and motorcoach) for 50 US states and
# the District of Columbia as well as 183 urbanized areas defined by the US Census Bureau
# with population higher than 200k
###########################################################################################

# set working directory to where this script is located
# setwd()

# load and attach required packages
library(sqldf)

########################
### data preparation ###
########################

# read state data
states <- read.csv("Data/states.csv", header=T, as.is=T)

# read urbanized area data
urban_200k <- read.csv("Data/urban_areas_200k.csv", header=T, as.is=T)
urban_200k <- merge(urban_200k, states[,c("no","statename")], by.x="STATE", by.y="no")

# read urbanize area relationship tables
urban_ZCTA <- read.csv("Data/urban_ZCTA.csv", header=T, as.is=T)
urban_cnty <- read.csv("Data/urban_county.csv", header=T, as.is=T)

# read bus count by zipcode data
bus_cnt <- read.csv("Result/bus_cnt_zip.csv", header=T, as.is=T)

# classify bus type based on the carrier type
bus_cnt$type <- "Transit"
bus_cnt$type[bus_cnt$CarrierType %in% c("PRIVATE","INDIVIDUAL","DEALER","UTILITIES/COMMUNICATIONS","VEHICLE MANUFACTURER")] <- "Motorcoach"
bus_cnt$type[bus_cnt$VehicleType=="BUS SCHOOL"] <- "School"

###################
### state level ###
###################

# count number of buses by type by state
query <- "
SELECT b.state, b.statename, type, sum(cnt) AS cnt
FROM bus_cnt AS a JOIN states AS b ON a.state=b.state
GROUP BY b.state, type
ORDER BY statename, type
"
bus_cnt_state <- sqldf(query, method="raw")

# create state level bus aggregate data frame
bus_state <- cbind(bus_cnt_state[bus_cnt_state$type=="Transit",c("state","statename","cnt")],
                   bus_cnt_state[bus_cnt_state$type=="School",c("cnt")],
                   bus_cnt_state[bus_cnt_state$type=="Motorcoach",c("cnt")])

# adjust column names
colnames(bus_state) <- c("state","statename","cnt_transit","cnt_school","cnt_motor")

# read occupancy data for different bus types
transit_state <- read.csv("Result/transit_state.csv", header=T, as.is=T)
school_state <- read.csv("Result/school_state.csv", header=T, as.is=T)
motor_state <- read.csv("Result/motor_state.csv", header=T, as.is=T)

# add occupancy information to the aggregated data frame
bus_state <- merge(bus_state, transit_state[,c("statename","occ_transit","vmt_transit")], by="statename")
bus_state <- merge(bus_state, school_state[,c("statename","occ_school","vmt_school")], by="statename")
bus_state <- merge(bus_state, motor_state[,c("statename","occ_motor","vmt_motor")], by="statename")

# calculate the overall average bus occupancy through weighted averaging across different types
bus_state$occ_bus <- with(bus_state, (cnt_transit*vmt_transit*occ_transit +
                                        cnt_school*vmt_school*occ_school +
                                        cnt_motor*vmt_motor*occ_motor)/(
                                          cnt_transit*vmt_transit +
                                            cnt_school*vmt_school +
                                            cnt_motor*vmt_motor)
)

# save results
write.csv(bus_state, "Result/bus_state.csv", row.names=F)


