# Parsers for Sensors on ELEMENT

This repository contains example Elixir code templates for IoT devices such as sensors to be used on the [ELEMENT](https://element-iot.com) platform provided by [ZENNER IoT Solutions](https://zenner-iot.com/).

For more information on the inner workings of the parsers, please check the [ELEMENT Documentation](https://docs.element-iot.com/parsers/overview/).

## Example Parsers for common Usecases

Have a look at these parsers if you need to write your own parser.

Usecase | Parser File
------------|-------------
Template | [lib/example_template.ex](lib/example_template.ex)
Frame-Port | [lib/example_frame_port.ex](lib/example_frame_port.ex)
Variable Length | [lib/example_variable_part.ex](lib/example_variable_part.ex)
Reading profile data | [lib/example_profile_read.ex](lib/example_profile_read.ex)
Writing profile data | [lib/example_profile_write.ex](lib/example_profile_write.ex)
Parsing IEEE754 | [lib/example_ieee754.ex](lib/example_ieee754.ex)
Parsing JSON | [lib/example_json.ex](lib/example_json.ex)
Reading device location | [lib/example_device_location.ex](lib/example_device_location.ex)
Dummy data | [lib/dummy.ex](lib/dummy.ex)


## Internal Parsers

These parsers are available on request.

### Important notice

>We go to great lengths to provide our customers with the largest and most up-to-date collection of parsers for LoRaWAN devices. We would have liked to continue to make this collection publicly available. Unfortunately, our competition has completely relied on these parsers being available for free without contributing anything to this collection themselves. Since more and more of the competition's customers have put a strain on our support capacities, we cannot continue to make the parsers publicly available. We are still happy to provide our customers with all parsers on request. In addition, we have created a possibility in ELEMENT IoT to provide parsers centrally for all tenants and will thus gradually make the parsers available to all our customers via this path.

#### Translated into German

>Wir betreiben großen Aufwand um unseren Kunden die größte und aktuellste Sammlung von Parsern für LoRaWAN-Endgeräte zur Verfügung zu stellen. Wir hätten diese Sammlung gerne weiter öffentlich zur Verfügung gestellt. Leider hat sich unser Wettbewerb komplett darauf verlassen, dass diese Parser kostenfrei zur Verfügung stehen, ohne selber zu dieser Sammlung etwas beizutragen. Da vermehrt auch die Kunden des Wettbewerbs unsere Supportkapazitäten belastet haben, können wir die Parser nicht weiter öffentlich zur Verfügung stellen. Unseren Kunden geben wir weiterhin und jederzeit sehr gerne alle Parser auf Anfrage. Zusätzlich haben wir in ELEMENT IoT direkt eine Möglichkeit geschaffen, Parser zentral für alle Mandaten bereitzustellen und werden so nach und nach die Parser über diesen Weg allen unseren Kunden bereitstellen.


Last Change | Parser Name
------------|-------------
2018-12-04 | abeeway Industrial Tracker
2019-09-06 | Adeunis ARF8046
2021-05-27 | Adeunis ARF8123AA Field Test Device (FTD)
2021-02-24 | Adeunis ARF8170BA
2021-02-04 | Adeunis ARF8180 Temperature Sensors
2020-07-08 | Adeunis ARF8180
2021-06-07 | Adeunis ARF8200AA
2021-01-05 | Adeunis ARF8230AA
2019-03-20 | Adeunis ARF8230
2020-12-14 | Adeunis ARF8240
2020-10-06 | Arad MODBUS
2020-11-20 | Ascoel CO868LR / TH868LR
2019-09-06 | Ascoel CM868LRTH Door/Window sensor
2019-09-06 | Ascoel CM868LR Magnet Contact
2019-09-06 | Ascoel IT868LR Pyroelectric Motion Detector
2020-06-23 | ATIM Metering and Dry Contact DIND160/80/88/44
2021-05-04 | Axioma Qalcosonic F1 - 24h mode (orHoneywell Elster)
2021-06-29 | Axioma Qalcosonic W1 - Current and last 15 hours (Honeywell Elster)
2021-10-19 | BARANI DESIGN MeteoHelix
2021-10-20 | BARANI DESIGN MeteoWind IoT
2020-11-11 | BESA M-BUS-1
2019-01-01 | Binando Binsonic
2019-12-10 | BOSCH Parking Sensor
2019-09-19 | BOSCH Traci
2019-12-02 | Cayenne LPP Protocol
2020-12-16 | Clevabit Protocol (DEOS SAM CO2 Ampel)
2021-03-03 | Clevercity Greenbox
2019-09-06 | Comtac E1310 DALI Bridge
2019-05-15 | Comtac E1323-MS3
2021-10-14 | Comtac E1332 LPN Modbus Energy Monitoring Bridge
2019-01-01 | Comtac E1360-MS3
2019-11-12 | Comtac E1374
2021-04-15 | Comtac KLAX
2020-01-30 | Comtac KLAX Modbus
2020-01-29 | Comtac KLAX SML
2020-01-08 | Comtac LPN CM1
2020-05-12 | Comtac LPN CM4
2019-09-06 | Comtac LPN DI
2019-09-06 | Comtac LPN Modbus easy
2021-10-19 | Comtac Modbus Bridge Template
2021-08-10 | Comtac TSM (Trafo Station Monitor)
2020-04-22 | conbee HybridTag L300
2021-09-22 | de-build.net POWER Gmbh - LoRa Protocol
2020-12-23 | DECENTLAB DL-MBX-001/002/003 Ultrasonic Distance Sensor
2020-03-31 | DECENTLAB DL-PR26 Pressure Sensor
2019-07-10 | Decentlab DL-TRS12 Soil Moisture
2020-09-10 | Diehl HRLGc G3 Water Meter
2019-08-26 | Diehl OMS
2021-04-06 | DigitalMatter Oyster GPS
2021-10-13 | Dragino LAQ4 Air Quality Sensor
2020-12-02 | Dragino distance sensor
2021-10-13 | Dragino LDS01 Door Sensor
2021-08-13 | Dragino LGT-92 LoRaWAN GPS Tracker
2020-01-01 | Dragino LHT65
2021-08-25 | Dragino LLMS01 Leaf Moisture
2020-12-22 | Dragino LSE01 Soil Sensor
2021-03-17 | Dragino LSN50
2021-08-26 | Dragino LSNOK01 Soil Fertility Nutrient
2021-08-26 | Dragino LSPH01 Soil PH Sensor
2021-07-14 | Dragino LT22222-L I/O Controller
2021-10-13 | Dragino LWL01 Water Leak Sensor
2021-01-17 | DZG Node
2021-01-17 | DZG Node
2021-04-15 | DZG Loramod V2
2019-09-06 | DZG loramod
2021-08-09 | Eastron SDM630MCT Electricity Meter
2021-06-14 | EasyMeter ESYS LR10 LoRaWAN adapter
2020-02-03 | eBZ electricity meter
2020-05-27 | eBZ electricity meter v2
2020-12-15 | Elsys Multiparser
2019-06-05 | Elvaco CMa11L indoor sensor
2021-08-04 | Elvaco CMi4110 Mbus
2021-07-22 | Fleximodo GOSPACE Parking
2019-01-01 | Fludia FM430
2020-01-27 | Globalsat ls11xp indoor climate monitor
2019-09-19 | GlobalSat GPS Tracker
2019-09-06 | Gupsy temperature and humidity sensor
2021-08-17 | GWF LoRaWAN module for GWF metering units
2021-04-08 | Holley E-Meter
2021-10-12 | Imbuildings People Counter
2020-11-30 | Innotas LoRa Pulse
2020-11-25 | Innotas LoRa EHKV
2020-11-25 | Innotas LoRa Water Meter
2021-10-15 | Integra Calec ST 3 Meter
2021-07-14 | Integra Topas Sonic Water Meter
2021-09-30 | InterAct - IOT Controller
2021-01-11 | Itron Cyble5
2021-07-30 | Keller
2020-12-16 | Kerlink Wanesy Wave
2021-01-22 | Lancier Pipesense
2021-02-09 | Libelium Smart Devices All in One
2019-09-06 | Libelium Smart Agriculture
2019-09-06 | Libelium Smart Cities
2019-09-06 | Libelium Smart Environment
2019-11-29 | Libelium Smart Parking
2019-09-06 | Libelium Smart Water
2019-01-26 | Libelium Smart Agriculture Pro
2021-01-28 | Libelium Smart City Pro
2021-01-26 | Libelium Smart Water Xtreme
2020-01-23 | Lobaro Environmental Sensor
2020-12-04 | Lobaro GPS Tracker
2021-09-23 | Lobaro Modbus Bridge v1.0
2018-01-01 | Lobaro Oscar smart waste ultrasonic sensor
2019-10-04 | Lobaro Oskar v2
2019-11-21 | Lobaro Pressure Sensor 26D
2021-01-22 | Lobaro WMBus Bridge
2019-03-07 | LPP Cayenne
2021-09-27 | MCF88 Multiparser
2021-08-27 | MClimate Vicky
2021-02-01 | Milesight and Ursalink EM300
2021-01-28 | Milesight and Ursalink UC11xx
2021-10-20 | MIROMICO FMLR IoT Button
2021-07-01 | Mutelcor MTC-PB01 / MTC-CO2-01 / MTC-XX-MH01 / MTC-XX-CF01
2019-12-09 | NAS ACM CM3010
2019-01-01 | NAS CM3020
2019-08-26 | NAS CM3030 Cyble Module
2019-08-26 | NAS CM3060 BK-G Pulse Reader
2020-04-17 | NAS PULSER BK-G CM3061
2021-07-26 | NAS Luminaire v0.6
2021-08-02 | NAS Luminaire v1.0
2020-09-28 | NAS UM30x3 Pulse+Analog Reader
2020-10-06 | NetOp Multiparser
2021-06-16 | Netvox Multiparser
2020-05-04 | Nexelec D678C Insafe+ Carbon, Temperature and Humidity
2021-06-16 | NKE Watteco - Eolane Bob Assistant
2020-10-15 | NKE Watteco Clos'O
2019-05-09 | NKE Watteco IN'O
2021-02-11 | NKE Watteco Intens'O
2019-11-18 | NKE Watteco Remote Temp
2020-11-23 | NKE Watteco Pulse Sens'O
2021-05-12 | NKE Watteco Smart Plug
2021-09-07 | Parametric PCR2 People Counter Radar
2021-09-22 | Parametric TCR Radar Traffic Counter
2020-03-26 | PaulWegener Datenlogger
2021-02-08 | PaulWegener Datenlogger
2021-10-14 | Pepperl+Fuchs WILSEN.sonic.level
2021-08-23 | PNI PlacePod parking sensor
2019-05-09 | RAK Button
2020-03-17 | RFI Remote Power Switch
2019-09-06 | Sagemcom Siconia
2021-08-03 | SEBA SlimCom IoT-LR for Dipper Datensammler
2021-04-19 | SenseCAP
2020-07-02 | Sensative Strips Comfort
2021-09-24 | Sensingslabs Multisensor
2019-09-06 | Sensinglabs SenLab LED
2021-09-23 | Sensoco Loomair
2019-10-16 | SensoNeo Quatro Sensor
2020-12-10 | SensoNeo Single Sensor
2020-11-17 | Sentinum APOLLON-Q
2021-04-30 | Sentinum FEBRIS
2021-08-11 | Skysense SKYAGR1
2021-07-15 | SLOC Multiparser
2020-11-26 | Smilio Action v2
2021-01-19 | SoilNet LoRa (Jülich Forschungszentrum)
2020-06-26 | Sontex Supercal/Superstatic
2021-01-26 | Speedfreak_v4
2021-07-12 | Strega Smart Valve
2021-07-07 | Swisscom LPN Multisense
2019-03-28 | Swisslogix/YMATRON SLX-1307
2019-06-25 | Tecyard Multiparser
2019-06-04 | Tecyard RattenSchockSender
2021-05-18 | Tekelek 766 RF
2021-03-17 | TEKTELIC Agriculture
2020-06-16 | Tektelic Industrial GPS Asset Tracker
2019-10-15 | Tektelic Kona home sensor
2021-03-11 | TENEO CO2 Ampel
2021-05-10 | Terabee Level Monitoring XL
2020-10-29 | Tetraedre
2021-08-24 | TrackNet Tabs
2021-10-08 | UIT-GmbH WR-iot-compact water level sensor
2020-12-10 | Ursalink AM100/102 and Milesight AM104/AM107
2020-04-27 | Ursalink UC11-T1 Temperature
2021-03-01 | VEGAPULS Air 41
2019-05-08 | Xignal Mouse/Rat Trap
2020-07-23 | Xter Connect people counter
2019-09-06 | yabby GPS tracker
2021-04-22 | Yokogawa Sushi Sensor
2021-08-25 | ZENNER Smoke Detector D1722
2020-02-27 | ZENNER T&H Sensor D1801
2019-07-05 | ZENNER Water Meter
2019-04-04 | ZENNER IoT Oskar v2 smart waste ultrasonic sensor
2019-05-09 | ZIS Oskar 1.0
2019-09-06 | ZIS DigitalInputSurveillance 8
2021-07-15 | ZRI Simple EDC and PDC
2021-08-19 | ZENNER Water Meters
2021-10-07 | ZENNER Multiparser (EDC, EHKV, PDC and WMZ)
