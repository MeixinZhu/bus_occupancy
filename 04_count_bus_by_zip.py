################################################################################
# This file includes software codes to count the number of buses by carrier type
# in each zip code tabulation area
################################################################################

# import required packages
import pandas as pd
import pandasql as ps

# read Polk Vehicle Registration data
veh_reg = pd.read_sas("Data/trucks.sas7bdat")

# decode data items
veh_reg.VehicleType = veh_reg.VehicleType.str.decode("utf-8")

# select all buses (exclude trucks)
veh_reg_bus = veh_reg.loc[veh_reg.VehicleType.isin(["BUS SCHOOL","BUS NON SCHOOL"])]

# decode data items
veh_reg_bus.CarrierType = veh_reg_bus.CarrierType.str.decode("utf-8")
veh_reg_bus.State = veh_reg_bus.State.str.decode("utf-8")
veh_reg_bus.Zip = veh_reg_bus.Zip.str.decode("utf-8")

# count number of buses by carrier type by zip code
query = """
SELECT state, zip, carriertype, vehicletype, COUNT(*) AS cnt
  FROM veh_reg_bus
 GROUP BY state, zip, carriertype, vehicletype
"""
bus_cnt_zip = ps.sqldf(query, env=locals())

# save results
bus_cnt_zip.to_csv("Result/bus_cnt_zip.csv", index=False)
