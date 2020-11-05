defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # ELEMENT IoT Parser for parsing WMBus packets created by WMBus bridge driver.
  #
  # A device using the WMBus bridge driver will create decoded packets with JSON payload.
  # This parser can be used to extract readings from that JSON data.
  #
  # By default readings with values will be created using this naming format:
  #   {memory_address}_{sub_device}_{tariff}_{description}_{function_field} = value
  #
  # If unit is available, this format is used:
  #   {memory_address}_{sub_device}_{tariff}_{description}_{function_field}_{unit} = value
  #
  # To use a own schema, modify the `key_naming_format` function.
  #
  # How to use the WMBus bridge:
  #   https://docs.element-iot.com/userguide/howto/de/treiber/wmbus_bridge/
  #
  # Changelog
  #   2020-11-04 [jb]: Initial version.
  #

  # Return a string that will be used as key for that value, or `nil` if value should be dropped.
  defp key_naming_format(memory_address, sub_device, tariff, function_field, description, unit) do
    description = String.replace(description, " ", "_")
    case to_string(unit) do
      "" ->"#{memory_address}_#{sub_device}_#{tariff}_#{description}_#{function_field}"
      _ -> "#{memory_address}_#{sub_device}_#{tariff}_#{description}_#{function_field}_#{unit}"
    end
  end

  def parse(%{"c_function_code" => "SND-NR", "message_content" => [%{"data" => data} | _]}, _meta) when is_list(data) do
    Enum.reduce(data, %{}, &Map.merge(&2, extract_value(&1)))
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  # Needs to return a map with key => value pairs.
  defp extract_value(%{"data" => %{"desc" => "message number", "unit" => _, "value" => _}}) do
    %{} # ignore message numbers
  end
  defp extract_value(%{
    "memory_address" => ma, "sub_device" => sd,
    "tariff" => t, "function_field" => ff,
    "data" => %{"desc" => desc, "unit" => unit, "value" => value}
  }) do
    case key_naming_format(ma, sd, t, ff, desc, unit) do
      nil -> %{}
      key -> %{key => value}
    end
  end
  defp extract_value(_) do
    %{} # Ignoring invalid format
  end

  def tests() do
    payload_json = """
      {
        "version": 66,
        "message_content": [
          {
            "version": 66,
            "status": "00",
            "modus": 7,
            "messsage_type_text": "Mbus, long header (72h)",
            "message_type": "72",
            "manufacturer": "ITU",
            "device_type": "Water",
            "data": [
              {
                "tariff": 0,
                "sub_device": 0,
                "memory_address": 0,
                "function_field": "current_value",
                "din_address": "8ITU4200018454",
                "data": {
                  "value": 4.787,
                  "unit": "m³",
                  "desc": "volume"
                }
              }
            ],
            "address": "00018454",
            "acc": 242
          }
        ],
        "manufacturer": "ITU",
        "length": 59,
        "device_type": "RF_Adapter",
        "c_function_code": "SND-NR",
        "address": "00018454"
      }
      """

    [
      {
        :parse_json,
        payload_json,
        %{},
        %{"0_0_0_volume_current_value_m³" => 4.787}
      },

      {
        :parse,
        %{
          "version" => 36,
          "message_content" => [
            %{
              "status" => "00",
              "modus" => 5,
              "messsage_type_text" => "Mbus, short header (7Ah)",
              "message_type" => "7A",
              "data" => [
                %{
                  "tariff" => 0,
                  "sub_device" => 0,
                  "memory_address" => 0,
                  "function_field" => "current_value",
                  "data" => %{
                    "value" => -105,
                    "unit" => "",
                    "desc" => "message_number"
                  }
                },
                %{
                  "tariff" => 0,
                  "sub_device" => 0,
                  "memory_address" => 0,
                  "function_field" => "current_value",
                  "data" => %{
                    "value" => 372.141,
                    "unit" => "m³",
                    "desc" => "volume"
                  }
                },
                %{
                  "tariff" => 0,
                  "sub_device" => 0,
                  "memory_address" => 1,
                  "function_field" => "error_value",
                  "data" => %{
                    "value" => 0,
                    "unit" => "m³",
                    "desc" => "volume"
                  }
                },
                %{
                  "tariff" => 1,
                  "sub_device" => 0,
                  "memory_address" => 1,
                  "function_field" => "error_value",
                  "data" => %{
                    "value" => 0,
                    "unit" => "m³",
                    "desc" => "volume"
                  }
                },
                %{
                  "tariff" => 2,
                  "sub_device" => 0,
                  "memory_address" => 1,
                  "function_field" => "error_value",
                  "data" => %{
                    "value" => 0,
                    "unit" => "m³",
                    "desc" => "volume"
                  }
                },
                %{
                  "tariff" => 0,
                  "sub_device" => 0,
                  "memory_address" => 1,
                  "function_field" => "error_value",
                  "data" => %{
                    "value" => "invalid date %{2000, 0, 0}",
                    "unit" => "",
                    "desc" => "date"
                  }
                },
                %{
                  "tariff" => 0,
                  "sub_device" => 0,
                  "memory_address" => 0,
                  "function_field" => "current_value",
                  "data" => %{
                    "value" => 0,
                    "unit" => "m³/h",
                    "desc" => "flow"
                  }
                },
                %{
                  "tariff" => 0,
                  "sub_device" => 0,
                  "memory_address" => 0,
                  "function_field" => "current_value",
                  "data" => %{
                    "value" => 4814,
                    "unit" => "days",
                    "desc" => "battery_remaining"
                  }
                },
                %{
                  "tariff" => 0,
                  "sub_device" => 0,
                  "memory_address" => 0,
                  "function_field" => "current_value",
                  "data" => %{
                    "value" => 17.7,
                    "unit" => "°C",
                    "desc" => "supply_temperature"
                  }
                },
                %{
                  "tariff" => 0,
                  "sub_device" => 0,
                  "memory_address" => 3,
                  "function_field" => "current_value",
                  "data" => %{
                    "value" => "2019-07-31T23:59:00",
                    "unit" => "",
                    "desc" => "datetime"
                  }
                },
                %{
                  "tariff" => 0,
                  "sub_device" => 0,
                  "memory_address" => 3,
                  "function_field" => "current_value",
                  "data" => %{
                    "value" => 297.876,
                    "unit" => "m³",
                    "desc" => "volume"
                  }
                },
                %{
                  "tariff" => 0,
                  "sub_device" => 0,
                  "memory_address" => 0,
                  "function_field" => "current_value",
                  "data" => %{
                    "value" => 748,
                    "unit" => "",
                    "desc" => "address"
                  }
                }
              ],
              "acc" => 233
            }
          ],
          "manufacturer" => "HYD",
          "length" => 94,
          "device_type" => "Water",
          "c_function_code" => "SND-NR",
          "address" => "64227825"
        },
        %{},
        %{
          "0_0_0_address_current_value" => 748,
          "0_0_0_battery_remaining_current_value_days" => 4814,
          "0_0_0_flow_current_value_m³/h" => 0,
          "0_0_0_message_number_current_value" => -105,
          "0_0_0_supply_temperature_current_value_°C" => 17.7,
          "0_0_0_volume_current_value_m³" => 372.141,
          "1_0_0_date_error_value" => "invalid date %{2000, 0, 0}",
          "1_0_0_volume_error_value_m³" => 0,
          "1_0_1_volume_error_value_m³" => 0,
          "1_0_2_volume_error_value_m³" => 0,
          "3_0_0_datetime_current_value" => "2019-07-31T23:59:00",
          "3_0_0_volume_current_value_m³" => 297.876
        }
      },
    ]
  end

end
