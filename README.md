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


## Public Parsers for LoRaWAN Devices

A list of parser for devices we already integrated in ELEMENT IoT Platform.

Device Name | Parser File
------------|-------------
ADEUNIS ARF8046 | [lib/adeunis_arf8046.ex](lib/adeunis_arf8046.ex)
ADEUNIS ARF8170BA | [lib/adeunis_arf8170ba.ex](lib/adeunis_arf8170ba.ex)
ADEUNIS ARF8200AA | [lib/adeunis_arf8200aa.ex](lib/adeunis_arf8200aa.ex)
ADEUNIS ARF8230AA | [lib/adeunis_arf8230aa.ex](lib/adeunis_arf8230aa.ex)
ADEUNIS FIELD TEST DEVICE LORAWAN ARF8123AA EU868 | [lib/adeunis_ftd.ex](lib/adeunis_ftd.ex)
ADEUNIS TEMP ARF8180BA | [lib/adeunis_temp.ex](lib/adeunis_temp.ex)
ASCOEL LoRaWan Magnetic Contact Sensor CM868LR (Temperature/Humidity) | [lib/ascoel_cm868lmrth.ex](lib/ascoel_cm868lmrth.ex)
ASCOEL LoRaWan Magnetic Contact Sensor CM868LR | [lib/ascoel_cm868lr.ex](lib/ascoel_cm868lr.ex)
ASCOEL LoRaWAN Pyroelectric Motion Sensor | [lib/ascoel_ir868lr.ex](lib/ascoel_ir868lr.ex)
BOSCH Park Sensor | [lib/bosch_parksensor.exs](lib/bosch_parksensor.exs)
Comtac DALI Bridge | [lib/comtac_dali-bridge.ex](lib/comtac_dali-bridge.ex)
Comtac Temperature and Humidity Sensor | [lib/comtac_lpn-cm-1.ex](lib/comtac_lpn-cm-1.ex)
Comtac LPN Modbus easy SW | [lib/comtac_lpn-modbus-easy-bridge_template.ex](lib/comtac_lpn-modbus-easy-bridge_template.ex)
Comtac LPN DI | [lib/comtac_lpn-di.ex](lib/comtac_lpn-di.ex)
Comtac KLAX | [lib/comtac_klax.ex](lib/comtac_klax.ex)
Conbee HybridTag L300 | [lib/conbee_hybdridtag_l300.ex](lib/conbee_hybdridtag_l300.ex)
Decentlab DL-PR26 | [lib/decentlab_dl_pr26.ex](lib/decentlab_dl_pr26.ex)
DZG IVU LoRaMOD Bridge | [lib/dzg_loramod.ex](lib/dzg_loramod.ex)
DZG IVU LoRaMOD Bridge v2 | [lib/dzg_loramod-v2.ex](lib/dzg_loramod-v2.ex)
ELSYS LoRaWAN Payload v8 | [lib/elsys_v8.ex](lib/elsys_v8.ex)
E-Meter | [lib/e-meter.ex](lib/e-meter.ex)
GlobalSat LT-100 Series Tracker | [lib/globalsat_tracker.ex](lib/globalsat_tracker.ex)
Gupsy Temperature and Humidity Sensor | [lib/gupsy_th.ex](lib/gupsy_th.ex)
GWF Meter Pulse Bridge | [lib/gwf_meter.ex](lib/gwf_meter.ex)
Holley Power Meter | [lib/holley_e-meter.ex](lib/holley_e-meter.ex)
Libelium Smart Agriculture | [lib/libelium_smart-agriculture.ex](lib/libelium_smart-agriculture.ex)
Libelium Smart Cities | [lib/libelium_smart-cities.ex](lib/libelium_smart-cities.ex)
Libelium Smart Environment | [lib/libelium_smart-environment.ex](lib/libelium_smart-environment.ex)
Libelium Smart Parking Sensor v3 | [lib/libelium_smart-parking_v3.exs](lib/libelium_smart-parking_v3.exs)
Libelium Smart Water | [lib/libelium_smart-water.ex](lib/libelium_smart-water.ex)
Lobaro GPS Tracker | [lib/lobaro_gps-tracker.ex](lib/lobaro_gps-tracker.ex)
Lobaro Pressure 26D | [lib/lobaro_pressure26d.ex](lib/lobaro_pressure26d.ex)
Lobaro WMBUS Bridge | [lib/lobaro_wmbus-bridge.ex](lib/lobaro_wmbus-bridge.ex)
NAS CM3010 | [lib/nas_cm3010.ex](lib/nas_cm3010.ex)
NAS Luminaire Controller Zhaga 18 | [lib/nas_luminaire.ex](lib/nas_luminaire.ex)
NAS UM3023A/UM3033A Digital Pulse Counter | [lib/nas_um30x3.ex](lib/nas_um30x3.ex)
NetOP Technology Devices | [lib/netop.ex](lib/netop.ex)
NKE Watteco IN'O | [lib/nke_ino.ex](lib/nke_ino.ex)
RAK Button | [lib/rak_button.ex](lib/rak_button.ex)
Sagemcom Siconia | [lib/sagemcom_siconia.ex](lib/sagemcom_siconia.ex)
Sensing Labs SenLab LED | [lib/sensinglabs_senlabm.ex](lib/sensinglabs_senlabm.ex)
Sensoneo Singlesensors | [lib/sensoneo_singlesensors.ex](lib/sensoneo_singlesensors.ex)
Strega Smartvalve| [lib/strega_smartvalve.ex](lib/strega_smartvalve.ex)
Smilio Action| [lib/smilio_action_fw_2_0.ex](lib/smilio_action_fw_2_0.ex)
Tabs All in One | [lib/tabs.ex](lib/tabs.ex)
Tabs Door and Window Sensor (deprecated) | [lib/tabs_doornwindow.ex](lib/tabs_doornwindow.ex)
Tabs Healthy Home Air Quality Sensor (deprecated) | [lib/tabs_healthy-home.ex](lib/tabs_healthy-home.ex)
Tabs Object locator (deprecated) | [lib/tabs_object-locator.ex](lib/tabs_object-locator.ex)
Tabs Pushbutton (deprecated) | [lib/tabs_pushbutton.ex](lib/tabs_pushbutton.ex)
Tabs Motion (deprecated) | [lib/tabs_motion.ex](lib/tabs_motion.ex)
yabby GPS | [lib/yabby_gps.ex](lib/yabby_gps.ex)
ZENNER Water Meter (v1.9) | [lib/zenner_water-meter.ex](lib/zenner_water-meter.ex)
ZIS DHT22 Digital Temperature and Humidity Sensor Module | [lib/zis_dht-22.ex](lib/zis_dht-22.ex)
ZIS SmartWaste UltraSonic | [lib/zis_smart-waste-ultrasonic.ex](lib/zis_smart-waste-ultrasonic.ex)
ZIS ZISDIS 8 | [lib/zis_zisdis8.ex](lib/zis_zisdis8.ex)

Your device is missing? Contact us at: [https://zenner-iot.com/page/kontakt/](https://zenner-iot.com/page/kontakt/)
