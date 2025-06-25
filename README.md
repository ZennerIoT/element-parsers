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

<!--START_PARSER_TABLE-->
### abeeway Industrial Tracker

* 2022-04-13: fixed position_scan(), cleanup
* 2022-03-17: Added collection_scan() support
* 2022-03-04: Added support for more devices and updated for Firmware 2.2 according to "Abeeway_Trackers_Reference_Guide_FW2.2_V1.7.pdf"
* 2018-12-04: Initial Parser for Firmware 1.7 according to "Abeeway Industrial Tracker_Reference_Guide_FW1.7.pdf"

### abeeway Industrial Tracker

* 2018-12-04: Initial Parser for Firmware 1.7 according to "Abeeway Industrial Tracker_Reference_Guide_FW1.7.pdf"

### Acrios Systems LoRaWAN to MBus Bridge

* 2025-06-10: Added direct forwarding, when complete MBus message is sent
* 2024-07-18: Initial version

### Adeunis ARF8046

* 2019-09-06: Added parsing catchall for unknown payloads.

### Adeunis ARF8123AA Field Test Device (FTD)

* 2021-12-10: Added gw_snr in readings
* 2021-05-27: Formatted code. Added example payload from v2 firmware.
* 2019-09-06: Added parsing catchall for unknown payloads.
* 2018-09-20: Completed fields definition; Added field "gps_reception_scale_name".
* 2018-09-03: Added fields for export functionality

### Adeunis ARF8170BA

* 2021-02-24: Fixed values of channel*_state*.
* 2020-12-07: Parser REWRITE, renamed fields. Supporting ARF8170BA-B02.
* 2019-09-06: Added parsing catchall for unknown payloads.

### Adeunis ARF8170BA (v2)

* 2022-11-03: Now supports V2 of ARF8170BA
* 2021-02-24: Fixed values of channel*_state*.
* 2020-12-07: Parser REWRITE, renamed fields. Supporting ARF8170BA-B02.
* 2019-09-06: Added parsing catchall for unknown payloads.

### Adeunis ARF8180 Temperature Sensors

* 2023-07-04: Added config() with option use_timestamp_from_device: false.
* 2022-12-15: Added data.transceived_at to find device time problems. Added field definitions.
* 2021-02-04: Supporting payloads with timestamp.
* 2021-02-02: Support for v4 payloads.
* 2020-08-27: Added alerts for v3 payloads.
* 2020-08-26: Support for v3 payloads.
* 2019-09-06: Added parsing catchall for unknown payloads.

### Adeunis ARF8180

* 2020-07-08: Taking initial internal implementation according to document "TEMP_V3_Technical_Reference_Manual_APP_2.0_07-2019", fixing syntaxerror, adding tests and adding fields

### Adeunis ARF8200AA Analog PWR

* 2021-12-27: Updated parser to "User_Guide_ANALOG_PWR_LoRaWAN_EU863-870_V2.0.2.pdf".
* 2021-06-07: Added do_extend_reading/2 callback. Added tests and formatted code.
* 2019-09-06: Added parsing catchall for unknown payloads.

### Adeunis ARF8230AA Pulse

* 2023-03-10: Implemented missing payloads. Added tests from 'PULSE_V4-Technical_Reference_Manual_APP_2.1-22.02.2021-1.pdf'.
* 2021-10-29: Rewrite of parser supporting all flags and newest payload version.
* 2021-01-05: Added support for App Version 2.0 with prepended timestamp.
* 2020-11-24: Added extend_reading with start and impulse extension from profile.
* 2019-09-06: Added parsing catchall for unknown payloads.

### Adeunis ARF8240

* 2021-11-30: Updated parser according to real device values.
* 2020-12-14: Initial implementation according to "MODBUS_LoRaWAN_868_V2.0.0..pdf".

### Adeunis ARF8275A

* 2023-03-07: Added basic support for co2 readings
* 2022-11-24: Split multipayloads in multiple readings
* 2022-11-17: Updated according to documentation

### Arad MODBUS

* 2020-10-06: Refactored and added tests.
* 2019-03-14: Initial implementation.

### ARBOR smart city

* 2022-03-09: Removed Steinhart-Hart and Temperature calculations. Added ARBOR Webservice Integration.
* 2022-02-21: Initial implementation according to "Integrations_Guide_ARBOR-smart-City.pdf Stand:27.04.2021"

### Ascoel CO868LR / TH868LR

* 2020-11-20: Initial implementation according to "FC0000-3-15-CO_TH__LoRa-00-DO-2.0.pdf"

### Ascoel CM868LRTH Door/Window sensor

* 2019-09-06: Added parsing catchall for unknown payloads.

### Ascoel CM868LR Magnet Contact

* 2019-09-06: Added parsing catchall for unknown payloads.

### Ascoel IT868LR Pyroelectric Motion Detector

* 2019-09-06: Added parsing catchall for unknown payloads.

### Ascoel PB868LRH PushButton

* 2022-02-15: Cleanup + fixes
* 2022-02-03: Added support for hardware_revision
* 2022-02-02: Initial implementation according to "PB868LRH and PB868LRI Push button sensors programming manual.pdf"

### Atim Cloud Wireless Sensor

* 2023-09-29: Initial implementation according to "https://www.atim.com/wp-content/uploads/documentation/ACW/ACW-THAQ/ENGLISH/ATIM_ACW-THAQ_UG_EN.pdf"

### ATIM Metering and Dry Contact DIND160/80/88/44

* 2020-06-23: Added feature :append_last_digital_inputs default: false
* 2020-06-18: Initial implementation according to "ATIM_ACW-DIND160-80-88-44_UG_EN_V1.7.pdf"

### AVK SMART WATER VIDI DEVICES

* 2025-06-20: Initial implementation according to "Technical Description_LoRaWAN setup Rev 03_PATOJE.pdf"

### Axioma Qalcosonic E3/E4

* 2024-07-15: Changed AES decryption profile to a generalized name
* 2024-01-31: Added AES decryption with key from profile from_ttn.aes_key
* 2023-07-13: Initial implementation according to "LRa functional description for E3_E4_V01_20221108.pdf"

### Axioma Qalcosonic F1 - 24h mode (or Honeywell Elster)

* 2023-08-31: Added AES decryption with key from profile qualcosonic.aes_key
* 2021-05-04: Initial implementation according to "Axioma Lora Payload F1 V1.8 Enhanced.pdf"

### Axioma Qalcosonic W1 - Current and last 15 hours (Honeywell Elster)

* 2022-05-13: Added do_extend_reading/2 callback.
* 2022-01-20: Keeping most of reading to support debugging when unix_difference_seconds check fails.
* 2021-06-29: Added config key device_timezone_utc_offset. Device timestamp expected to be UTC+1.
* 2021-05-05: Added AES decryption with key from profile qualcosonic.aes_key
* 2021-05-04: Changed unix_difference_seconds to default false, disabling time check.
* 2021-05-03: Added configuration options, skipped logged values, checking device timestamp delta.
* 2020-02-04: Initial implementation according to "Axioma Lora Payload W1 V01.7 Extended.pdf"

### BARANI DESIGN MeteoHelix

* 2021-10-20: added sensor error or sensor n/a
* 2021-10-19: Initial implementation according to "https://www.baranidesign.com/meteohelix-message-decoder"

### BARANI DESIGN MeteoRain IoT

* 2023-02-01: Initial implementation according to "https://www.baranidesign.com/meteorain-open-message-format"

### BARANI DESIGN MeteoWind IoT

* 2021-10-20: added sensor error or sensor n/a
* 2021-10-19: Initial implementation according to "https://www.baranidesign.com/iot-wind-open-message-format"

### BESA M-BUS-1

* 2020-11-11: Initial implementation according to "01-M-BUS-1 UM_rev 12.pdf"

### Binando Binsonic

* 2019-01-01: Initial implementation.

### Bitgear IO-Guard

* 2024-09-16: Increades readability and fixed port 22 Payloads
* 2024-02-14: Initial implementation according to "IO-Guard Device uplink messages.pdf"

### BOSCH Parking Sensor

* 2019-12-10: Fixed mapping in reset_cause/1
* 2019-09-06: Added parsing catchall for unknown payloads.
* 2019-04-30: change order of bytes in startup message, according to FW v0.23.3
* 2019-02-19: Added fields
* 2018-11-12: Interface v2 implemented
* 2018-10-09: Interface v1 implemented

### BOSCH Traci

* 2019-09-19: Ignoring locations where GPS lat=0 and lon=0.
* 2019-06-05: Initial implementation according to "Traci-FramepayloadProtocol_V1.5.pdf"

### WEP 5

* 2023-12-05: Initial implementation according to "WEP5.pdf"

### Browan Tabs TBSL100 Sound Level

* 2023-03-03: Initial implementation according to "Tabs TBSL100 Sound Level Sensor User Manual (EN).pdf".

### Cayenne LPP Protocol

* 2019-12-02: Initial implementation.

### Clevabit Protocol (DEOS SAM CO2 Ampel)

* 2023-03-13: Added Dew-Temperature calculation and extend_reading callback.
* 2020-12-16: Initial implementation according to payload version 1.0

###  Clever City Greenbox v2

* 2024-12-09: Updated name and documentation
* 2024-12-05: Initial implementation according to documentation "GreenBox Bedienungsanleitung, de, V2.44.pdf"

### Clevercity Greenbox

* 2023-12-27: Fixed calculation of k1_running_since/k2 using data.timestamp.
* 2022-11-21: Using data.timestamp (if available) for config.interpolate_times, to avoid late sending problems.
* 2022-11-01: Fixed interpolation problem with summer-winter timezone switch. Added reparsing_strategy=sequential
* 2021-03-03: Fixing interpolated times missing and duplicate off markings.
* 2021-02-10: Fixing interpolated times limited to today and yesterday.
* 2021-01-22: Limited interpolation to last 24h. Ignoring payload "" on port 0.
* 2020-11-19: Added interpolated fields k1_switch=on/off and k2_switch=on/off for switch detection.
* 2020-10-01: Fixed 0x00 message for 0.71 docs.
* 2020-04-27: Added option to interpolate on/off times.
* 2019-06-24: GPS minutes are now divided by 60 and then multiplied by 100.
* 2019-06-20: Added GPS position in reading metadata. Fixed invalid GPS values. Fixed city/country names.
* 2018-01-06: Initial implementation according to PDF.

### Comtac Cluey XX LR

* 2025-05-07: Refactor of certain parse_parameter_value functions.
* 2025-04-29: Initial implementation according to Cluey_XX_LR_Payload-Beschreibung[DE_V02.04].pdf.

### Comtac E1310 DALI Bridge

* 2019-09-06: Added parsing catchall for unknown payloads.

### Comtac E1323-MS3

* 2019-05-15: Initial version

### Comtac E1332 LPN Modbus Energy Monitoring Bridge

* 2022-11-09: Changed one_datapoint_per_reading to default: false, added fields.
* 2022-06-08: Added datatype "ignore" for skipping a datapoint
* 2021-10-25: Added config option one_datapoint_per_reading: true
* 2021-10-14: Fixed typo in float/float_little casting part.
* 2021-08-05: Initial version according to "E1332-LoRa_ModbusEnergyMonitoring_Bridge_V0.01.pdf"

### Comtac E1360-MS3

* 2019-01-01: Initial implementation.

### Comtac E1374

* 2022-01-13: Added missing preload().
* 2019-11-12: Initial implementation according to "E1374 LPN Tracker SW Specs V00"

### Comtac E1395 CM-3 Temperature Sensor

* 2022-01-24: Initial version according to "E1395-CM-3_EN_V00.02_V05.pdf"

### Comtac JSON Parser

* 2025-03-11: Initial implementation

### Comtac KLAX v1

* 2023-03-08: Added try catch. Added zaehlernummer calculation. Added reparsing_strategy()
* 2023-03-03: Added warning when using with app_version >= 1.0.
* 2023-02-24: Updated fields() definition, updated tests.
* 2021-04-15: Using new config() function.
* 2019-12-11: Added field obis_value in all readings for MSCONS rule compatability.
* 2019-10-30: Field server_id is now integer. Added hex string value server_id_hex.
* 2019-07-23: Skipping negative values by default.
* 2019-07-15: Fixing interpolation for changes between measurements in a packet.
* 2019-05-14: Rounding all values as float to a precision of 3 decimals.
* 2019-05-13: Added interpolation feature. Added registers with full OBIS codes.
* 2019-03-27: Logging unknown binaries in _parse_payload/2.
* 2019-03-05: Register values now signed. Added fields().
* 2019-03-04: Skipping invalid backdated values when value==0.0; Added mode "Logarex"
* 2019-02-13: Initial Version by Niklas, registers and interval fixed.

### Comtac KLAX v2 Modbus

* 2023-03-03: Added warning when using with app_version < 1.0.
* 2020-01-30: Initial Version.

### Comtac KLAX v2 SML

* 2023-03-09: Added profile field and handling of converter_factor. Added data.zaehlernummer from server_id.
* 2023-03-03: Added warning when using with app_version < 1.0.
* 2022-12-01: Added do_extend_reading callback.
* 2022-03-28: Not adding obis values when unit="NDEF".
* 2020-01-13: Let parser write interval and registers from packets of port 100 and 104 into profile
* 2020-01-07: Added support for element profile parameters
* 2020-01-29: Initial Version. Partly used old 0.2-0.4 Parser

### Comtac LPN CM1

* 2020-01-08: Added Taupunkttemperatur calculation.
* 2019-09-06: Added parsing catchall for unknown payloads.

### Comtac LPN CM4

* 2020-05-12: Fixed single temperature value.
* 2020-02-28: Added "Taupunkt" calculation.
* 2020-02-24: Initial implementation according to E1446-CM-4_EN_V00.pdf

### Comtac LPN DI

* 2019-09-06: Added parsing catchall for unknown payloads.

### Comtac LPN DO

* 2024-04-10: Initial implementation according to E1347-LPN_DO_EN_V0.10.pdf

### Comtac LPN Modbus easy

* 2019-09-06: Added parsing catchall for unknown payloads.
* 2018-07-18: First implementation.

### Comtac Cluey LPN KM

* 2023-03-01: Added data.single_point_Y_input1 and data.single_point_Y_input2.
* 2023-02-09: Initial implementation according to "KM-KurzschlussMonitor-Bedienungsanleitung-DE-V0.1.4.pdf".

### Comtac Modbus Bridge Template

* 2025-05-08: Added Port 5 for Modbusbridge EM, corrected reg to dp as key and profile names
* 2023-01-11: Added type "binary_bypass". Forwards the binary value directly. To be able to split the values later on in mapping function
* 2022-02-03: Added type "signed16_custom_invert". Interprets incoming bytes (1,2,3,4) as (3,4,1,2) signed.
* 2021-10-28: Added profile support. Use profile: comtac_modbus_bridge_params, with fields dp1, dp2, dp3. If no valid type found, defaulttype is used
* 2021-10-19: Added type "float32_custom_invert". Interprets incoming bytes (1,2,3,4) as (3,4,1,2) float.
* 2021-07-12: Added type "binary"
* 2021-06-15: Added Port 100 again correctly, DPext0 and DPext1 possible
* 2021-06-14: New version. Only type of each register has to be defined (signed, signed_little, unsigned, unsigned_little, float, float_little). Added Errors

### Comtac TSM (Trafo Station Monitor)

* 2021-08-10: Fixed for real payload from device.
* 2021-05-14: Initial Version, according to "E1398 Payloadbeschreibung TSM V01.pdf".

### conbee HybridTag L300

* 2020-04-22: Added calculated ullage in % from configurable profile
* 2020-01-08: Added fields for Indoor Localization
* 2019-12-27: Added field "Proximity in %"
* 2019-09-06: Added parsing catchall for unknown payloads.
* 2019-03-20: Fixed "Humidity Sensor" for real payload.
* 2018-08-23: Initial version implemented using HybridTAG-L300-Infosheet_06-18-2.pdf

### SonoMeter40

* 2024-07-10: Initial implementation according to "SonoMeter40-LoRa_Payload_Nordic_Heating.pdf"

### de-build.net POWER Gmbh - LoRa Protocol

* 2021-09-22: Added units from profile.
* 2021-03-18: Updated format for port 1 and 2 with splitter symbol. Supporting min/max without channel chars.
* 2021-03-02: Initial implementation according to "Lora Protokoll v1.0.pdf" (14.01.2021)

### DECENTLAB DL-MBX-001/002/003 Ultrasonic Distance Sensor

* 2023-02-01: Fixed bug, returning nothing instead of nil for distance when measurement is invalid
* 2022-04-20: Filter invalid measurements
* 2020-12-23: Initial implementation

### DECENTLAB DL-PR26 Pressure Sensor

* 2020-03-31: Allowing all device_ids now
* 2019-01-07: Initial implementation for 359=KELLER_I2C_PRESSURE_SENSOR

### DL-PR36

* 2023-10-10: Initial implementation according to "https://cdn.decentlab.com/download/datasheets/Decentlab-DL-PR36-datasheet.pdf"

###   DECENTLAB DL-SHT35 Air, Remperature and Humidity Sensor

* 2024-09-30: Initial implementation according to "Decentlab-DL-SHT35-datasheet.pdf"

### Decentlab DL-TRS12 Soil Moisture

* 2019-07-10: Initial version. Code cleanup. Tests.

### DEOS Teo

* 2022-09-05: Increased readability
* 2022-09-01: Initial implementation according to "Datasheet DEOS TEO_de.pdf"

### Diehl HRLGc G3 Water Meter

* 2024-01-15: Fixed DS51_A Payload
* 2021-12-13: Added manufacturer error flag flow_persistence_3
* 2020-09-10: Reformatted. Added extend_reading and first tests. Fixed utc_now usage.

### Diehl OMS

* 2019-08-26: Formatted code.
* 2019-03-14: Initial implementation

### Diehl Hydrus 2.0 LoRaWAN

* 2025-05-02: Added error codes according to 20241001_HYDRUS_2.0_Fehlerbeschreibungen.pdf
* 2024-05-30: Fixed bug in parser using a too long oms tpl
* 2024-05-28: Added test, removed comments
* 2024-05-27: Initial implementation

### DigitalMatter G62 LoRaWAN

* 2024-06-14: Initial implementation according to "1693355424527-G62+LoRaWAN+Integration+1.3.pdf".

### DigitalMatter Oyster GPS

* 2022-06-21: Updated according to "Oyster 3 LoRaWAN Integration 1.2.pdf".
* 2021-04-06: Fixed not whitelisted function call.
* 2021-02-09: Initial implementation according to "Oyster LoRaWAN Integration 1.8.pdf".

### DNIL LHI110 LORA HAN INTERFACE

* 2023-10-19: Corrected voltage, power and current calculcations"
* 2023-10-13: Initial implementation according to "LHi110 Manual 1.0 2023-09-28.pdf"

### dnt Innovations LoRaWAN Asset Tracker Solar

* 2024-09-12: Initial implementation according to "https://www.dnt.de/media/73/84/28/1674658420/dnt-LW-ATS-web_230119.pdf"

### Dräger x-Node

* 2022-08-09: Initial implementation according to "Payload Decoder_Basic_Travekom.pdf"

### Dragino AQS01-L

* 2024-09-12: Initial implementation according to "http://wiki.dragino.com/xwiki/bin/view/Main/User%20Manual%20for%20LoRaWAN%20End%20Nodes/AQS01-L_LoRaWAN_Indoor_CO2_Sensor_User_Manual/#H2.3200BUplinkPayload"

### Dragino CPL01

* 2024-04-12: Initial implementation according to "http://wiki.dragino.com/xwiki/bin/view/Main/User%20Manual%20for%20LoRaWAN%20End%20Nodes/CPL01%20LoRaWAN%20Outdoor%20PulseContact%20%20Sensor%20Manual/#H2.3UplinkPayload"

### Dragino CPL03

* 2024-07-17: Initial implementation according to "http://wiki.dragino.com/xwiki/bin/view/Main/User%20Manual%20for%20LoRaWAN%20End%20Nodes/CPL03-LB_LoRaWAN_Outdoor_PulseContact%20_Sensor_User_Manual/#H2.3.3CPL01:Real-TimeOpen2FCloseStatus2CUplinkFPORT3D2"

### Dragino D2x-LB/LS

* 2024-05-16: Fixed mod calculation according to ttn parser
* 2024-04-24: Fixed alarm detection
* 2024-04-04: Initial implementation according to "http://wiki.dragino.com/xwiki/bin/view/Main/User%20Manual%20for%20LoRaWAN%20End%20Nodes/D20-LBD22-LBD23-LB_LoRaWAN_Temperature_Sensor_User_Manual/#HAlarmFlag26MOD26LevelofPA8:"

### Dragino LAQ4 Air Quality Sensor

* 2021-10-13: fixed frame port
* 2021-10-12: Initial implementation according to "LAQ4_LoRaWAN_Air_Quality_Manual_v1.1.pdff"

### Dragino LDDS Distance sensor

* 2023-02-09: Should be compatible with LDDS45 according to manufacturer.
* 2020-12-02: Initial implementation according to Dragino - LoRaWAN_LDDS75_User Manual_v1.1

### Dragino LDS01 Door Sensor

* 2021-10-13: fixed frame port and tests + added support for versions 1.3 and lower
* 2021-10-12: Initial implementation according to "LDS01_LoRaWAN_Door_Sensor_UserManual_v1.4.0.pdf"

### LDS03A - Outdoor LoRaWAN Open/Close Door Sensor

* 2023-08-30: Addedd support for FPORT 4, 2, 3.
* 2023-08-25: Initial implementation according to Dragino wiki page: wiki.dragino.com

### Dragino LGT-92 LoRaWAN GPS Tracker

* 2022-06-29: Added config option gps_keep_invalid=false.
* 2021-08-13: Rewrite and updated to latest firmware v1.6.
* 2020-02-12: Initial implementation according to Dragino TTN Parser.

### Dragino LHT52 LoRaWAN Temperature Sensor

* 2025-06-19: Initial implementation according to https://wiki.dragino.com/xwiki/bin/view/Main/User%20Manual%20for%20LoRaWAN%20End%20Nodes/LHT52%20-%20LoRaWAN%20Temperature%20%26%20Humidity%20Sensor%20User%20Manual/#H2.4A0UplinkPayload"

### Dragino LHT65

* 2022-11-09: Added support for "Ext=9, E3 sensor with Unix Timestamp"
* 2020-01-01: Added to version control.

### Dragino LHT65N

* 2025-03-14: Added Ext=0x0E (should have been 0x0A according to documentation)
* 2024-08-15: Added Ext=6, 11, 4, 8
* 2024-05-07: Added field for temperature_temp117
* 2023-07-04: Added Ext=2
* 2023-03-27: Fixed formatting
* 2023-03-23: Initial implementation (Ext=1) according to "http://wiki.dragino.com/xwiki/bin/view/Main/User%20Manual%20for%20LoRaWAN%20End%20Nodes/LHT65N%20LoRaWAN%20Temperature%20%26%20Humidity%20Sensor%20Manual/#H2.4UplinkPayloadA0A028Fport3D229"

### LLDS40-LoRaWAN LiDAR ToF Distance Sensor

* 2024-08-07: Initial implementation according to "http://wiki.dragino.com/xwiki/bin/view/Main/User%20Manual%20for%20LoRaWAN%20End%20Nodes/LLDS40-LoRaWAN%20LiDAR%20ToF%20Distance%20Sensor%20User%20Manual/#H3.A0LiDARToFMeasurement"

### Dragino LLMS01 Leaf Moisture

* 2021-08-25: Initial Implementation according to "LoRaWAN_Leaf_Moisture_Sensor_UserManual_v1.0.pdf"

### LMDS120 - LoRaWAN Microwave Radar Distance

* 2024-07-10: Initial implementation according to "http://wiki.dragino.com/xwiki/bin/view/Main/User%20Manual%20for%20LoRaWAN%20End%20Nodes/LMDS120%20-%20LoRaWAN%20Microwave%20Radar%20Distance%20%20Sensor%20User%20Manual/"

### LMDS200 - LoRaWAN Microwave Radar Distance

* 2024-08-30: Fixed frequency value
* 2024-08-27: Initial implementation according to "http://wiki.dragino.com/xwiki/bin/view/Main/User%20Manual%20for%20LoRaWAN%20End%20Nodes/LMDS200%20-%20LoRaWAN%20Microwave%20Radar%20Distance%20%20Sensor%20User%20Manual/#H3.3SetAlarmDistance280xA229"

### Dragino LSE01 Soil Sensor

* 2020-12-22: Initial Implementation according to "LoRaWAN_Soil_Moisture_%26_EC_Sensor_UserManual_v1.3.pdf"

### Dragino LSN50

* 2022-02-11: Supporting Mode 3, using profile `dragino_lsn50` for field `mode`.
* 2021-03-17: Supporting Mode 1 and 4
* 2020-12-22: Initial Implementation according to "LSN50_LoRa_Sensor_Node_UserManual_v1.7.1.pdf"

### Dragino LSN50V2

* 2025-06-23: Initial Implementation according to https://github.com/dragino/dragino-end-node-decoder/blob/main/LSN50%20%26%20LSN50-v2/LSN50V2_v1.8.0_Decoder_TTN.txt

### Dragino LSN50V2-D20

* 2023-03-07: Initial Implementation according to "Dragino LSN50v2 D20 User Manual (EN).pdf"

### Dragino LSNOK01 Soil Fertility Nutrient

* 2021-08-26: Initial Implementation according to "LoRaWAN_Soil_NPK_Sensor_UserManual_v1.0.pdf"

### Dragino LSPH01 Soil PH Sensor

* 2021-08-26: Initial Implementation according to "LoRaWAN_Soil_Ph_Sensor_UserManual_v1.1.pdf"

### Dragino LT22222-L and LT33222-L I/O Controller

* 2025-02-20: Added MOD6
* 2024-06-19: Added & 0x3F calculation to each mod identification according to ttn parser and added hardware type
* 2021-07-14: Added parsing for old payload format v1.3
* 2021-05-18: Initial Implementation according to "LoRa_IO_Controller_UserManual_v1.5.5.pdf"

### Dragino LTC2-LB LoRaWAN Temperature Transmitter

* 2025-06-18: Initial implementation according to "https://wiki.dragino.com/xwiki/bin/view/Main/User%20Manual%20for%20LoRaWAN%20End%20Nodes/LTC2-LB--LoRaWAN_Temperature_Transmitter_User_Manual/"

### Dragino LTC2 LoRaWAN Temperature Sensor

* 2023-03-02: Initial implementation according to "http://wiki.dragino.com/xwiki/bin/view/Main/User%20Manual%20for%20LoRaWAN%20End%20Nodes/LTC2%20-%20LoRaWAN%20Temperature%20Transmitter%20User%20Manual/#H2.4A0200BUplinkPayload"

### Dragino LWL01 Water Leak Sensor

* 2021-10-13: fixed frame ports
* 2021-10-12: fixed spelling and format
* 2021-10-12: Initial implementation according to "LWL01_LoRaWAN_Water_Leak_UserManual_v1.3.1.pdf"

### Dragino LWL02 Water Leak Sensor + LDS02 Door Sensor

* 2022-01-22: fixed format, added support for 9byte Payloads from LWL01
* 2022-01-21: Initial implementation according to "lds01_02_payload_ttn_v1.5.txt" since PL descriptions doesnt fit

### Dragino LWL03A

* 2024-11-14: Initial implementation according to "https://wiki.dragino.com/xwiki/bin/view/Main/User%20Manual%20for%20LoRaWAN%20End%20Nodes/LWL03A%20%E2%80%93%20LoRaWAN%20None-Position%20Rope%20Type%20Water%20Leak%20Controller%20User%20Manual/#H2.3A0200BUplinkPayload"

### Dragino PS-LB/LS

* 2024-09-05: added profiles and calculations, currently only for cubic tanks.
* 2024-07-22: Initial implementation according to "http://wiki.dragino.com/xwiki/bin/view/Main/User%20Manual%20for%20LoRaWAN%20End%20Nodes/PS-LB%20--%20LoRaWAN%20Pressure%20Sensor/#H2.3200BUplinkPayload"

### Dragino S31x-LB Temperature and Humidity

* 2024-03-07: Initial implementation according to "http://wiki.dragino.com/xwiki/bin/view/Main/User%20Manual%20for%20LoRaWAN%20End%20Nodes/S31-LB_S31B-LB/".

### Dragino SW3L LoRaWAN Outdoor Flow Sensor

* 2023-03-15: Initial implementation according to "http://wiki.dragino.com/xwiki/bin/view/Main/User%20Manual%20for%20LoRaWAN%20End%20Nodes/SW3L%20LoRaWAN%20Outdoor%20Flow%20Sensor/#H2.3UplinkPayload"

### Dragino TrackerD

* 2023-08-22: Added location
* 2023-08-10: Added support for 11 Byte Port 5 Payload according to vendor
* 2023-08-08: Initial implementation according to "http://wiki.dragino.com/xwiki/bin/view/Main/User%20Manual%20for%20LoRaWAN%20End%20Nodes/TrackerD/#HFLAG:"

### DZG Node

* 2021-01-17: Also handle version 2
* 2021-01-10: Initial version

### DZG Node

* 2022-03-17: Update medium index
* 2021-01-17: Also handle version 2
* 2021-01-10: Initial version

### DZG Loramod V2

* 2021-10-29: Updated definition according to newest docs. Added tests.
* 2021-04-15: Using new config() function.
* 2020-10-26: Handling errors when timestamp close to DST borders.
* 2019-12-12: Ignoring frame_port for messages without frame header, fame_port=8 was required before.
* 2019-10-10: Added key interpolated=1 and :obis_value to interpolated readings.
* 2019-09-30: Using meta.transceived_at instead of DateTime.utc_now in add_power_from_last_reading()
* 2019-08-28: Added missing :obis_value key in message format v2.
* 2019-07-31: Added :obis_value key for first register value, supporting MSCONS rule.
* 2019-06-21: Added handling of a-plus-a-minus with register2_value field.
* 2019-05-15: Rounding all values as float to a precision of 3 decimals.
* 2019-05-14: Added full obis code if available. Added interpolation feature.
* 2019-05-13: Return only the latest value with A_Plus qualifier.
* 2019-05-02: Return multiple readings with an A_Plus qualifier and a correct timestamp. DON'T USE THIS!
* 2019-04-29: Also handle medium electricity with qualifier A_Plus.
* 2019-02-18: Added option add_power_from_last_reading? that will calculate the power between register values.
* 2018-12-19: Handling MeterReading messages with header v2. Fixed little encoding for some fields.
* 2018-12-03: Handling MeterReading messages with missing frame header.
* 2018-11-28: Reimplementation according to PDF.

### DZG loramod

* 2019-09-06: Added parsing catchall for unknown payloads.
* 2019-06-20: Added medium "heatcostallocator".

### Eastron SDM230 Electricity Meter

* 2023-03-06: Initial implementation according to documentation Eastron_SDM230-LoRaWAN_protocol_V1.0-combined

### Eastron SDM530 3 Phase Electricity Meter

* 2024-07-24: Initial implementation.

### Eastron SDM630CT 3 Phase Electricity Meter

* 2022-11-30: Initial implementation.

### Eastron SDM630MCT Electricity Meter

* 2021-08-09: Initial version according to "LineMetricsLoRa-PayloadSpezifikationEastronSDM630MCT-050821-0822.pdf"

### EasyMeter ESYS LR10 LoRaWAN adapter

* 2021-06-14: Updated to new payload format according to "BA_ESYS-LR10_Rev1.3_vorläufig.docx".
* 2020-04-17: Fixes after testing phase.
* 2020-02-03: Initial implementation.

### eBZ electricity meter

* 2023-04-13: Added data."1-0:1.8.0" => 2.197 in reading.
* 2020-02-03: MSCONS compatibility and reformatting.
* 2019-05-09: Initial implementation according to "example Payload"

### eBZ electricity meter RD3 Version 0.3.4!

* 2023-04-13: Initial implementation according to "RD3_app_layer_specification_V0_3_4_draft.pdf".

### eBZ electricity meter RD3 Version 1.0.1!

* 2024-08-06: Added catch for empty push messages
* 2024-01-18: Fixed that firmware in combination with other pushes was not possible
* 2023-09-27: Corrected firmware
* 2023-09-25: Corrected voltage factors of u_l1_avg, u_l2_avg, u_l3_avg due to real data
* 2023-09-12: Added missing units
* 2023-09-12: Fixes and added support according to "RD3_app_msg_protocol_specification_1_0_1"
* 2023-06-26: Minor fixes, added get_resp (0x02) support, added set_resp(0x04) support"
* 2023-05-17: Initial implementation according to "RD3_Nachrichten-Protokoll_Spezifikation_1_0_1.pdf"

### eBZ electricity meter v2

* 2022-08-25: Added do_extend_reading callback.
* 2020-05-27: Initial implementation of new version

### Elsys Multiparser

* 2023-06-09: Added dedicated add_dew_point.
* 2022-01-12: Added dew point when temperature and humiditiy exist
* 2021-11-03: Added support for Elsys tvoc Sensor, Adding sTypes 1C
* 2020-12-15: Updating to Payload v1.11. Adding sTypes 00, 10, 13, 1A, 1B, 3E. Removed _unit fields. Added location.
* 2020-04-07: Added all missing sTypes. Fixed negative temperature bugs. Removed offset=0 values.
* 2019-09-06: Added parsing catchall for unknown payloads.
* 2019-02-22: Added sTypes 03, 0F, 14. Fields and Tests.
* 2018-07-16: Added sTypes 04, 05, 06
* 2018-04-12: Initial implementation, not yet all sTypes implemented

### Elvaco CMa11L indoor sensor

* 2019-06-05: Initial parser according to documentation.

### Elvaco CMi41X0 Mbus

* 2025-05-23: Add _error to key, when function_field is error_value
* 2025-04-30: Fixed Typo and allowed to use tariff naming scheme: set use_energy_tariff_naming() to true
* 2024-09-04: Added missing fields
* 2024-08-02: Corrected SHARKY 775 errors due to new documentation: Definition error codes and status bytes SHARKY 775
* 2024-07-29: Renamed strings for SHARKY errors
* 2024-07-24: Changend SHARKY 775 errors to single string
* 2024-07-17: Added errors for DIEHL SHARKY 775 and SCYLAR INT8 according to "Error Payload datarecord definition.pdf"
* 2024-01-30: Added previous energy value when memory_address is 2, Filtered special unit (Part of simple billing format) (CMi4111 v1.3)
* 2023-10-11: Added energy cold and energy heat from tariff 1-2 of scheduled extended+ mode of CMi4110
* 2023-07-05: Added extend_dib_naming_schema for custom renaming dibs. Added max_ and min_ prefix next to unprefixed "current" functions_fields.
* 2022-12-23: Added test for CMi4111 Payload.
* 2022-04-06: Fixing error when error hex string is above 09
* 2022-02-14: Handling CMi4140 'Heat-Intelligence message' without "cool energy e3".
* 2022-02-10: Handling CMi4140 'Heat-Intelligence message'.
* 2021-12-15: Updated extend_reading with meta argument. Added missing field definitions.
* 2021-08-04: Process longer error String
* 2021-04-15: Removing value not parseable by LibWmbus
* 2020-11-24: Added do_extend_reading and OBIS "6-0:1.0.0" to data.
* 2020-07-08: Added all error flags in build_error_string()
* 2020-06-29: Added filter_unknown_data() filtering :unknown Mbus data.
* 2019-09-06: Added parsing catchall for unknown payloads.
* 2019-07-08: Use LibWmbus library to parse the dibs. Changes most of the field names previously defined.
* 2019-07-02: update according to v1.3 of documentation by adding precise error messages.
* 2018-03-21: initial version

### EMU Professional II Lora

* 2023-02-09: Productive version excluding CRC calculation.
* 2023-01-31: Initial implementation.

### Squid V2

* 2023-07-25: Initial implementation according to "https://ewattch-documentation.com/?page_id=11345&lang=en"

### Fast-GmbH AZA-OAD-Logger

* 2024-11-22: Updated payload according to "2024-09-05_Data-set_BIDI-LoRA_EN.docx". Starting pegel index with 1 instead of 0.
* 2022-07-05: Made pegel binary part dynamic long.
* 2022-04-08: Initial version.

### Fleximodo GOSPACE Parking

* 2021-07-22: Initial version according to "fleximodo_rawdata-payload-deciphering.pdf"

### Fludia FM430

* 2019-01-01: Initial implementation.

### Fludia FM432

* 2023-04-06: Added FM432g (to be tested)
* 2023-03-13: Renamed e_pos,... to energy_pos. Fixed scaler detection. Added do_extend_reading callback. Added fields(). Added value to 'unknown'.
* 2023-02-16: Parsing continues after increment error, add_increments() function added
* 2023-01-19: Added FM432e
* 2022-11-10: Initial implementation (FM432ir only)

### GLA intec WasteBox

* 2024-07-11: Allow distance to be 0 for ullage calculation.
* 2022-10-24: Updated initial version and added profile data.

### Globalsat ls11xp indoor climate monitor

* 2020-01-27: Added taupunkt calculation

### GlobalSat GPS Tracker

* 2019-09-19: Ignoring invalid payloads. Handling missing GPS fix.
* 2019-09-06: Added parsing catchall for unknown payloads.

### Gupsy temperature and humidity sensor

* 2019-09-06: Added parsing catchall for unknown payloads.

### GWF LoRaWAN module for GWF metering units

* 2023-12-13: Added support for message type 0x32
* 2021-08-17: Added extend_reading function and missing fields.
* 2021-04-15: Using new config() function.
* 2019-07-04: Added support for message type 0x02.
* 2019-05-16: Removed/changed fields (meter_id, manufacturer_id, state). Added interpolation feature. Added obis codes.
* 2018-08-08: Parsing battery and additional function.
* 2018-04-18: Initial version.

### GWF RCM H200

* 2024-12-18: Initial version according to "lora3: current Value Volume 8 Digit.png"

### Herholdt Controls - ECS WL03

* 2023-02-21: Initial implementation according to "IIST313-07_LoRaWAN_Instruction Manual_Apr_2022.pdf".

### Herz Messtechnik P8 (RC82)

* 2024-07-29: initial version according to P8 (RC82) LoRaWAN Data protocol(Flommit)-V1.2_20240229(2).pdf

### Holley E-Meter

* 2023-04-12: Added a check if 1.8.0 and 2.8.0 do sum up from .1 + .2
* 2023-01-04: Added do_extend_reading callback.
* 2021-04-08: Added new payload format.
* 2019-09-06: Added parsing catchall for unknown payloads.

### Honeywell R110 (Testversion)

* 2025-02-12: Initial implementation (testversion) according to "pmt-hps-r110-lorawan-payload-formats.pdf"

### Hyquest IoTa Sensornode

* 2022-08-12: Added measurement_ID and value count
* 2022-07-26: Initial implementation according to "HS IoTa LoRa Data Format Guide.pdf"

### IMBUILDINGS Multiparser

* 2024-07-30: Initial version according to https://support.imbuildings.com/docs/#/./reference-guide/payload-definitions/

### Imbuildings People Counter

* 2025-01-13: Fixed Battery value for 23 byte payload.
* 2021-10-12: fixed nameing fields for 13 byte payload.
* 2021-10-04: Updated parser to match payloads with 13 byte payload.
* 2020-12-10: Corrected parser due to faulty payload description
* 2020-12-02: Initial implementation according to "IMBUILDINGS - LoRaWAN People Counter - doc v1.1.pdf" (No real tests possible)

### IMST WMBus Bridge

* 2022-02-02: Better heuristik to find server ids
* 2021-12-28: Added parsing of status messages
* 2021-12-27: Initial implementation.

### IMST iOKE868 LoRaWAN

* 2025-03-03: Fixed Port 5 payload
* 2025-03-03: Fixed Segmentation of Port 69 according to real data.
* 2023-03-24: Initial implementation.

### Innotas LoRa Pulse

* 2020-11-30: Initial implementation

### Innotas LoRa EHKV

* 2020-11-25: Refactoring
* 2020-11-23: Initial version

### Innotas LoRa Water Meter

* 2024-06-16: Added hardcoded unit as reading
* 2020-11-25: Refactoring
* 2019-08-27: Initial version

### Integra Aquastream (former Aquametro)

* 2023-01-03: Added alarms from error bytes.
* 2022-12-30: Updated implementation. Added options config.add_measured_at_from_timestamp and config.each_delta_as_reading.
* 2022-09-15: Initial implementation according to "aquastream 9-730-PT-DE-03.pdf"
* 2022-09-27: Corrected parser according to vendor description

### Integra Aquastream Water Meter v3

* 2024-06-07: Added mbus_manufacturer field in case it transmitted over mbus
* 2024-05-03: Corrected alarms. Using alarm definitions (4.4) instead of error flags (3.3)
* 2023-02-13: Added meter_address field.
* 2023-02-10: Initial implementation according to "integra_aquastream 9-730-PT-EN-06.pdf".

### Integra Calec ST 3 Meter

* 2025-01-21: Corrected usage of Lib
* 2023-09-01: Manually parsing status byte from payload
* 2022-11-09: Added try catch for handling WmBus errors.
* 2022-09-01: Fixed reading format. Added tests.
* 2021-10-15: Initial implementation according to "CALEC_ST_III_3-140-P-LORA-DE-02.pdf".

### Integra Topas Sonic Water Meter

* 2024-07-30: Added Payload version 2: Histogram (IMDE02) according to TOPAS_SONIC_RUBIN_SONIC_Payload_1-000-PT-EN-05-1.pdf
* 2023-05-15: Added config option `create_hourly_values=false`.
* 2023-05-10: Added new payload format according to "Topas Sonic-LW8-INTG01-INTG02-V1.0.002.pdf".
* 2022-10-13: Using LibWmbus.parse and providing also WMBus header data like address. Added do_extend_reading callback.
* 2022-03-03: Added new payload format according to "Topas Sonic-LW-INTG01 - V0.1.pdf".
* 2021-07-14: Initial implementation according to "Payload Beschreibung Topas Sonic Lora.pdf".

### InterAct - IOT Controller

* 2021-12-16: Added do_extend_reading callback.
* 2021-10-29: Fixed analog raw to mA conversion.
* 2021-09-30: Initial Version, according to "description_IOT_Controller_v0.1.pdf".

### Isarsoft Perception Edge Bundle

* 2024-05-14: Initial implementation according to example payload given by manufacturer

### Itron Cyble5

* 2022-06-24: Fixing measured_at for 3h/6h/12h formats last message.
* 2022-06-22: Handling measured_at for 3h/6h/12h formats.
* 2022-01-19: Added do_extend_reading/2 callback.
* 2021-01-11: Fixed handling of invalid payloads in decrypt().
* 2020-11-04: Fixed handling of negative values in interval DOB, in case of backflow. Added more fields() definitions.
* 2020-08-27: Added DOBJ 150 "FDR 12 Delta S16". Removed OBIS field adding.
* 2020-08-12: Initial implementation according to "Cyble 5 Lora Data decoding v0.5.pdf" and "DOBJ Table.xlsx".

### Jooby Analog (Test Version)

* 2025-01-22: Implementation of LastEVent, battery alarm and SetTime2000.
* 2024-12-19: Initial version according to "https://github.com/jooby-dev/jooby-docs/blob/main/docs/analog" supporting HourMC only.

### Juenemann LD-System, Gas pressure sensor

* 2024-11-03: Initial implementation according to "LoRa-Kommunikationsprotokoll.pdf" provided by Juenemann: https://juenemann-instruments.de/wp-content/uploads/LoRa-Kommunikationsprotokoll.pdf

### Kairos Water - Noah Multifunction Leak Sensor

* 2024-09-18: Initial implementation according to Noah Payloads.pdf

### Kamstrup flowIQ2200

* 2025-01-24: Added Security Profile D, Supporting manufacturer specific
* 2025-01-10: Added Security Profile A
* 2024-12-03: Fixed output name
* 2024-11-06: Initial implementation with no encryption according to "FILE100003266_D_EN.pdf"

### Keller

* 2022-04-19: Handling invalid float values.
* 2021-07-30: Added missing fields.
* 2021-06-09: Parsing Port 4 Info messages.
* 2021-05-18: Added do_extend_reading and formatted code.
* 2020-11-16: Add device_type 0x03
* 2020-05-26: Revert bits/field_names arrays order.
* 2020-05-05: Fix bits/field_names arrays order by flipping the order.
* 2019-07-30: Initial implementation according to "Kommunikationsprotokoll LoRa v2.1.pdf"

### Kerlink Wanesy Wave

* 2022-06-24: Fix for BLE messages without "t" timestamp.
* 2020-12-16: Initial implementation according to payload version 1.1

### Laird Sentrius RS1xx LoRa Protocol

* 2024-05-30: Reworked parser and updated according to "CS-AN-RS1xx-LoRa-Protocol v2_12_1.pdf"
* 2024-05-29: Initial implementation according to "4444_CS-AN-RS1xx-LoRa-Protocol_v2_10.pdf"

### Lancier Monitoring

* 2025-04-15: Added possibility to separate channel values into different data points: set "add_channel_to_key()" to true
* 2022-08-18: Added Port 100 message according to "Lancier Monitoring LORA Payload Version 0.1.2"
* 2022-08-18: Initial implementation according to "Lancier Monitoring LORA Payload Version 0.1.1"

### Lancier Pipesense

* 2021-01-22: Updated according to "076264.000-03_12.20_BA_D_PipeSens.pdf"
* 2020-10-06: Initial implementation according to "PipeSensLora payload vorab.pdf"

### landis+gyr uh40 lora interface

* 2024-12-03: Added units.
* 2024-11-27: Initial implementation with no encryption according to "TKB3554_UH40_LoRa_EN_.pdf"

### Libelium Smart Devices All in One

* 2021-01-25: Removed duplicate prefix.
* 2021-02-09: Initial implementation.

### Libelium Smart Agriculture

* 2019-09-06: Added parsing catchall for unknown payloads.

### Libelium Smart Cities

* 2019-09-06: Added parsing catchall for unknown payloads.

### Libelium Smart Environment

* 2019-09-06: Added parsing catchall for unknown payloads.

### Libelium Smart Parking

* 2019-11-29: Removed all reverse engineered fields because they changed.
* 2019-09-06: Added parsing catchall for unknown payloads.

### Libelium Smart Water

* 2019-09-06: Added parsing catchall for unknown payloads.

### Libelium Smart Agriculture Pro

* 2019-01-26: Initial implementation.

### Libelium Smart City Pro

* 2021-01-28: Formatting + Tests
* 2021-01-26: Initial implementation.

### Libelium Smart Water Xtreme

* 2021-01-26: Initial implementation.

### Lobaro EDL21

* 2022-02-22: Initial implementation.

### Lobaro EDL21 dzero

* 2023-01-31: Initial implementation.

### Lobaro Environmental Sensor

* 2020-01-23: Initial implementation according to "https://docs.lobaro.com/lorawan-sensors/environment-lorawan/index.html" as provided by Lobaro

### Lobaro GPS Tracker

* 2020-12-04: REWRITE of parser with NEW field names. Fixing wrong parsing between versions.
* 2020-11-25: Fixed negative Temperature for v5.0
* 2020-11-04: Added Payload Version 7.0 and 7.1 and disabled output of GPS data of 5.0 version when no sat. is available.
* 2020-01-10: Added Payload Version 5.0.
* 2019-09-06: Added parsing catchall for unknown payloads.

### Lobaro Hybrid Pegelsonde

* 2023-01-25: Added 5,7,9 byte Payload representation according to the provided javascript parser
* 2022-08-02: Initial implementation according to https://doc.lobaro.com/doc/hybrid-nb-iot-+-lora-devices/hybrid-modbus-gateway/sample-implementations

### Lobaro Modbus Bridge v1.0

* 2023-06-28: Fixed Modbus exception code texts
* 2022-01-13: Added reparsing_strategy: sequential
* 2022-01-11: Fixed add_timestamp to convert all timestamp to DateTime. Added do_extend_reading/2 callback.
* 2021-09-23: Improved handling of splitted Port 5 messages.
* 2021-07-14: Fixed a bug in add_timestamp
* 2021-03-23: Supporting bridge firmware version from v1.0, and verbose format.

### Lobaro MQTT Bridged Device Driver

* 2025-06-05: Initial version

### Multi Temperature Sensor Box

* 2023-09-26: Initial implementation according documentation https://doc.lobaro.com/doc/products/discontinued-products/multi-temperature-sensor-box-lorawan#MultiTemperatureSensorBox(LoRaWAN)-Payload

### Lobaro Oscar smart waste ultrasonic sensor

* 2018-01-01: Initial implementation

### Lobaro Oskar v2

* 2019-10-04: Initial implementation according documentation provided by Lobaro

### Lobaro Water Level Sensor

* 2022-04-19: added Profile support to calcule water depth and parse status messages on frame_port 64
* 2019-11-21: updating parser according to firmware version 0.1.0
* 2019-05-14: Initial implementation according to "LoRaWAN-Pressure-Manual.pdf" as provided by Lobaro

### Lobaro WMBus Bridge

* 2023-04-20: Reformatted, added tests.
* 2021-01-22: Updated device_type_to_string list.
* 2020-07-27: Fixed temp, added format 2, added tests, added fields definition.
* 2020-06-30: Current state, added tests.
* 2019-03-14: Initial implementation.

### LPP Cayenne

* 2019-03-07: Initial implementation

### MCF88 Multiparser

* 2025-02-05: Added support for 1.3, 1.7, 1.7.1, 1.9.1, 1.10, 1.12, 1.14, 1.16, 1.17  and updated support for 1.1
* 2022-09-02: Added support for report_data revision 1.32 with config option report_data_note3_version
* 2022-07-26: Added support for lwws001 pm data frame
* 2022-07-04: Added do_extend_reading callback.
* 2022-07-01: Added time_sync_answer payload to time_sync_req.
* 2022-03-03: Added config option timestamp_as_measured_at = false
* 2022-02-01: Added payloads for MCF-LW13IO.
* 2022-01-14: Added config show_all_flags with default `false`.
* 2021-11-04: Fixed endianess of many values.
* 2021-09-27: Added Power (ignoring timestamp of these messages)
* 2021-09-07: Added Note 3 for MCF-LWWS00
* 2021-02-18: Initial implementation according to "MCF88 Data Frame Format 1.24.pdf".

### MClimate HT Sensor

* 2022-12-14: Initial Implementation.

### MClimate 16ASPM

* 2025-01-27: Initial Implementation.

### MClimate Vicki

* 2024-11-12: Added command 0x19 and 0x1F from TTN Parser
* 2024-10-15: Added command 0x1D from TTN Parser
* 2024-01-25: Fixed error in dew point calculation when humidity is zero. Added reading dew_point_error in this case.
* 2024-01-23: Updated mapping list
* 2024-01-17: Fixed Typos, added switch for writing relevant readings into fields, added support for 0x46 command response, fixed 0x13
* 2023-12-20: Added command 0x44 (get external temperature), 0x1b (Get uplink messages type command explanation).
* 2023-11-21: removed duplicate rel_hum calculation
* 2023-10-19: Added command response 0x2B.
* 2023-07-05: added command mode 0x16, 0x17, 0x29, 0x36, 0x3D, 0x3F, 0x40, 0x42
* 2023-05-19: fixed float calculation
* 2023-04-18: Writing SW-Version into vicki profile, fixed child lock statement
* 2023-04-05: Added support for firmware 4.1 and added command support
* 2023-01-18: Added relative valve position and fixed field names
* 2022-11-03: Added Payloads starting with 0x28 (reply to commands)
* 2021-12-21: Updated to latest firmware 3.5. Added Command-Code 0x81.
* 2021-08-27: Initial Implementation of keepalive frame according to "MClimate_Vicki_LoRaWAN_Device_Communication_Protocol_1.7.pdf"

### Milesight AM100 Series

* 2021-12-15: Initial implementation according to "am100-series-user-guide-en.pdf"

### Milesight AM300 Series

* 2021-12-13: Initial implementation according to "am300-series-user-guide-en.pdf"

### Milesight AT101

* 2024-10-16: Changed Location handling and WiFI Scans Output
* 2024-10-02: Initial implementation according to "https://github.com/Milesight-IoT/SensorDecoders/tree/main/AT_Series/AT101"

### Milesight and Ursalink CT10x

* 2024-06-17: https://github.com/Milesight-IoT/SensorDecoders/tree/main/CT_Series/CT101

### Milesight and Ursalink EM300 Series

* 2024-07-02: Added EM300-Di support according to https://github.com/Milesight-IoT/SensorDecoders/tree/main/EM_Series/EM300_Series/EM300-DI

### Milesight and Ursalink EM300 Series

* 2024-07-02: Added EM300-Di support according to https://github.com/Milesight-IoT/SensorDecoders/tree/main/EM_Series/EM300_Series/EM300-DI
* 2023-09-26: Added EM320-Tilt support according to https://github.com/Milesight-IoT/SensorDecoders/tree/main/EM_Series/EM300_Series/EM320-TILT
* 2023-08-03: Added EM320-TH support according to "em320-th-user-guide-en.pdf"
* 2023-02-20: Skip empty UP payloads, occuring with link_check_req commands.
* 2022-10-10: Added missing Fields for EM310 UDL from "em310-udl-user-guide-en.pdf".
* 2021-02-01: Added undocumented payload part FF0B...
* 2021-01-27: Initial version from em300-series-user-guide-en.pdf

### Milesight and Ursalink EM400

* 2023-08-15: Initial version according to em400-mud-user-guide-en.pdf

### Milesight and Ursalink EM500

* 2022-04-21: Initial version according to em500-series-communication-protocol-en.pdf

### Milesight and Ursalink GS101

* 2024-05-28: Initial version according to "Milesight GS101 User Manual (EN).pdf".

### Milesight and Ursalink GS301

* 2024-03-08: Initial version according to gs301-user-guide-en.pdf

### Milesight and Ursalink UC100

* 2023-07-24: Added profile support to configure byteorder
* 2023-07-20: Initial version according to uc100-user-guide-en.pdf

### Milesight and Ursalink UC11xx

* 2021-01-28: Initial version from uc11xx_control_protocol_en.pdf v1.4

### Milesight UC300 Series

* 2024-02-02: Added Modbus to parser
* 2024-01-29: Initial implementation according to "https://github.com/Milesight-IoT/SensorDecoders/tree/main/UC_Series/UC300"

### Milesight and Ursalink UC50x

* 2023-10-16: Initial version according https://github.com/Milesight-IoT/SensorDecoders/tree/main/UC_Series/UC50x

### Milesight and Ursalink UC51x

* 2024-07-02: Initial implementation according to "https://github.com/Milesight-IoT/SensorDecoders/blob/main/UC_Series/UC51X/README.md"

### Milesight and Ursalink VS121

* 2023-06-14: Initial version according to vs121-user-guide-en.pdf

### Milesight and Ursalink VS132

* 2023-07-25: fixed parse_parts function
* 2023-01-05: Initial version according to vs132-user-guide-en.pdf

### Milesight and Ursalink VS133

* 2023-07-24: Initial version according to "https://github.com/Milesight-IoT/SensorDecoders/blob/main/VS_Series/VS133/README.md"

### Milesight and Ursalink WS101

* 2023-05-02: Corrected modes
* 2022-04-28: Initial version according to ws101-user-guide-en.pdf

### Milesight and Ursalink WS136 & WS156

* 2022-08-12: Initial version according to ws136&ws156-user-guide-en.pdf

### Milesight and Ursalink WS201

* 2024-03-08: Initial version according to milesight_ws201_smart fill level monitoring sensor_user guide-v1.0_en.pdf

### Milesight WS202

* 2024-06-10: Initial version according to https://github.com/Milesight-IoT/SensorDecoders/tree/main/WS_Series/WS202

### Milesight and Ursalink WS301

* 2022-05-17: Initial version according to ws301-user-guide-en.pdf

### Milesight and Ursalink WS302

* 2024-02-01: Initial version according to ws302-user-guide-en.pdf

### Milesight and Ursalink WS50x

* 2023-09-26: Initial version according to https://github.com/Milesight-IoT/SensorDecoders/tree/main/WS_Series/WS50x

### Milesight and Ursalink WS52x

* 2023-07-13: Added "Channel 3F, Outage".
* 2022-09-16: Initial version according to https://github.com/Milesight-IoT/SensorDecoders/tree/master/WS_Series/WS52x

### Milesight and Ursalink WT101

* 2024-02-13: Initial version according to https://github.com/Milesight-IoT/SensorDecoders/tree/main/WT_Series/WT101

### Milesight WT30x

* 2024-11-15: Initial version according to wt30x-user-guide-en.pdf

### Mioty metering

* 2023-09-29: Initial version.

### MIROMICO FMLR IoT Button

* 2021-10-20: Initial implementation according to "Miromico IoT-Button Factsheet (EN).pdf" with given example payloads

### Miromico Insight

* 2024-04-03: fixed temperature calculation
* 2023-12-04: Initial implementation according to https://docs.miromico.ch/iot-devices/miro-insight-lorawan/payload/

### Mutelcor MTC-PB01 / MTC-CO2-01 / MTC-XX-MH01 / MTC-XX-CF01

* 2021-07-01: Added Manhole and Customer Feedback sensor.
* 2020-12-11: Initial version.

### Mutelcor MTC-XX-AU01/02/03/04

* 2023-12-14: Initial version.

### NAS ACM CM3010

* 2019-12-09: Fixed boot message for newer longer payloads.
* 2019-11-15: Handling 32bit usage payload too.
* 2019-08-27: Update parser to v1.3.0; added catchall
* 2018-06-26: Initial implementation according to "Absolute_encoder_communication_module_CM3010.pdf"

### NAS CM3020

* 2019-01-01: Initial implementation according to "https://www.nasys.no/wp-content/uploads/Wehrle_Modularis_module_CM3020_3.pdf"

### NAS CM3022

* 2023-01-04: Fixed volume readings. Value is "little" encoded.
* 2022-12-27: Initial implementation according to "NAS CM3022 2.3.x Payload Structures.pdf"

### NAS CM3030 Cyble Module

* 2019-08-26: Initial version

### NAS CM3060 BK-G Pulse Reader

* 2023-11-06: Update according to "BK_G_Pulse_Reader_cm3060-1.pdf"
* 2019-08-26: Initial version

### NAS PULSER BK-G CM3061

* 2024-03-05: Added do_extend_reading Callback.
* 2024-02-03: Fixed some edgecases.
* 2024-02-02: Added conditional parts of payload
* 2024-01-29: Update according to "https://www.nasys.no/wp-content/uploads/CM3061-2.3.x-Payload-Structures.pdf"
* 2020-04-17: Initial version

### NAS Luminaire v0.6

* 2021-07-26: This parser supports v0.6, use v1.0 parser for newer hardware.
* 2019-04-04: Initial version

### NAS Luminaire v1.0

* 2021-08-02: Added missing commands and events.
* 2021-07-29: Updated for payload v1.0

### NAS UM30x3 Pulse+Analog Reader

* 2020-09-28: Interpolation now for digital1 and digital2 instead of obis key.
* 2020-06-29: Added filter_unknown_data() filtering :unknown Mbus data.
* 2020-05-13: Fixed interpolate: false. Made configuration testable.
* 2019-05-22: Adjusted fw version on boot message and also return status message from boot message as separate reading.
* 2019-05-17: Added obis field for gas_in_liter. Added interpolation of values. Fixed boot message for v0.7.0.
* 2019-05-07: Also handling UM3033 devices.
* 2019-05-07: Updated with information from 0.7.0 document. Fix rssi and medium_type mapping.
* 2018-09-04: Added tests. Handling Configuration request on port 49

### NAS UM3110

* 2023-12-06: Initial implementation according to "NAS UM3110 4.0.x Payload.pdf" (Supporting usage_packet, status_packet and general_configuration_packet)

### NetOp Multiparser

* 2020-10-06: Added support for ambient light sensor (v1.9)
* 2019-05-09: Initial implementation according to v1.8, including door and manhole sensors.

### Netvox Multiparser

* 2023-12-18: Fixed multiplier logic - multiplier packet arrives after the packets with currents
* 2023-06-20: Added R718MBB Activity Event Counter.
* 2023-03-29: Added R718G Light Sensor.
* 2022-08-12: Added R718N360, fixed R718N
* 2021-06-16: Added support for R311A/R718F/R311CC/R730F
* 2021-04-15: Fixed temperature scale.
* 2020-12-22: Added support for R718CJ2/CK2/CT2/CR2/CE2/R730CJ2/CK2/CT2/CR2/CE2 two channel temperature sensors.
* 2020-12-22: Added support for R311FA/RA02C/RA0716 sensor. Formatted code.
* 2020-11-19: Added support for R711/R718A/R718AB/R720A temperature/humidity sensors.
* 2020-06-16: added 3 phase current meter (BROKEN)
* 2020-04-28: added some more sensor types
* 2020-01-09: added some sensor types
* 2019-07-01: fix bug
* 2019-06-05: refactoring. Checked with v1.8.5
* 2019-04-30: initial version (Light Sensors: R311G, R311B,  Water Leak Sensors: R311W, R718WB, R718WA, R718WA2, R718WB2)

### Nexelec D678C Insafe+ Carbon, Temperature and Humidity

* 2020-05-04: Added config flag "config_add_last_real_time_data_to_button_press?"
* 2020-02-28: Initial implementation according to "D678C_Insafe+_Carbon_LoRa_Technical_Guide_EN.pdf"

### Nexelec D770A Air Lora

* 2023-10-19: Initial implementation according to "D770A_Air_Lora_Technical_Guide_EN_V5.7_public.pdf"

### nke AtmO / nke Remote Temperature and Humidity

* 2024-01-26: Added nke Remote temperature according to https://support.watteco.com/remot_th/
* 2022-09-27: Initial implementation according to https://support.nke-watteco.com/atmo/

### NKE Watteco - Eolane Bob Assistant

* 2021-06-16: Initial implementation according to "BoB_ASSISTANT_Reference_Manual_V1.1.pdf"

### NKE Watteco Clos'O

* 2020-10-15: Initial implementation according to "Clos'O_50-70-108-000_SPG_V0_9 EN _1_.pdf".

### NKE Watteco Flash'O

* 2023-06-30: Initial implementaion

### NKE Watteco IN'O

* 2023-02-03: Added switch to generate output key for each endpoint when activated
* 2022-03-21: deleted debug messages + named field in Bitmap16
* 2022-03-17: Added support for Node power descriptor
* 2022-03-15: Added support for Bitmap16 attribute_type
* 2019-05-09: Added support for ModBus device.
* 2018-11-19: Renamed fields according to NKE docs, see tests. Added parsing of cmdid, clusterid, attrid, attrtype.
* 2018-09-17: Handling missing fctrl, added fields like "input_2_state" for better historgrams.

### NKE Watteco Intens'O

* 2021-02-11: Made "rp" and "csp" optional at payload ending.
* 2021-02-05: Initial implementation according to "http://support.nke-watteco.com/wp-content/uploads/2019/03/50-70-098_Intenso_User_Guide_1.1_Revised.pdf"

###  NKE Watteco ModBus

* 2024-02-13: Removed debug function
* 2023-09-19: Initial implementation according to https://support.watteco.com/modbus/

### NKE Watteco Monit'O

* 2022-03-31: Initial implementaion

### NKE Watteco Movee

* 2024-09-03: Initial implementation according to "UserGuide_-_Movee-v2.01_nke_watteco.pdf"

### NKE Watteco Press'O

* 2022-03-18: Initial implementaion

### NKE Watteco Remote Temp

* 2024-07-23: Allow to add key for each endpoint and to rename it.
* 2022-04-08: Updated error handling.
* 2019-11-18: Initial implementation.

### NKE Watteco Pulse Sens'O

* 2022-11-21: Added profile support for initial meter reading and factor for each input
* 2020-11-23: Initial implementation according to "http://support.nke-watteco.com/pulsesenso-2/#ApplicativeLayer"

### NKE Watteco Smart Plug

* 2021-05-12: Added heartbeat. Formatted Code.
* 2020-08-20: Added tests, refactoring.
* 2019-01-01: Initial Version.

###  NKE Watteco Multiparser (In Progress)

* 2024-04-17: Initial implementation of Clusters
* 2024-03-25: Initial implementation Triphas'o
* 2024-03-19: Progress
* 2024-02-23: Initial implementation (In Progress)

### NKE Watteco Ventil'O

* 2024-02-26: Initial implementation according to "https://support.watteco.com/ventilo/"

### Orbiwise noicesensor

* 2022-05-17: fixed calculation with real data
* 2022-05-12: Initial implementation according to provided data via E-Mail

### OXON - Multiparser

* 2024-02-09: Added Oxobutton 2  according to "Oxobutton_2_Manual" - Not tested
* 2022-08-17: Added Buttonboard (FW version 1.2.8) according to "https://www.oxobutton.ch/products/buttonboard-lorawan/documentation#uplink"
* 2021-11-29: Initial implementation of Oxobutton Q according to "https://www.oxobutton.ch/products/oxobutton-lorawan/documentation#uplink"

### Palas AQ Guard Smart

* 2025-01-24: Initial implementation according to 2025-01-21_payload_description.xlsx

### paramair aura co2

* 2024-09-04: Added support for payload versions v3, v4a, v4b
* 2024-08-19: Initial implementation according to "eLichens_Aura-CO2_UserManual-19_10_02_082023_EN.pdf"

### Parametric PCR2 People Counter Radar

* 2021-09-07: added pcr2_ods device type 5
* 2021-08-12: fixed the unit of sbx_batt according to https://www.parametric.ch/de/docs/pcr2/pcr2_app_payload_v4
* 2020-10-22: Implemented v4 according to https://parametric.ch/docs/pcr2/pcr2_app_payload_v4
* 2020-07-07: Implemented v3 according to https://parametric.ch/docs/pcr2/pcr2_app_payloads_v3, renamed field temperature to cpu_temp
* 2020-06-09: Initial implementation according to https://parametric.ch/docs/pcr2/pcr2_app_payloads_v2

### Parametric PMX TCR Radar Traffic Counter

* 2025-04-23: Corrected speed categories for counter payload
* 2024-09-12: Added Category depending on Frame_Port and fixed Voltage calc
* 2024-09-06: Updated implementation according to "PMX TCR LoRaWAN Payload Description.pdf" and changed name to "Parametric PMX"
* 2021-09-22: Updated implementation according to https://parametric.ch/docs/tcr/tcr_payload_v3
* 2020-09-29: Updated implementation according to https://parametric.ch/docs/tcr/tcr_payload_v2
* 2020-07-07: Initial implementation according to https://parametric.ch/docs/tcr/tcr_payload_v1

### Parametric TCR Radar Traffic Counter Gen 2

* 2023-08-30: Added support for counter payload according to docu.
* 2023-08-25: Implementation of firmware V2.2 according to https://docs.parametric-analytics.com/tcr/manuals/lora_payload/

### PARKLAB - Wireless Parking Space Detection WPSD

* 2023-04-20: Initial implementation according "Payloadbeschreibung PARKLAB Technologie GmbH.pdf".

### PaulWegener Datenlogger ASCII

* 2020-03-26: Initial implementation according to example payload.

### PaulWegener Datenlogger BINARY

* 2022-11-17: Added do_extend_reading callback.
* 2021-12-01: Using little binary value for bytes > 1
* 2021-11-23: Initial implementation according "BA iModem LoRaWAN-1.pdf" from Aug. 2021

### Pepperl+Fuchs WILSEN.sonic.level

* 2025-06-04: Added water level for UC7000-Model
* 2024-07-18: Updated due to Beschreibung der Payload für WILSEN.node WSN-*-F406-B41-*-02 (payloadbeschreibung.pdf)
* 2023-05-17: Checked compatibility with "20221024_tdoct7056mod_eng_for_distance_draft.docx".
* 2022-11-15: Added support for mm and amplitude payload design
* 2021-10-25: Added do_extend_reading/2 Callback
* 2021-10-14: added missing fields
* 2021-05-17: Updated according to Document "tdoct7056__eng.docx", added error handling.
* 2020-07-06: Initial implementation according to Document "TDOCT-6836__GER.docx"

### Pietro Fiorentini SSM-AQUO

* 2024-04-16: Fixed alarm interpretation due to documentation v1.1
* 2022-10-07: Initial implementation according to "Radio Payload_SMM-Aquo_v1_20220506.pdf"

### Pipersberg Octave Watermeter

* 2023-12-06: Initial implementation according to "OCTAVE XTR_LoRa_Nachricht 0x80_WT Log Beacon.pdf" and "TTN Parser 0x80+9B Beacons WT Log Frame & Alarm.js".

### Pipersberg Ultrimis Watermeter

* 2025-05-12: Added Payload Version 0x8001
* 2025-05-02: Filter not documented payload (Payload Version 0x80)
* 2025-02-26: Changed start_volume to signed
* 2023-12-07: Added config allow_negative_delta: true
* 2023-11-13: Fixed bug for 'Ignoring delta volume values FFFF and after' with create_hourly_values=true.
* 2023-11-08: Fixed tests for 32bit volume_start value.
* 2023-10-30: Corrected volume_start is 32bit not 16bit.
* 2023-05-15: Added config option `create_hourly_values=false`. Added OBIS "8-0:1.0.0".
* 2023-04-27: Added data.volume_previous_x values.
* 2023-04-20: Added more tests from real device.
* 2023-04-04: Initial implementation according to "ULTRIMIS V1.5 LoRa PAYLOAD.pdf"

### Plenum Kuando Busylight

* 2023-04-13: Initial implementation according to "Technical Documentation kuando IoT Busylight v3.1 - LoRa.pdf"

### PNI PlacePod parking sensor

* 2023-03-27: Added tests from PNI-Sensor-PlacePod-Communications-Protocol.pdf
* 2021-08-23: Added known mapping for internal channel 5 and 6. Added missing fields(), formatted code.
* 2021-08-11: Parse even with PNI internal data.
* 2021-04-20: Added do_extend_reading/2 and add_bosch_parking_format/1 for Bosch park sensor compatibility.
* 2019-12-10: Initial implementation according to "PNI PlacePod Sensor - Communications Protocol.pdf"

### Polysense - Multiparser

* 2022-10-13: Initial Implementation according to http://pmo4d0f6d.hkpic1.websiteonline.cn/upload/PolysenseWxS8800UserGuide.pdf (13.10.2022)

### Quandify Cubic Meter

* 2024-03-11: Initial implementation according to cm2-decoder-light

### Rainbow 7in1 LoRaWAN soil sensor

* 2025-04-09: Initial version according to Lorawan_7_in_1_soil_sensor.pdf and correction of manufacturer

### RAK Button

* 2019-05-09: Added tests, fields and documentation.
* 2019-05-09: Initial implementation according to "RAK_LB801LoRaButtonATFirmwareUserManualV1.0.pdf"

### RFI Remote Power Switch

* 2020-03-17: Initial implementation

### Sagemcom Siconia

* 2019-09-06: Added parsing catchall for unknown payloads.
* 2019-01-01: Initial implementation.

### Sagemcom Siconia WM15-L

* 2021-12-07: Initial implementation according to "SCOM_U3_EAU_DN15_Frame_Format_SvG_2021-06-21.pdf".

### SEBA SlimCom IoT-LR for Dipper Datensammler

* 2023-02-24: Fixed timezone to "Etc/GMT-1".
* 2021-08-03: Initial version according to "BA_SlimCom IoT_DE.PDF".

### Seeed Studio SenseCAP S210X

* 2024-02-27: fixed a bug in temperature calculation
* 2023-07-20: added support for most SenseCAP S210X sensors
* 2021-04-19: Added field for battery + new test
* 2021-04-15: Initial Version. Documentation: https://sensecap-docs.seeed.cc/pdf/SenseCAP%20LoRaWAN%20Sensor%20User%20Manual-V1.1.pdf

### Seeed Studio SenseCAP S2120

* 2025-01-29: Initial Version. Documentation: SenseCAP S2120 LoRaWAN 8-in-1 Weather Station User Guide.pdf

### Seeed Studio SenseCAP Tracker T1000-A/B

* 2025-03-04: Initial Implementation according to: SenseCAP_Tracker_T1000-AB_User_Guide_EN.pdf

### Sensative Strips Comfort

* 2023-11-21: Corrected avg temperature due to LoRa-Strips-Payload-formats-2
* 2020-07-02: Updated payload to Strips-MsLoRa-DataFrames-3.odt, ignoring frame_port=2 for now.
* 2019-11-05: Fixed order of temperature/humidity in 1.1.17, 1.1.18 and 1.1.19.
* 2019-09-10: Initial implementation according to "Sensative_LoRa-Strips-Manual-Alpha-2.pdf"

### Sensoco Loomair

* 2021-09-23: Initial Version, according to "Sensoco Loomair M Payload Structure v1.0.pdf".

### SensoNeo Quatro Sensor

* 2021-10-26: Added do_extend_reading/2 Callback
* 2019-10-16: Initial implementation according to "sensoneo_quatro_QS_Payload_v2.pdf".

### SensoNeo Single Sensor

* 2021-10-26: Added do_extend_reading/2 Callback
* 2020-12-10: Fixed negative temperatures in v3 Payload. Added field payload_type.
* 2020-04-22: Added calculated ullage in % from configurable profile
* 2019-10-11: Supporting v3 payloads.
* 2019-10-10: New implementation for <= v2 payloads.
* 2019-09-06: Added parsing catchall for unknown payloads.
* 2018-09-17: fixed position value, was switched
* 2018-09-13: Initial version.

### Sensoterra Probe

* 2025-05-15: Corrected calculations due to manufactures explanation
* 2025-05-08: Merged rows in case of multi mode
* 2025-02-28: Initial implementation according to "2410-Local-Mode-Technical-Documentation.pdf"

### Sentinum APOLLON-Q

* 2021-10-26: Added do_extend_reading/2 Callback
* 2020-11-17: Initial implementation according to "Apollon_A4_Payload_Beschreibung.pdf"

### Sentinum FEBRIS Co2

* 2021-11-03: Fixed newer minor versions and battery unit.
* 2021-04-30: Fixed temperature and typos.
* 2021-04-20: Initial implementation according to "Febris_A4_Payload_Beschreibung.pdf"

### Sentinum FEBRIS SCW

* 2023-05-23: Initial implementation according to "SCW.decoder.sub2.js".

### Sentinum Hyperion

* 2024-08-22: Initial implementation according to "https://docs.sentinum.de/en/lorawan-interface"

### Senzemo Microclimate 3.0

* 2024-08-06: Untested - Initial implementation according to "https://senzemo.com/wp-content/uploads/2022/12/Senstick_SMC30-HWv3.0_FWv1.0-LoRaWAN_Protocol_v1.9.pdf"

### Sewerin Leckage Sensor

* 2025-02-07: Fixed Recursion
* 2025-02-07: Initial implementation according to document "Message Items.pdf"

### Skysense SKYAGR1

* 2021-08-11: Initial Version, according to "SKYAGR1.pdf" version 1.0.7.

### SLOC Multiparser

* 2022-02-28: Updated implementation according to "LoRa Payload Description_v1.4.pdf"
* 2022-02-22: Added do_extend_reading callback.
* 2022-02-21: Updated implementation according to "LoRa Payload Description_v1.2.pdf"
* 2021-12-22: Using first 4 bytes as measured_at. Skipping "unknown_datapoint_XXX" rows.
* 2021-07-15: Initial implementation according to "LoRa Payload Description_v1.1.pdf"

### Smilio Action v2

* 2020-11-26: Implemented missing modes CODE, PULSE and Downlink Query Frame.
* 2019-02-14: Initial version.

### SoilNet LoRa (Jülich Forschungszentrum)

* 2021-01-19: Fixed optional temperature for SMT100 Sensors.
* 2021-01-06: Initial implementation according to "SoilNet_LoRa_WSW.PDF"

### LPWANminiUNI Truebner-STM100

* 2022-11-28: Added parsing for a 3 module setup
* 2022-10-28: Initial Implementation according to LPWAN_truebnerSMT100_EN.pdf (HW Version and SW Version inconsistent with testpayload)

### Sontex Supercal/Superstatic

* 2020-06-26: Using memory_address, sub_device and tariff in reading keys.
* 2020-06-09: Initial implementation according to "M-Bus Frames 7x9 - LoRAWAN_20190812.pdf"

### Sontex SQ1 water meter

* 2024-03-12: Initial implementation according to "JSParserSQ1MbusFrameLoRa.txt", "M-Bus frames SQ1.pdf" and "AN_SQ1 LoRaWAN_V01_2207_en.pdf"

### Sontex Supercal 5

* 2024-07-11: Initial implementation according to "CSMDE-Supercal 5 LoRaWAN Configuration & payload setting-030624-112721.pdf"

### Sontex Wecount-S

* 2023-04-05: Initial implementation according to "Radio-Telegram_LoRa_WECOUNT-S_Payload_0.3.4_20221121.xlsx"

### Speedfreak_v4

* 2021-01-26: Initial implementation

### Strega Smart Valve

* 2022-02-24: Added extend_reading callback.
* 2021-07-12: Fixed parsing of FULL payloads. Formatted code.
* 2021-07-01: Processing payloads for LITE and FULL device models.
* 2021-04-23: Added hint for custom payloads from FULL devices.
* 2020-06-12: Supporting v4 Payloads, RENAMED READING FIELDS!
* 2019-09-06: Added parsing catchall for unknown payloads.
* 2018-09-13: Initial version.

### SuMiDen Devices

* 2024-04-18: Initial version according to "SuMiDen Device Data Parsing"

### Swisscom LPN Multisense

* 2021-07-07: Added do_extend_reading/2 callback and added field definition.
* 2021-02-25: Allowed payload version up to 2.
* 2021-01-25: Initial version of parser, according to "Multisense_User_Guide-de.pdf" v2 from 02/11/2020

### Swisslogix/YMATRON SLX-1307

* 2019-03-28: Initial version of parser, according to DOC_1074_01_A_InterfaceLoRaFillLevelSensorSLX_1307_V1_1.pdf

### Synetica enlink Air X

* 2024-09-04: Initial implementation according to https://github.com/synetica/enlink-decoder?tab=readme-ov-fil

### Tecyard Multiparser

* 2019-06-25: return mV instead of V for voltage.
* 2019-06-24: Implement sensors 0x06 to 0x82.
* 2019-06-20: Initial implementation according to "TecyardSensorProtocol-v2_SWKN.xlsx"

### Tecyard RattenSchockSender

* 2019-06-04: Initial implementation according to "RattenSchockSenderHHWasser.pdf"

### Tekelek Multiparser

* 2024-01-26: Added TEK 893(Atex) and changed to multiparser.
* 2022-05-18: Added tank.capacity profile field.
* 2021-05-18: Added tank.sensor_distance profile field. Formatted code.
* 2020-01-27: Fixed handling of tank.form profile field.
* 2019-05-22: Read tank height and form from device profile. Calculate fill level depending on form.
* 2018-11-29: Initial version of parser CF-5004-01 TEK 766 Payload Data Structure R1.xlsx

### TEKTELIC Agriculture

* 2024-01-25: Fixed muc_temperature calculation according to "T0005978_TRM v. 2.1.1"
* 2024-01-04: Added dew_point calculation
* 2023-09-12: Corrected temperature calculation of voltage input 3 and 4"
* 2023-05-23: Updated according to "T0005978_TRM_Kiwi_Clover_ver2.0.pdf"
* 2022-04-06: Added watermark*_kpa_raw values not normalized to 24° if no temperature is available.
* 2021-03-17: Fixed negative values for ambient temperature and added roundings for watermark and temperatures
* 2020-11-09: Initial implementation according to "T0005978_TRM_Agriculture_Sensor_ver1_4.pdf"

### Tektelic Industrial GPS Asset Tracker

* 2020-06-16: Fixed call to add_location. Always creating locations ignoring gps_valid flag.
* 2020-06-11: Initial implementation according to "T0006279_TRM_ver0.6.r1.pdf"

### Tektelic Kona home sensor

* 2019-10-15: Initial implementation according to "T0005370_TRM_ver2.0.pdf"

### Tektelic Smart Home Sensor

* 2021-11-01: Initial implementation according to "T0006338_TRM_ver2_2.pdf"

### TENEO CO2 Ampel

* 2021-03-11: Initial implementation according to "Payload-documentation-CO2-stoplicht-V1.0-EN.pdf"

### Terabee Level Monitoring XL

* 2021-05-10: Initial implementation according to "LoRa-Level-Monitoring-XL-User-Manual-MAR-2021.pdf"

### Terabee People Counter

* 2024-01-04: Initial implementation according to "Terabee+People+Counting+L-XL+-+User+Manual+-+EN+v3.2+(3)-1.pdf"

### Tetraedre

* 2020-10-29: Initial implementation according to "Proposal of April 30th, 2016. Thierry Schneider, Tetraedre Sarl"

### Thermokon Multiparser

* 2025-06-19: Added downlink packets
* 2024-04-16: Initial implementation according to "LoRaWAN_Schnittstellenbeschreibung_de.pfd" Revision B

### TIP SINUS LoRaWAN

* 2025-01-29: Initial implementation according to "Kurzbedienungsanleitung_SINUS_Zähler_LoRaWAN_V5.pdf"

### BROWAN Tabs (formerly TrackNet Tabs)

* 2022-05-17: Fixed calculation mistake on ambient light sensor
* 2021-08-24: Added Sound level Sensor according to "RM_Sound Level Sensor_20200210.pdf".
* 2021-04-21: Updated Healthy Home IAQ Sensor according to "BQW_02_0005.003".
* 2021-03-29: Added Water Leak Sensor from "Tabs Water Leak Datenblatt EN"
* 2020-12-22: Added Ambient Light Sensor from "RM_Ambient light Sensor_20200319 (BQW_02_0008).pdf" and formatted code.
* 2020-09-28: Update battery calculation for new Healthy Home Sensor version
* 2020-09-23: Added support for new Healthy Home Sensor version (with indoor-air-quality)
* 2019-04-04: Initial version, combining 5 TrackNet Tabs devices.

### Treesense LoRaWAN

* 2024-04-09: Updated parser according to TTN decoder: Pulse R (v1.0), Pulse S (v1.1)
* 2023-09-15: Initial implementation according to the vendor provided information

### UIT-GmbH WR-iot-compact water level sensor

* 2023-05-10: Changes according to DB_Bsp_LoRa-Settings-Auslieferungszustand_deu.pdf
* 2023-05-09: added message_type 0x10 and 0x11
* 2021-10-08: Initial implementation.

### DFM-Bodenfeuchte-Profilsonde

* 2024-03-09: Initial implementation according to "UP_DFM_Profilsonden.pdf"

### Ursalink AM100/102 and Milesight AM104/AM107

* 2020-12-10: Initial version for payload structure v1.2

### Ursalink UC11-T1 Temperature

* 2020-04-27: Initial version for payload structure v1.4

### Vega-Absolute GM-2

* 2022-08-08: Initial version according to 01-VEGA GM-2 UM_rev 06

### VEGA M-BUS 1

* 2021-11-18: NOT YET READY!!!

### Vega MBus Bridge

* 2022-05-16: Initial version

### VEGAPULS Air 41 and 42

* 2024-11-08: Added possibility to add an offset via profiles when unit is given by device, fixed typo in field name
* 2023-11-24: Added support for packet types 12
* 2023-10-29: Added support for vega air 23 and packet types 8,9,16,17
* 2023-02-20: Added possibility to add an offset via profiles
* 2021-11-17: Updated implementation according to "Betriebsanleitung_VEGAPULS Air 42.pdf", handling GPS error values.
* 2021-03-01: Initial implementation according to "Betriebsanleitung_VEGAPULS Air 41.pdf"

### Vistron RLS100

* 2025-06-02: Removed scaling due to manufacturer hint.
* 2025-04-10: Initial version according to RLS100_Integration Guide_FUOTA.pdf

### Von Roll Klappe mit Tell, fireplug lid sensor

* 2024-11-07: Initial implementation according to "190116_Application_Layer_Alert_Data_Specification.pdf" provided by Von Roll

### Wehrle Wecount-S

* 2023-06-22: Initial implementation according to "Radio-Telegram_LoRa_WECOUNT-S_Payload_0.3.4_20221121.xlsx"

### TDW2/LDW2

* 2022-07-15: Updated to  payload version: V1.3
* 2022-07-12: Updated to  payload version: V1.2
* 2022-06-22: Updated to version TDW2/LDW2 v0.8 and payload version: V1.1
* 2021-08-31: Initial version

### Wika Netris 1

* 2025-05-28: Initial implementation according to "sd_netris1_lpwan_en_co.pdf"

### PEU-20/21

* 2024-04-21: Initial implementation according to "sd_LPWAN_PEU_20_PEU_21.pdf".

### PEW-1000

* 2024-02-12: Initial implementation according to "sd_pew_1000_en.pdf".

### PEW-1000 mioty

* 2025-04-17: Initial implementation according to "sd_pew_1000_en.co.pdf".

### PGW23.100.11

* 2024-10-08: Added Gauge values to 0x01 and 0x02 payloads in of existing min/max values in profile
* 2023-04-21: Initial implementation according to "sd_pgw23_100_en.pdf".

### wio  FieldTester

* 2023-12-12: Initial implementation

### WMBus Driver Packet Parser

* 2022-10-27: Added config option skip_invalid_data with default: false
* 2022-02-04: Parsing all message_content and data inside.
* 2021-06-01: Added extend_reading/2 callback
* 2020-11-04: Initial version.

### Xignal Mouse/Rat Trap

* 2019-05-08: Initial implementation.

### Xter Connect people counter

* 2020-07-23: Initial implementation according to "Payload spec command V203.pdf"

### yabby GPS tracker

* 2019-09-06: Added parsing catchall for unknown payloads.
* 2019-05-13: Initial implementation according to "Yabby_LoRaWAN_Integration_1.3.pdf", provided by ZENNER Connect

### Yokogawa Sushi Sensor

* 2021-04-22: Initial implementation according to "IM01W06E01-11EN_001.pdf"

### ZENNER Smoke Detector D1722

* 2023-08-29: Fixed firmware_version, added device_identity.
* 2022-03-10: Added extend_reading. Added status_summary bitmap for SP9.1 packets.
* 2021-08-25: Added german Field-Display Names
* 2021-04-28: Added AP 0x19 "smoke_alarm_released" for scenario 206.
* 2019-07-04: implement SP0.1
* 2019-07-02: implement SP2.1

### ZENNER T&H Sensor D1801

* 2024-04-19: Added signed to temperatures in sp SP12_3 packets.
* 2023-11-28: Corrected sp SP12_3 packets
* 2023-10-25: Added dew point calculation and SP12_3.
* 2020-02-27: Parsing Packets SP50, SP92 and SP93 too.
* 2020-02-10: Initial implementation according to "D1801-TH-Sensor-LoRa-userguide.pdf"

### ZENNER Water Meter

* 2022-02-04: Added do_extend_reading()
* 2019-07-05: Added obis_code() configuration.
* 2018-05-22: Added parsing for status bytes {9,1},{9,2}; added parsing of date and time
* 2018-04-26: Added fields(), tests() and value_m3

### Binary MBus

* 2024-12-11: Added zeropadding zu checksum
* 2022-05-18: Initial version. Supporting Long frame with variable data structure

### Binary MBus with Lib

* 2024-12-11: Added zeropadding zu checksum
* 2024-07-18: Initial version. Using wMBus Lib

### Binary wMBus

* 2025-06-05: Initial version. Using wMBus Lib

### ZENNER IoT Oskar v2 smart waste ultrasonic sensor

* 2019-04-04: Added tests, updated fields
* 2019-04-04: Initial version.

### ZIS Oskar 1.0

* 2019-05-09: Added tests/0 and fields/0. Defining unit in fields/0. Refactored parse functions.

### ZIS DigitalInputSurveillance 8

* 2019-09-06: Added parsing catchall for unknown payloads.

### ZENNER International Gridbox

* 2023-04-27: Initial implementation according to "LoRaWAN_Payload_ecolyze_2023-03-21.pdf"

### ZRI Simple EDC and PDC

* 2022-03-02: Fix date calculation in SP4/8
* 2021-07-15: Fixed tests and formatting.
* 2021-07-14: Added ways to extend readings and set defaults
* 2021-03-28: Added EDC status summary and AP1
* 2021-01-10: Initial version

### ZRI Simple EDC and PDC

* 2021-01-10: Initial version

### ZENNER Water Meters

* 2021-08-19: Added support for SP12.
* 2019-09-06: Added parsing catchall for unknown payloads
* 2018-04-26: Added fields(), tests() and value_m3

### ZENNER Multiparser (EDC, EHKV, PDC and WMZ)

* 2025-05-21: Moved Port 0 packets from readings to logger, added code 1D to AP1.
* 2025-05-20: Removed unused channel from SP6 and SP7 when wmz configured as single channel.
* 2025-02-13: Added a mapping for din_number manufacturer "{SI" to "ZRI".
* 2025-01-20: Improve timeshift for SP12
* 2024-07-30: Added v7.2.5 workaround for average temperature in SP0.1 package for wmz devices. Also firmware version is now written to the profile.
* 2024-05-27: Fixed status code "backflow" (0F) and broken AP1 timestamps from IUW.
* 2024-04-24: Added profile field din_number2 used by PDC devices. Added config.ignore_din_numbers with EDC/PDC default din_number values.
* 2024-02-05: Added config.overwrite_profile=false. Handling packets with empty payload or frame_port=0.
* 2023-11-27: Fixed SP9.2 and SP9.3 of IUW devices. Added field data.device_summary_type.
* 2023-06-27: Added AP status code 0x0D dry, 0x0E frost and 0x0F backflow.
* 2023-02-24: Added config/profile field 'sp12_strategy' with default `multiple_readings`.
* 2023-02-23: Corrected handling in SP12 packets around midnight. Using "Etc/UTC+1" as default_timezone.
* 2023-02-17: Fixed a bug in parse_fw_version incorrectly detecting EHKV devices.
* 2023-01-03: Added skipping duplicate next to resend payloads.
* 2022-12-29: Added config.ignore_duplicate_up_frames=false, for skipping exact previous payloads.
* 2022-11-25: Renaming display names for the return temperature fields.
* 2022-11-18: Renaming fields for SP5/6 from daily_*/monthly_* to just * (e.g. heating instead of daily_heating)
* 2022-11-03: Added row diagnostic_seconds. Removed changeable units from fields() definition.
* 2022-08-24: Fixed calculation of average values in SP0 packets.
* 2022-07-22: Not updating existing profile keys, so values from SP9.2 and SP9.3 packets can be modified.
* 2022-04-01: Using reparsing_strategy=sequential, enabling profile writes using reparsing (from SP9.2 and SP9.3 packets).
* 2022-02-16: Allow for more clock drift when calculation time of measurement (up to half for period)
* 2021-11-30: Ignoring non binary payloads.
* 2021-11-17: Fixed EDC SP12 channel. Added writing din_number to zri_device profile and all succeeding readings.
* 2021-10-21: Added IUW device_type and VIF 0x75 manufacturer-specific for channel0 of NDC.
* 2021-10-07: Added config write_profile=true. Added all missing field definitions. Added do_extend_fields().
* 2021-07-13: Fix SP12.
* 2021-06-23: Added handling of fabrication_number = 0xFFFFFFFF.
* 2020-11-23: Added profile field "meter_id" as string. Adding meter_id to all readings if available in existing profile.
* 2020-10-27: Bugfix: Writing only strings to profile fields, not atoms.
* 2020-10-16: Added meta as second parameter to do_extend_reading()
* 2020-09-10: Fixed device_type handling in SP9.2. Refactored some profile functions
* 2020-09-02: Added testable configuration.
* 2020-06-22: Handling datetimes with ambiguous timezone information.
* 2020-05-12: Refactorings, fixed timing problems, improved documentation and error handling.
* 2020-04-15: Added do_extend_reading/1 for adding more fields to readings if needed.
* 2020-02-06: Fix middle-of-month problems. Added field definitions.
* 2019-11-27: Fix timezone problems. Add a workaround for ehkv devices not being recognized due to a fw bug. Changed naming for C5 fields.
* 2019-11-18: Workaround for profile information being deleted.
* 2019-09-19: Ignore SP9.3 of unconfigured devices. Fixed average calculation. Only compare with same DiagnosticCycleInterval
* 2019-09-16: Switched return temperatures in SP0.1. Added avg values for C5 SP0.1 packets.
* 2019-09-02: Implemented workaround for wrong subtype in SP12 packets of earlier :edc devices.
* 2019-08-08: Added SP12.
* 2019-07-23: Fix endianness in SP0.1 packet and status_summary for wmz devices.
* 2019-07-19: Add device_type with SP9.2 instead of using the fabrication_block in SP9.3.
* 2019-07-18: Add status summary parsing for ZENNER wmz devices
* 2019-07-16: Fix din number creation. Readable Device Identity
* 2019-07-08: Fix avg/max temperature calculation for SP0.1.
* 2019-05-27: Add functionality for the C5 HeatCoolingMeter. Refactor the parser.
* 2019-01-01: Initial version

### ZRI CO2

* 2022-01-01: Initial version

