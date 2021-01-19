# Parsers for Sensors on ELEMENT

[![Build Status](https://travis-ci.org/ZennerIoT/element-parsers.svg?branch=master)](https://travis-ci.org/ZennerIoT/element-parsers)

This repository contains Elixir code templates for IoT devices such as sensors to be used on the [ELEMENT](https://element-iot.com) platform provided by [ZENNER IoT Solutions](https://zenner-iot.com/).

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


## Public Parsers for LoRaWAN Devices

A list of parser for devices we already integrated in ELEMENT IoT Platform.

Device Name | Parser File
------------|-------------
abeeway Industrial Tracker | [lib/abeeway_industrial_tracker.ex](lib/abeeway_industrial_tracker.ex)
ADEUNIS ARF8046 | [lib/adeunis_arf8046.ex](lib/adeunis_arf8046.ex)
ADEUNIS ARF8170BA | [lib/adeunis_arf8170ba.ex](lib/adeunis_arf8170ba.ex)
ADEUNIS ARF8200AA | [lib/adeunis_arf8200aa.ex](lib/adeunis_arf8200aa.ex)
ADEUNIS ARF8230AA | [lib/adeunis_arf8230aa.ex](lib/adeunis_arf8230aa.ex)
ADEUNIS FIELD TEST DEVICE LORAWAN ARF8123AA EU868 | [lib/adeunis_ftd.ex](lib/adeunis_ftd.ex)
ADEUNIS TEMP ARF8180BA | [lib/adeunis_temp.ex](lib/adeunis_temp.ex)
ASCOEL LoRaWan Magnetic Contact Sensor CM868LR (Temperature/Humidity) | [lib/ascoel_cm868lmrth.ex](lib/ascoel_cm868lmrth.ex)
ASCOEL LoRaWan Magnetic Contact Sensor CM868LR | [lib/ascoel_cm868lr.ex](lib/ascoel_cm868lr.ex)
ASCOEL LoRaWAN Pyroelectric Motion Sensor | [lib/ascoel_ir868lr.ex](lib/ascoel_ir868lr.ex)
ATIM Metering Dry Contacts| [lib/atim_metering_dry_contacts.ex](lib/atim_metering_dry_contacts.ex)
Axioma Qalcosonic water meter | [lib/axioma_qalcosonic.ex](lib/axioma_qalcosonic.ex)
BOSCH Park Sensor | [lib/bosch_parksensor.ex](lib/bosch_parksensor.ex)
Cayenne LPP | [lib/cayenne_lpp.ex](lib/cayenne_lpp.ex)
Comtac DALI Bridge | [lib/comtac_dali-bridge.ex](lib/comtac_dali-bridge.ex)
Comtac Temperature and Humidity Sensor | [lib/comtac_lpn-cm-1.ex](lib/comtac_lpn-cm-1.ex)
Comtac LPN CM-4 | [lib/comtac_lpn-cm-4.ex](lib/comtac_lpn-cm-4.ex)
Comtac LPN DI | [lib/comtac_lpn-di.ex](lib/comtac_lpn-di.ex)
Comtac LPN Modbus easy SW | [lib/comtac_lpn-modbus-easy-bridge_template.ex](lib/comtac_lpn-modbus-easy-bridge_template.ex)
Comtac KLAX | [lib/comtac_klax.ex](lib/comtac_klax.ex)
Conbee HybridTag L300 | [lib/conbee_hybdridtag_l300.ex](lib/conbee_hybdridtag_l300.ex)
Decentlab DL-PR26 | [lib/decentlab_dl_pr26.ex](lib/decentlab_dl_pr26.ex)
Decentlab DL-MBX | [lib/decentlab_dl_mbx.ex](lib/decentlab_dl_mbx.ex)
Decentlab DL-TRS12 | [lib/decentlab_dl_trs12.ex](lib/decentlab_dl_trs12.ex)
DZG IVU LoRaMOD Bridge | [lib/dzg_loramod.ex](lib/dzg_loramod.ex)
DZG IVU LoRaMOD Bridge v2 | [lib/dzg_loramod-v2.ex](lib/dzg_loramod-v2.ex)
EasyMeter ESYS-LR10 | [lib/easymeter_esys_lr10.ex](lib/easymeter_esys_lr10.ex)
ELEMENT WMBus Bridge Driver | [lib/element_wmbus_bridge_driver.ex](lib/element_wmbus_bridge_driver.ex)
ELSYS Multiparser | [lib/elsys.ex](lib/elsys.ex)
elvaco CMa11L | [lib/elvaco_cma11l.ex](lib/elvaco_cma11l.ex)
elvaco CMi4110  | [lib/elvaco_cmi4110.ex](lib/elvaco_cmi4110.ex)
E-Meter | [lib/e-meter.ex](lib/e-meter.ex)
eBZ | [lib/ebz.ex](lib/ebz.ex)
eBZ v2 | [lib/ebz_v2.ex](lib/ebz_v2.ex)
GlobalSat LT-100 Series Tracker | [lib/globalsat_tracker.ex](lib/globalsat_tracker.ex)
GlobalSat LS-11xP indoor climate monitor | [lib/globalsat_LS-11xP.ex](lib/globalsat_LS-11xP.ex)
Gupsy Temperature and Humidity Sensor | [lib/gupsy_th.ex](lib/gupsy_th.ex)
GWF Meter Pulse Bridge | [lib/gwf_meter.ex](lib/gwf_meter.ex)
Holley Power Meter | [lib/holley_e-meter.ex](lib/holley_e-meter.ex)
Libelium Smart Agriculture | [lib/libelium_smart-agriculture.ex](lib/libelium_smart-agriculture.ex)
Libelium Smart Cities | [lib/libelium_smart-cities.ex](lib/libelium_smart-cities.ex)
Libelium Smart Environment | [lib/libelium_smart-environment.ex](lib/libelium_smart-environment.ex)
Libelium Smart Parking Sensor v3 | [lib/libelium_smart-parking_v3.ex](lib/libelium_smart-parking_v3.ex)
Libelium Smart Water | [lib/libelium_smart-water.ex](lib/libelium_smart-water.ex)
Lobaro Environment | [lib/lobaro_environmental.ex](lib/lobaro_environmental.ex)
Lobaro GPS Tracker | [lib/lobaro_gps-tracker.ex](lib/lobaro_gps-tracker.ex)
Lobaro Pressure 26D | [lib/lobaro_pressure26d.ex](lib/lobaro_pressure26d.ex)
Lobaro Oskar v2 | [lib/lobaro_oskar_v2.ex](lib/lobaro_oskar_v2.ex)
NAS CM3010 | [lib/nas_cm3010.ex](lib/nas_cm3010.ex)
NAS CM3020 | [lib/nas_cm3020.ex](lib/nas_cm3020.ex)
NAS CM3030 | [lib/nas_cm3030.ex](lib/nas_cm3030.ex)
NAS CM3060 | [lib/nas_cm3060.ex](lib/nas_cm3060.ex)
NAS CM3061 | [lib/nas_cm3061.ex](lib/nas_cm3061.ex)
NAS Luminaire Controller Zhaga 18 | [lib/nas_luminaire.ex](lib/nas_luminaire.ex)
NAS UM3023A/UM3033A Digital Pulse Counter | [lib/nas_um30x3.ex](lib/nas_um30x3.ex)
NetOP Technology Devices | [lib/netop.ex](lib/netop.ex)
Netvox Multiparser | [lib/netvox_multiparser.ex](lib/netvox_multiparser.ex)
Nexelec D678C | [lib/nexelec_d678c.ex](lib/nexelec_d678c.ex)
NKE Watteco Clos'O | [lib/nke_closo.ex](lib/nke_closo.ex)
NKE Watteco IN'O | [lib/nke_ino.ex](lib/nke_ino.ex)
NKE Watteco Remote Temperature | [lib/nke_remote_temperature.ex](lib/nke_remote_temperature.ex)
NKE Watteco Smart Plug | [lib/nke_smart_plug.ex](lib/nke_smart_plug.ex)
Parametric PCR2 Radar People Flow sensor | [lib/parametric_pcr2.ex](lib/parametric_pcr2.ex)
Parametric TCR Radar Traffic Counter | [lib/parametric_tcr.ex](lib/parametric_tcr.ex)
PNI PlacePods | [lib/pni_placepods.ex](lib/pni_placepods.ex)
RAK Button | [lib/rak_button.ex](lib/rak_button.ex)
RFI Remote Power Switch | [lib/rfi_remote-power-switch.ex](lib/rfi_remote-power-switch.ex)
Sagemcom Siconia | [lib/sagemcom_siconia.ex](lib/sagemcom_siconia.ex)
Sensative Strips Comfort | [lib/sensative_strips.ex](lib/sensative_strips.ex)
Sensing Labs SenLab LED | [lib/sensinglabs_senlabm.ex](lib/sensinglabs_senlabm.ex)
Strega Smartvalve| [lib/strega_smartvalve.ex](lib/strega_smartvalve.ex)
Smilio Action| [lib/smilio_action_fw_2_0.ex](lib/smilio_action_fw_2_0.ex)
Sontex 79 Heat| [lib/sontext_7x9_heat.ex](lib/sontext_7x9_heat.ex)
Swisslogix Ymatron SLX 1307| [lib/swisslogix_ymatron_fill-level-sensor_slx-1307.ex](lib/swisslogix_ymatron_fill-level-sensor_slx-1307.ex)
Tabs "All in One" | [lib/tabs.ex](lib/tabs.ex)
Tekelek 766 RF | [lib/tekelek_766_rf.ex](lib/tekelek_766_rf.ex)
Tektelic "Industrial GPS Asset Tracker" | [lib/tektelic_industrial_gps_asset_tracker.ex](lib/tektelic_industrial_gps_asset_tracker.ex)
Tektelic "Kona Home Sensor" | [lib/tektelic_kona_home_sensor.ex](lib/tektelic_kona_home_sensor.ex)
Ursalink UC11-T1 | [lib/ursalink_uc11-t1.ex](lib/ursalink_uc11-t1.ex)
Xter Connect | [lib/xter_connect.ex](lib/xter_connect.ex)
yabby GPS | [lib/yabby_gps.ex](lib/yabby_gps.ex)
ZENNER Water Meter (v1.9) | [lib/zenner_water-meter.ex](lib/zenner_water-meter.ex)
ZIS DHT22 Digital Temperature and Humidity Sensor Module | [lib/zis_dht-22.ex](lib/zis_dht-22.ex)
ZIS SmartWaste UltraSonic | [lib/zis_smart-waste-ultrasonic.ex](lib/zis_smart-waste-ultrasonic.ex)
ZIS ZISDIS 8 | [lib/zis_zisdis8.ex](lib/zis_zisdis8.ex)

Your device is missing? Contact us at: [https://zenner-iot.com/page/kontakt/](https://zenner-iot.com/page/kontakt/)

## Internal Parsers

These parsers are available on request.

Last Change | Parser Name
------------|-------------
2020-07-08 | Adeunis ARF8180
2019-03-20 | Adeunis ARF8230
2020-12-14 | Adeunis ARF8240
2020-10-06 | Arad MODBUS
2020-11-20 | Ascoel CO868LR / TH868LR
2020-11-11 | BESA M-BUS-1
2019-01-01 | Binando Binsonic
2019-09-19 | BOSCH Traci
2020-12-16 | Clevabit Protocol
2020-11-19 | Clevercity Greenbox
2019-05-15 | Comtac E1323-MS3
2019-01-01 | Comtac E1360-MS3
2019-11-12 | Comtac E1374
2020-01-30 | Comtac KLAX Modbus
2020-01-29 | Comtac KLAX SML
2020-09-10 | Diehl HRLGc G3 Water Meter
2019-08-26 | Diehl OMS
2020-12-02 | Dragino distance sensor
2020-01-01 | Dragino LHT65
2020-12-22 | Dragino LSE01 Soil Sensor
2020-12-22 | Dragino LSN50
2021-01-17 | DZG Node
2021-01-17 | DZG Node
2019-01-01 | Fludia FM430
2019-01-01 | Holley Meter
2020-12-10 | Imbuildings People Counter
2020-11-30 | Innotas LoRa Pulse
2020-11-25 | Innotas LoRa EHKV
2020-11-25 | Innotas LoRa Water Meter
2021-01-11 | Itron Cyble5
2020-11-16 | Keller
2020-12-16 | Kerlink Wanesy Wave
2020-10-06 | Lancier Pipesense
2020-01-01 | Lobaro Modbus Bridge (HTTP)
2018-01-01 | Lobaro Oscar smart waste ultrasonic sensor
2020-07-27 | Lobaro WMBus Bridge
2019-03-07 | LPP Cayenne
2020-12-11 | Mutelcor MTC-PB01 / MTC-CO2-01
2020-11-23 | NKE Watteco Pulse Sens'O
2020-03-26 | PaulWegener Datenlogger
2020-07-06 | Pepperl+Fuchs WILSEN.sonic.level
2019-05-16 | Sensingslabs Multisensor
2019-10-16 | SensoNeo Quatro Sensor
2020-12-10 | SensoNeo Single Sensor
2020-11-17 | Sentinum APOLLON-Q
2021-01-19 | SoilNet LoRa (Jülich Forschungszentrum)
2019-03-28 | Swisslogix/YMATRON SLX-1307
2019-06-25 | Tecyard Multiparser
2019-06-04 | Tecyard RattenSchockSender
2020-11-09 | TEKTELIC Agriculture
2020-10-29 | Tetraedre
2020-12-10 | Ursalink AM100/102 and Milesight AM104/AM107
2019-05-08 | Xignal Mouse/Rat Trap
2019-07-04 | ZENNER Smoke Detector D1722
2020-02-27 | ZENNER T&H Sensor D1801
2019-07-05 | ZENNER Water Meter
2021-01-10 | ZRI Simple EDC and PDC
2020-11-23 | ZENNER Multiparser (EDC, EHKV, PDC and WMZ)
