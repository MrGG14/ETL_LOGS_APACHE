CREATE TABLE `geoip` (
  `ip` varchar(15) NOT NULL,
  `nomorg` varchar(100) DEFAULT NULL,
  `numorg` varchar(20) DEFAULT NULL,
  `postal_code` varchar(20) DEFAULT NULL,
  `city_name` varchar(50) DEFAULT NULL,
  `country_name` varchar(50) DEFAULT NULL,
  `country_iso_code` varchar(20) DEFAULT NULL,
  `region_name` varchar(100) DEFAULT NULL,
  `region_iso_code` varchar(20) DEFAULT NULL,
  `continent_code` varchar(20) DEFAULT NULL,
  `timezone` varchar(50) DEFAULT NULL,
  `lon` double DEFAULT NULL,
  `lat` double DEFAULT NULL,
  `ipc` int(11) DEFAULT NULL,
  `fechreg` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`ip`)
) ENGINE=InnoDB;