-- kafka.monitor DDL
CREATE TABLE `monitor` (
  `idrt` int(11) NOT NULL AUTO_INCREMENT,
  `IP` varchar(15) NOT NULL,
  `UAID` varchar(40) NOT NULL,
  `NV` int(11) NOT NULL,
  `UV` datetime(3) NOT NULL,
  `rtreg` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`idrt`)
) ENGINE=InnoDB AUTO_INCREMENT=75 DEFAULT CHARSET=utf8mb3;