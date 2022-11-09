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

### Adeunis ARF8230AA

* 2021-10-29: Rewrite of parser supporting all flags and newest payload version.
* 2021-01-05: Added support for App Version 2.0 with prepended timestamp.
* 2020-11-24: Added extend_reading with start and impulse extension from profile.
* 2019-09-06: Added parsing catchall for unknown payloads.

### Adeunis ARF8230

* 2022-08-17: Recognizing frame types periodic_channel_a/b, added fields, formatting.
* 2019-03-20: Initial Implementation.

### Adeunis ARF8240

* 2021-11-30: Updated parser according to real device values.
* 2020-12-14: Initial implementation according to "MODBUS_LoRaWAN_868_V2.0.0..pdf".

### Aquametro Aquastream

* 2022-09-15: Initial implementation according to "aquastream 9-730-PT-DE-03.pdf"
* 2022-09-27: Corrected parser according to vendor description

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

### ATIM Metering and Dry Contact DIND160/80/88/44

* 2020-06-23: Added feature :append_last_digital_inputs default: false
* 2020-06-18: Initial implementation according to "ATIM_ACW-DIND160-80-88-44_UG_EN_V1.7.pdf"

### Axioma Qalcosonic F1 - 24h mode (or Honeywell Elster)

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

### BARANI DESIGN MeteoWind IoT

* 2021-10-20: added sensor error or sensor n/a
* 2021-10-19: Initial implementation according to "https://www.baranidesign.com/iot-wind-open-message-format"

### BESA M-BUS-1

* 2020-11-11: Initial implementation according to "01-M-BUS-1 UM_rev 12.pdf"

### Binando Binsonic

* 2019-01-01: Initial implementation.

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

### Cayenne LPP Protocol

* 2019-12-02: Initial implementation.

### Clevabit Protocol (DEOS SAM CO2 Ampel)

* 2020-12-16: Initial implementation according to payload version 1.0

### Clevercity Greenbox

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

### Comtac E1310 DALI Bridge

* 2019-09-06: Added parsing catchall for unknown payloads.

### Comtac E1323-MS3

* 2019-05-15: Initial version

### Comtac E1332 LPN Modbus Energy Monitoring Bridge

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

### Comtac KLAX

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

### Comtac KLAX Modbus

* 2020-01-30: Initial Version.

### Comtac KLAX SML

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

### Comtac LPN Modbus easy

* 2019-09-06: Added parsing catchall for unknown payloads.
* 2018-07-18: First implementation.

### Comtac Modbus Bridge Template

* 2022-02-03: Added type "signed16_custom_invert". Interprets incoming bytes (1,2,3,4) as (3,4,1,2) signed.
* 2021-10-28: Added profile support. Use profile: comtac_modbus_bridge_params, with fields reg1, reg2, reg3. If no valid type found, defaulttype is used
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

### de-build.net POWER Gmbh - LoRa Protocol

* 2021-09-22: Added units from profile.
* 2021-03-18: Updated format for port 1 and 2 with splitter symbol. Supporting min/max without channel chars.
* 2021-03-02: Initial implementation according to "Lora Protokoll v1.0.pdf" (14.01.2021)

### DECENTLAB DL-MBX-001/002/003 Ultrasonic Distance Sensor

* 2022-04-20: Filter invalid measurements
* 2020-12-23: Initial implementation

### DECENTLAB DL-PR26 Pressure Sensor

* 2020-03-31: Allowing all device_ids now
* 2019-01-07: Initial implementation for 359=KELLER_I2C_PRESSURE_SENSOR

### Decentlab DL-TRS12 Soil Moisture

* 2019-07-10: Initial version. Code cleanup. Tests.

### DEOS Teo

* 2022-09-05: Increased readability
* 2022-09-01: Initial implementation according to "Datasheet DEOS TEO_de.pdf"

### Diehl HRLGc G3 Water Meter

* 2021-12-13: Added manufacturer error flag flow_persistence_3
* 2020-09-10: Reformatted. Added extend_reading and first tests. Fixed utc_now usage.

### Diehl OMS

* 2019-08-26: Formatted code.
* 2019-03-14: Initial implementation

### DigitalMatter Oyster GPS

* 2022-06-21: Updated according to "Oyster 3 LoRaWAN Integration 1.2.pdf".
* 2021-04-06: Fixed not whitelisted function call.
* 2021-02-09: Initial implementation according to "Oyster LoRaWAN Integration 1.8.pdf".

### Dräger x-Node

* 2022-08-09: Initial implementation according to "Payload Decoder_Basic_Travekom.pdf"

### Dragino LAQ4 Air Quality Sensor

* 2021-10-13: fixed frame port
* 2021-10-12: Initial implementation according to "LAQ4_LoRaWAN_Air_Quality_Manual_v1.1.pdff"

### Dragino distance sensor

* 2020-12-02: Initial implementation according to Dragino - LoRaWAN_LDDS75_User Manual_v1.1

### Dragino LDS01 Door Sensor

* 2021-10-13: fixed frame port and tests + added support for versions 1.3 and lower
* 2021-10-12: Initial implementation according to "LDS01_LoRaWAN_Door_Sensor_UserManual_v1.4.0.pdf"

### Dragino LGT-92 LoRaWAN GPS Tracker

* 2022-06-29: Added config option gps_keep_invalid=false.
* 2021-08-13: Rewrite and updated to latest firmware v1.6.
* 2020-02-12: Initial implementation according to Dragino TTN Parser.

### Dragino LHT65

* 2020-01-01: Added to version control.

### Dragino LLMS01 Leaf Moisture

* 2021-08-25: Initial Implementation according to "LoRaWAN_Leaf_Moisture_Sensor_UserManual_v1.0.pdf"

### Dragino LSE01 Soil Sensor

* 2020-12-22: Initial Implementation according to "LoRaWAN_Soil_Moisture_%26_EC_Sensor_UserManual_v1.3.pdf"

### Dragino LSN50

* 2022-02-11: Supporting Mode 3, using profile `dragino_lsn50` for field `mode`.
* 2021-03-17: Supporting Mode 1 and 4
* 2020-12-22: Initial Implementation according to "LSN50_LoRa_Sensor_Node_UserManual_v1.7.1.pdf"

### Dragino LSNOK01 Soil Fertility Nutrient

* 2021-08-26: Initial Implementation according to "LoRaWAN_Soil_NPK_Sensor_UserManual_v1.0.pdf"

### Dragino LSPH01 Soil PH Sensor

* 2021-08-26: Initial Implementation according to "LoRaWAN_Soil_Ph_Sensor_UserManual_v1.1.pdf"

### Dragino LT22222-L I/O Controller

* 2021-07-14: Added parsing for old payload format v1.3
* 2021-05-18: Initial Implementation according to "LoRa_IO_Controller_UserManual_v1.5.5.pdf"

### Dragino LWL01 Water Leak Sensor

* 2021-10-13: fixed frame ports
* 2021-10-12: fixed spelling and format
* 2021-10-12: Initial implementation according to "LWL01_LoRaWAN_Water_Leak_UserManual_v1.3.1.pdf"

### Dragino LWL02 Water Leak Sensor + LDS02 Door Sensor

* 2022-01-22: fixed format, added support for 9byte Payloads from LWL01
* 2022-01-21: Initial implementation according to "lds01_02_payload_ttn_v1.5.txt" since PL descriptions doesnt fit

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

### Eastron SDM630MCT Electricity Meter

* 2021-08-09: Initial version according to "LineMetricsLoRa-PayloadSpezifikationEastronSDM630MCT-050821-0822.pdf"

### EasyMeter ESYS LR10 LoRaWAN adapter

* 2021-06-14: Updated to new payload format according to "BA_ESYS-LR10_Rev1.3_vorläufig.docx".
* 2020-04-17: Fixes after testing phase.
* 2020-02-03: Initial implementation.

### eBZ electricity meter

* 2020-02-03: MSCONS compatibility and reformatting.
* 2019-05-09: Initial implementation according to "example Payload"

### eBZ electricity meter v2

* 2022-08-25: Added do_extend_reading callback.
* 2020-05-27: Initial implementation of new version

### Elsys Multiparser

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

### Fast-GmbH AZA-OAD-Logger

* 2022-07-05: Made pegel binary part dynamic long.
* 2022-04-08: Initial version.

### Fleximodo GOSPACE Parking

* 2021-07-22: Initial version according to "fleximodo_rawdata-payload-deciphering.pdf"

### Fludia FM430

* 2019-01-01: Initial implementation.

### GLA intec WasteBox

* 2022-10-24: Updated initial version and added profile data.

### Globalsat ls11xp indoor climate monitor

* 2020-01-27: Added taupunkt calculation

### GlobalSat GPS Tracker

* 2019-09-19: Ignoring invalid payloads. Handling missing GPS fix.
* 2019-09-06: Added parsing catchall for unknown payloads.

### Gupsy temperature and humidity sensor

* 2019-09-06: Added parsing catchall for unknown payloads.

### GWF LoRaWAN module for GWF metering units

* 2021-08-17: Added extend_reading function and missing fields.
* 2021-04-15: Using new config() function.
* 2019-07-04: Added support for message type 0x02.
* 2019-05-16: Removed/changed fields (meter_id, manufacturer_id, state). Added interpolation feature. Added obis codes.
* 2018-08-08: Parsing battery and additional function.
* 2018-04-18: Initial version.

### Holley E-Meter

* 2021-04-08: Added new payload format.
* 2019-09-06: Added parsing catchall for unknown payloads.

### Hyquest IoTa Sensornode

* 2022-08-12: Added measurement_ID and value count
* 2022-07-26: Initial implementation according to "HS IoTa LoRa Data Format Guide.pdf"

### Imbuildings People Counter

* 2021-10-12: fixed nameing fields for 13 byte payload.
* 2021-10-04: Updated parser to match payloads with 13 byte payload.
* 2020-12-10: Corrected parser due to faulty payload description
* 2020-12-02: Initial implementation according to "IMBUILDINGS - LoRaWAN People Counter - doc v1.1.pdf" (No real tests possible)

### IMST WMBus Bridge

* 2022-02-02: Better heuristik to find server ids
* 2021-12-28: Added parsing of status messages
* 2021-12-27: Initial implementation.

### Innotas LoRa Pulse

* 2020-11-30: Initial implementation

### Innotas LoRa EHKV

* 2020-11-25: Refactoring
* 2020-11-23: Initial version

### Innotas LoRa Water Meter

* 2020-11-25: Refactoring
* 2019-08-27: Initial version

### Integra Calec ST 3 Meter

* 2022-11-09: Added try catch for handling WmBus errors.
* 2022-09-01: Fixed reading format. Added tests.
* 2021-10-15: Initial implementation according to "CALEC_ST_III_3-140-P-LORA-DE-02.pdf".

### Integra Topas Sonic Water Meter

* 2022-10-13: Using LibWmbus.parse and providing also WMBus header data like address. Added do_extend_reading callback.
* 2022-03-03: Added new payload format according to "Topas Sonic-LW-INTG01 - V0.1.pdf".
* 2021-07-14: Initial implementation according to "Payload Beschreibung Topas Sonic Lora.pdf".

### InterAct - IOT Controller

* 2021-12-16: Added do_extend_reading callback.
* 2021-10-29: Fixed analog raw to mA conversion.
* 2021-09-30: Initial Version, according to "description_IOT_Controller_ruhrverband_v0.1.pdf".

### Itron Cyble5

* 2022-06-24: Fixing measured_at for 3h/6h/12h formats last message.
* 2022-06-22: Handling measured_at for 3h/6h/12h formats.
* 2022-01-19: Added do_extend_reading/2 callback.
* 2021-01-11: Fixed handling of invalid payloads in decrypt().
* 2020-11-04: Fixed handling of negative values in interval DOB, in case of backflow. Added more fields() definitions.
* 2020-08-27: Added DOBJ 150 "FDR 12 Delta S16". Removed OBIS field adding.
* 2020-08-12: Initial implementation according to "Cyble 5 Lora Data decoding v0.5.pdf" and "DOBJ Table.xlsx".

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

### Lancier Monitoring

* 2022-08-18: Added Port 100 message according to "Lancier Monitoring LORA Payload Version 0.1.2"
* 2022-08-18: Initial implementation according to "Lancier Monitoring LORA Payload Version 0.1.1"

### Lancier Pipesense

* 2021-01-22: Updated according to "076264.000-03_12.20_BA_D_PipeSens.pdf"
* 2020-10-06: Initial implementation according to "PipeSensLora payload vorab.pdf"

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

### Lobaro Environmental Sensor

* 2020-01-23: Initial implementation according to "https://docs.lobaro.com/lorawan-sensors/environment-lorawan/index.html" as provided by Lobaro

### Lobaro GPS Tracker

* 2020-12-04: REWRITE of parser with NEW field names. Fixing wrong parsing between versions.
* 2020-11-25: Fixed negative Temperature for v5.0
* 2020-11-04: Added Payload Version 7.0 and 7.1 and disabled output of GPS data of 5.0 version when no sat. is available.
* 2020-01-10: Added Payload Version 5.0.
* 2019-09-06: Added parsing catchall for unknown payloads.

### Lobaro Hybrid Pegelsonde

* 2022-08-02: Initial implementation according to https://doc.lobaro.com/doc/hybrid-nb-iot-+-lora-devices/hybrid-modbus-gateway/sample-implementations

### Lobaro Modbus Bridge v1.0

* 2022-01-13: Added reparsing_strategy: sequential
* 2022-01-11: Fixed add_timestamp to convert all timestamp to DateTime. Added do_extend_reading/2 callback.
* 2021-09-23: Improved handling of splitted Port 5 messages.
* 2021-07-14: Fixed a bug in add_timestamp
* 2021-03-23: Supporting bridge firmware version from v1.0, and verbose format.

### Lobaro Oscar smart waste ultrasonic sensor

* 2018-01-01: Initial implementation

### Lobaro Oskar v2

* 2019-10-04: Initial implementation according documentation provided by Lobaro

### Lobaro Water Level Sensor

* 2022-04-19: added Profile support to calcule water depth and parse status messages on frame_port 64
* 2019-11-21: updating parser according to firmware version 0.1.0
* 2019-05-14: Initial implementation according to "LoRaWAN-Pressure-Manual.pdf" as provided by Lobaro

### Lobaro WMBus Bridge

* 2021-01-22: Updated device_type_to_string list.
* 2020-07-27: Fixed temp, added format 2, added tests, added fields definition.
* 2020-06-30: Current state, added tests.
* 2019-03-14: Initial implementation.

### LPP Cayenne

* 2019-03-07: Initial implementation

### MCF88 Multiparser

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

### MClimate Vicky

* 2022-11-03: Added Payloads starting with 0x28 (reply to commands)
* 2021-12-21: Updated to latest firmware 3.5. Added Command-Code 0x81.
* 2021-08-27: Initial Implementation of keepalive frame according to "MClimate_Vicki_LoRaWAN_Device_Communication_Protocol_1.7.pdf"

### Milesight AM300 Series

* 2021-12-13: Initial implementation according to "am300-series-user-guide-en.pdf"

### Milesight and Ursalink EM300 / EM310-UDL

* 2022-10-10: Added missing Fields for EM310 UDL from "em310-udl-user-guide-en.pdf".
* 2021-02-01: Added undocumented payload part FF0B...
* 2021-01-27: Initial version from em300-series-user-guide-en.pdf

### Milesight and Ursalink EM500

* 2022-04-21: Initial version according to em500-series-communication-protocol-en.pdf

### Milesight and Ursalink UC11xx

* 2021-01-28: Initial version from uc11xx_control_protocol_en.pdf v1.4

### Milesight and Ursalink WS101

* 2022-04-28: Initial version according to ws101-user-guide-en.pdf

### Milesight and Ursalink WS136 & WS156

* 2022-08-12: Initial version according to ws136&ws156-user-guide-en.pdf

### Milesight and Ursalink WS301

* 2022-05-17: Initial version according to ws301-user-guide-en.pdf

### Milesight and Ursalink WS52x

* 2022-09-16: Initial version according to https://github.com/Milesight-IoT/SensorDecoders/tree/master/WS_Series/WS52x

### MIROMICO FMLR IoT Button

* 2021-10-20: Initial implementation according to "Miromico IoT-Button Factsheet (EN).pdf" with given example payloads

### Mutelcor MTC-PB01 / MTC-CO2-01 / MTC-XX-MH01 / MTC-XX-CF01

* 2021-07-01: Added Manhole and Customer Feedback sensor.
* 2020-12-11: Initial version.

### NAS ACM CM3010

* 2019-12-09: Fixed boot message for newer longer payloads.
* 2019-11-15: Handling 32bit usage payload too.
* 2019-08-27: Update parser to v1.3.0; added catchall
* 2018-06-26: Initial implementation according to "Absolute_encoder_communication_module_CM3010.pdf"

### NAS CM3020

* 2019-01-01: Initial implementation according to "https://www.nasys.no/wp-content/uploads/Wehrle_Modularis_module_CM3020_3.pdf"

### NAS CM3030 Cyble Module

* 2019-08-26: Initial version

### NAS CM3060 BK-G Pulse Reader

* 2019-08-26: Initial version

### NAS PULSER BK-G CM3061

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

### NetOp Multiparser

* 2020-10-06: Added support for ambient light sensor (v1.9)
* 2019-05-09: Initial implementation according to v1.8, including door and manhole sensors.

### Netvox Multiparser

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

### nke AtmO

* 2022-09-27: Initial implementation according to https://support.nke-watteco.com/atmo/

### NKE Watteco - Eolane Bob Assistant

* 2021-06-16: Initial implementation according to "BoB_ASSISTANT_Reference_Manual_V1.1.pdf"

### NKE Watteco Clos'O

* 2020-10-15: Initial implementation according to "Clos'O_50-70-108-000_SPG_V0_9 EN _1_.pdf".

### NKE Watteco IN'O

* 2022-03-21: deleted debug messages + named field in Bitmap16
* 2022-03-17: Added support for Node power descriptor
* 2022-03-15: Added support for Bitmap16 attribute_type
* 2019-05-09: Added support for ModBus device.
* 2018-11-19: Renamed fields according to NKE docs, see tests. Added parsing of cmdid, clusterid, attrid, attrtype.
* 2018-09-17: Handling missing fctrl, added fields like "input_2_state" for better historgrams.

### NKE Watteco Intens'O

* 2021-02-11: Made "rp" and "csp" optional at payload ending.
* 2021-02-05: Initial implementation according to "http://support.nke-watteco.com/wp-content/uploads/2019/03/50-70-098_Intenso_User_Guide_1.1_Revised.pdf"

### NKE Watteco Monit'O

* 2022-03-31: Initial implementaion

### NKE Watteco Press'O

* 2022-03-18: Initial implementaion

### NKE Watteco Remote Temp

* 2022-04-08: Updated error handling.
* 2019-11-18: Initial implementation.

### NKE Watteco Pulse Sens'O

* 2020-11-23: Initial implementation according to "http://support.nke-watteco.com/pulsesenso-2/#ApplicativeLayer"

### NKE Watteco Smart Plug

* 2021-05-12: Added heartbeat. Formatted Code.
* 2020-08-20: Added tests, refactoring.
* 2019-01-01: Initial Version.

### Orbiwise noicesensor

* 2022-05-17: fixed calculation with real data
* 2022-05-12: Initial implementation according to provided data via E-Mail

### OXON - Multiparser

* 2022-08-17: Added Buttonboard (FW version 1.2.8) according to "https://www.oxobutton.ch/products/buttonboard-lorawan/documentation#uplink"
* 2021-11-29: Initial implementation of Oxobutton Q according to "https://www.oxobutton.ch/products/oxobutton-lorawan/documentation#uplink"

### Parametric PCR2 People Counter Radar

* 2021-09-07: added pcr2_ods device type 5
* 2021-08-12: fixed the unit of sbx_batt according to https://www.parametric.ch/de/docs/pcr2/pcr2_app_payload_v4
* 2020-10-22: Implemented v4 according to https://parametric.ch/docs/pcr2/pcr2_app_payload_v4
* 2020-07-07: Implemented v3 according to https://parametric.ch/docs/pcr2/pcr2_app_payloads_v3, renamed field temperature to cpu_temp
* 2020-06-09: Initial implementation according to https://parametric.ch/docs/pcr2/pcr2_app_payloads_v2

### Parametric TCR Radar Traffic Counter

* 2021-09-22: Updated implementation according to https://parametric.ch/docs/tcr/tcr_payload_v3
* 2020-09-29: Updated implementation according to https://parametric.ch/docs/tcr/tcr_payload_v2
* 2020-07-07: Initial implementation according to https://parametric.ch/docs/tcr/tcr_payload_v1

### PaulWegener Datenlogger ASCII

* 2020-03-26: Initial implementation according to example payload.

### PaulWegener Datenlogger BINARY

* 2021-12-01: Using little binary value for bytes > 1
* 2021-11-23: Initial implementation according "BA iModem LoRaWAN-1.pdf" from Aug. 2021

### Pepperl+Fuchs WILSEN.sonic.level

* 2021-10-25: Added do_extend_reading/2 Callback
* 2021-10-14: added missing fields
* 2021-05-17: Updated according to Document "tdoct7056__eng.docx", added error handling.
* 2020-07-06: Initial implementation according to Document "TDOCT-6836__GER.docx"

### SSM-AQUO

* 2022-10-07: Initial implementation according to "Radio Payload_SMM-Aquo_v1_20220506.pdf"

### PNI PlacePod parking sensor

* 2021-08-23: Added known mapping for internal channel 5 and 6. Added missing fields(), formatted code.
* 2021-08-11: Parse even with PNI internal data.
* 2021-04-20: Added do_extend_reading/2 and add_bosch_parking_format/1 for Bosch park sensor compatibility.
* 2019-12-10: Initial implementation according to "PNI PlacePod Sensor - Communications Protocol.pdf"

### Polysense - Multiparser

* 2022-10-13: Initial Implementation according to http://pmo4d0f6d.hkpic1.websiteonline.cn/upload/PolysenseWxS8800UserGuide.pdf (13.10.2022)

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

* 2021-08-03: Initial version according to "BA_SlimCom IoT_DE.PDF".

### SenseCAP

* 2021-04-19: Added field for battery + new test
* 2021-04-15: Initial Version. Documentation: https://sensecap-docs.seeed.cc/pdf/SenseCAP%20LoRaWAN%20Sensor%20User%20Manual-V1.1.pdf

### Sensative Strips Comfort

* 2020-07-02: Updated payload to Strips-MsLoRa-DataFrames-3.odt, ignoring frame_port=2 for now.
* 2019-11-05: Fixed order of temperature/humidity in 1.1.17, 1.1.18 and 1.1.19.
* 2019-09-10: Initial implementation according to "Sensative_LoRa-Strips-Manual-Alpha-2.pdf"

### Sensingslabs Multisensor

* 2021-12-09: Fixed current_value_state for senlab D
* 2021-10-29: Added Datalog-Format for Temp/hum
* 2021-09-24: Added SenlabH tests and taupunkt calculation.
* 2021-04-06: Fixed parse functions due to real data
* 2021-03-01: Added Catchall and fixed parse function
* 2019-05-16: Initial implementation

### Sensinglabs SenLab LED

* 2019-09-06: Added parsing catchall for unknown payloads.
* 2019-01-01: Initial implementation.

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

### Sentinum APOLLON-Q

* 2021-10-26: Added do_extend_reading/2 Callback
* 2020-11-17: Initial implementation according to "Apollon_A4_Payload_Beschreibung.pdf"

### Sentinum FEBRIS

* 2021-11-03: Fixed newer minor versions and battery unit.
* 2021-04-30: Fixed temperature and typos.
* 2021-04-20: Initial implementation according to "Febris_A4_Payload_Beschreibung.pdf"

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

* 2022-10-28: Initial Implementation according to LPWAN_truebnerSMT100_EN.pdf (HW Version and SW Version inconsistent with testpayload)

### Sontex Supercal/Superstatic

* 2020-06-26: Using memory_address, sub_device and tariff in reading keys.
* 2020-06-09: Initial implementation according to "M-Bus Frames 7x9 - LoRAWAN_20190812.pdf"

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

### Swisscom LPN Multisense

* 2021-07-07: Added do_extend_reading/2 callback and added field definition.
* 2021-02-25: Allowed payload version up to 2.
* 2021-01-25: Initial version of parser, according to "Multisense_User_Guide-de.pdf" v2 from 02/11/2020

### Swisslogix/YMATRON SLX-1307

* 2019-03-28: Initial version of parser, according to DOC_1074_01_A_InterfaceLoRaFillLevelSensorSLX_1307_V1_1.pdf

### Tecyard Multiparser

* 2019-06-25: return mV instead of V for voltage.
* 2019-06-24: Implement sensors 0x06 to 0x82.
* 2019-06-20: Initial implementation according to "TecyardSensorProtocol-v2_SWKN.xlsx"

### Tecyard RattenSchockSender

* 2019-06-04: Initial implementation according to "RattenSchockSenderHHWasser.pdf"

### Tekelek 766 RF

* 2022-05-18: Added tank.capacity profile field.
* 2021-05-18: Added tank.sensor_distance profile field. Formatted code.
* 2020-01-27: Fixed handling of tank.form profile field.
* 2019-05-22: Read tank height and form from device profile. Calculate fill level depending on form.
* 2018-11-29: Initial version of parser

### TEKTELIC Agriculture

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

### Tetraedre

* 2020-10-29: Initial implementation according to "Proposal of April 30th, 2016. Thierry Schneider, Tetraedre Sarl"

### BROWAN Tabs (formerly TrackNet Tabs)

* 2022-05-17: Fixed calculation mistake on ambient light sensor
* 2021-08-24: Added Sound level Sensor according to "RM_Sound Level Sensor_20200210.pdf".
* 2021-04-21: Updated Healthy Home IAQ Sensor according to "BQW_02_0005.003".
* 2021-03-29: Added Water Leak Sensor from "Tabs Water Leak Datenblatt EN"
* 2020-12-22: Added Ambient Light Sensor from "RM_Ambient light Sensor_20200319 (BQW_02_0008).pdf" and formatted code.
* 2020-09-28: Update battery calculation for new Healthy Home Sensor version
* 2020-09-23: Added support for new Healthy Home Sensor version (with indoor-air-quality)
* 2019-04-04: Initial version, combining 5 TrackNet Tabs devices.

### UIT-GmbH WR-iot-compact water level sensor

* 2021-10-08: Initial implementation.

### Ursalink AM100/102 and Milesight AM104/AM107

* 2020-12-10: Initial version for payload structure v1.2

### Ursalink UC11-T1 Temperature

* 2020-04-27: Initial version for payload structure v1.4

### Vega GM-2

* 2022-08-08: Initial version according to 01-VEGA GM-2 UM_rev 06

### Vega MBus Bridge

* 2022-05-16: Initial version

### VEGAPULS Air 41 and 42

* 2021-11-17: Updated implementation according to "Betriebsanleitung_VEGAPULS Air 42.pdf", handling GPS error values.
* 2021-03-01: Initial implementation according to "Betriebsanleitung_VEGAPULS Air 41.pdf"

### TDW2/LDW2

* 2022-07-15: Updated to  payload version: V1.3
* 2022-07-12: Updated to  payload version: V1.2
* 2022-06-22: Updated to version TDW2/LDW2 v0.8 and payload version: V1.1
* 2021-08-31: Initial version

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

* 2022-03-10: Added extend_reading. Added status_summary bitmap for SP9.1 packets.
* 2021-08-25: Added german Field-Display Names
* 2021-04-28: Added AP 0x19 "smoke_alarm_released" for scenario 206.
* 2019-07-04: implement SP0.1
* 2019-07-02: implement SP2.1

### ZENNER T&H Sensor D1801

* 2020-02-27: Parsing Packets SP50, SP92 and SP93 too.
* 2020-02-10: Initial implementation according to "D1801-TH-Sensor-LoRa-userguide.pdf"

### ZENNER Water Meter

* 2022-02-04: Added do_extend_reading()
* 2019-07-05: Added obis_code() configuration.
* 2018-05-22: Added parsing for status bytes {9,1},{9,2}; added parsing of date and time
* 2018-04-26: Added fields(), tests() and value_m3

### Binary MBus

* 2022-05-18: Initial version. Supporting Long frame with variable data structure

### ZENNER IoT Oskar v2 smart waste ultrasonic sensor

* 2019-04-04: Added tests, updated fields
* 2019-04-04: Initial version.

### ZIS Oskar 1.0

* 2019-05-09: Added tests/0 and fields/0. Defining unit in fields/0. Refactored parse functions.

### ZIS DigitalInputSurveillance 8

* 2019-09-06: Added parsing catchall for unknown payloads.

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

