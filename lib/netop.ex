defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # Parser for NetOp technology devices.
  #
  # Latest documentation: http://netop.io/protocol.pdf
  #
  # Changelog:
  #   2019-05-09 [gw]: Initial implementation according to v1.8, including door and manhole sensors.
  #   2020-10-06 [gw]: Added support for ambient light sensor (v1.9)
  #

  # Protocol version 1
  def parse(<<_rfu::5, 1::3, serial_number::32, data_block_plus_checksum::binary>>, %{meta: %{frame_port: 22}}) do
    with {:ok, data, _checksum} <- parse_data_blocks(data_block_plus_checksum) do
      Enum.map(data, &Map.put(&1, :serial_number, serial_number))
    else
      _ -> %{}
    end
  end

  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  def parse_data_blocks(data, result \\ [])
  def parse_data_blocks(<<checksum::binary-1>>, result), do: {:ok, result, checksum}
  def parse_data_blocks(<<>>, result), do: {:ok, result, <<>>}
  def parse_data_blocks(<<data_header::binary-3, data::binary>>, result) do
    with {:ok, parsed_data, rest} <- parse_data(data_header, data) do
      parse_data_blocks(rest, [parsed_data] ++ result)
    end
  end

  # might_have_an_error bit is set
  defp parse_data(<<_contains_timestamp::1, _rfu1::1, _slot_number::3, 1::1, device_information::9, _rfu2::1, sensor_board_type::binary-1>>, data) do
    Logger.error("Potentially invalid data. Device_information: #{inspect device_information} with sensor board type: #{inspect sensor_board_type(sensor_board_type)} and data #{inspect data}")
    {:error, :data_might_have_an_error}
  end

  # device information
  defp parse_data(<<contains_timestamp::1, _rfu1::1, slot_number::3, might_have_error::1, device_information::9, _rfu2::1, 0>>, data) do
    with {:ok, timestamp, rest} <- parse_time_stamp(contains_timestamp, data),
         {:ok, parsed_payload, rest} <- parse_device_information(device_information, rest) do
      parsed_data =
        %{
          slot_number: slot_number,
          might_have_an_error: might_have_error,
        }
        |> Map.merge(timestamp)
        |> Map.merge(parsed_payload)

      {:ok, parsed_data, rest}
    end
  end

  # sensor-function
  defp parse_data(<<contains_timestamp::1, _rfu1::1, slot_number::3, might_have_error::1, sensor_function::9, _rfu2::1, sensor_board_type::binary-1>>, data) do
    with {:ok, timestamp, rest} <- parse_time_stamp(contains_timestamp, data),
         {:ok, parsed_payload, rest} <- parse_sensor_function(sensor_function, rest) do
      parsed_data =
        %{
          might_have_an_error: might_have_error,
          sensor_board_type: sensor_board_type(sensor_board_type),
          slot_number: slot_number,
        }
        |> Map.merge(timestamp)
        |> Map.merge(parsed_payload)

      {:ok, parsed_data, rest}
    end
  end

  # 5.12 Door Opening - Closing Counter Sensor
  defp parse_sensor_function(0x00C, <<opening_counter::16, closing_counter::16, rest::binary>>) do
    {
      :ok,
      %{
        type: :door_counter,
        times_opened: opening_counter,
        times_closed: closing_counter,
      }, rest
    }
  end

  # 5.16 Door Sensor
  defp parse_sensor_function(0x010, <<0x0000000::7, door_status::1, rest::binary>>) do
    {
      :ok,
      %{
        type: :door_sensor,
        door_status: door_status,
        door_status_name: door_status(door_status),
      }, rest
    }
  end

  # 5.20 Ambient Light Sensor
  defp parse_sensor_function(0x014, <<ambient_light_level::32, rest::binary>>) do
    {
      :ok,
      %{
        type: :ambient_light_sensor,
        ambient_light_level: ambient_light_level / 100
      }, rest
    }
  end

  # 5.32 Manhole Sensor
  defp parse_sensor_function(0x020, <<0x0000000::7, lid_status::1, rest::binary>>) do
    {
      :ok,
      %{
        type: :manhole_sensor,
        lid_status: lid_status,
        lid_status_name: lid_status(lid_status),
      }, rest
    }
  end

  defp parse_sensor_function(device, data) do
    Logger.warn("Unknown device #{inspect device} with data #{inspect data}")
    {:error, :unknown_device}
  end

  # 7.1 number of transmits
  defp parse_device_information(0x000, <<number_of_transmits::32, rest::binary>>) do
    {
      :ok,
      %{
        type: :device_information,
        number_of_transmits: number_of_transmits,
      }, rest
    }
  end

  # 7.2 number of slots
  defp parse_device_information(0x001, <<slots, rest::binary>>) do
    {
      :ok,
      %{
        type: :device_information,
        number_of_slots: slots,
      }, rest
    }
  end

  # 7.3 plugged slots
  defp parse_device_information(0x002, <<slot_8::1, slot_7::1, slot_6::1, slot_5::1, slot_4::1, slot_3::1, slot_2::1, slot_1::1, rest::binary>>) do
    {
      :ok,
      %{
        type: :device_information,
        slot_1: connected_or_not(slot_1),
        slot_2: connected_or_not(slot_2),
        slot_3: connected_or_not(slot_3),
        slot_4: connected_or_not(slot_4),
        slot_5: connected_or_not(slot_5),
        slot_6: connected_or_not(slot_6),
        slot_7: connected_or_not(slot_7),
        slot_8: connected_or_not(slot_8),
      }, rest
    }
  end

  # 7.4 serial number
  defp parse_device_information(0x003, <<serial_number::32, rest::binary>>) do
    {
      :ok,
      %{
        type: :device_information,
        serial_number: serial_number,
      }, rest
    }
  end

  # 7.5 connectivity FW version
  defp parse_device_information(0x004, <<fw_version::16, rest::binary>>) do
    {
      :ok,
      %{
        type: :device_information,
        fw_version: fw_version,
      }, rest
    }
  end

  # 7.6 SW version
  defp parse_device_information(0x005, <<sw_version::16, rest::binary>>) do
    with {:ok, major, minor} <- get_version(sw_version) do
      {
        :ok,
        %{
          type: :device_information,
          sw_version: "v#{major}.#{minor}",
        }, rest
      }
    end
  end

  # 7.7 HW version
  defp parse_device_information(0x006, <<hw_version::16, rest::binary>>) do
    with {:ok, major, minor} <- get_version(hw_version) do
      {
        :ok,
        %{
          type: :device_information,
          hw_version: "#{major}.#{minor}"
        }, rest
      }
    end
  end

  # 7.8 cell ID
  defp parse_device_information(0x007, <<cell_id::40, rest::binary>>) do
    {
      :ok,
      %{
        type: :device_information,
        cell_id: cell_id,
      }, rest
    }
  end

  # 7.9 signal power
  defp parse_device_information(0x008, <<signal_power, rest::binary>>) do
    {
      :ok,
      %{
        type: :device_information,
        signal_power: signal_power,
      }, rest
    }
  end

  # 7.10 IMEI
  defp parse_device_information(0x009, <<imei::56, rest::binary>>) do
    {
      :ok,
      %{
        type: :device_information,
        imei: imei,
      }, rest
    }
  end

  # 7.11 IMSI
  defp parse_device_information(0x00A, <<imsi::56, rest::binary>>) do
    {
      :ok,
      %{
        type: :device_information,
        imsi: imsi,
      }, rest
    }
  end

  # 7.12 frequency
  defp parse_device_information(0x00B, <<frequency::16, rest::binary>>) do
    {
      :ok,
      %{
        type: :device_information,
        frequency: frequency / 10,
      }, rest
    }
  end

  # 7.13 edrx
  defp parse_device_information(0x00C, <<edrx, rest::binary>>) do
    {
      :ok,
      %{
        type: :device_information,
        edrx: edrx_mode(edrx),
      }, rest
    }
  end

  # 7.14 connection trials
  defp parse_device_information(0x00D, <<connections, rest::binary>>) do
    {
      :ok,
      %{
        type: :device_information,
        connection_trials: connections,
      }, rest
    }
  end

  # 7.15 PSM Periodic Timer Value
  defp parse_device_information(0x00E, <<psm_timer_unit::3, psm_timer_value::5, rest::binary>>) do
    {
      :ok,
      %{
        type: :device_information,
        psm_periodic_timer_value: psm_periodic_timer_value(psm_timer_unit, psm_timer_value),
      }, rest
    }
  end

  # 7.16 PSM Active Timer Value
  defp parse_device_information(0x00F, <<psm_timer_unit::3, psm_timer_value::5, rest::binary>>) do
    {
      :ok,
      %{
        type: :device_information,
        psm_active_timer_value: psm_active_timer_value(psm_timer_unit, psm_timer_value),
      }, rest
    }
  end

  # 7.17 Battery Level
  defp parse_device_information(0x010, <<battery, rest::binary>>) do
    with {:ok, status, level} <- battery_level(battery) do
      {
        :ok,
        %{
          type: :device_information,
          battery_level: level,
          battery_status: status,
        }, rest
      }
    end
  end

  # 7.18 Alive Message Period
  defp parse_device_information(0x011, <<alive_message_period::32, rest::binary>>) do
    {
      :ok,
      %{
        type: :device_information,
        alive_message_period: alive_message_period,
      }, rest
    }
  end

  defp parse_device_information(dev_inf, _) do
    Logger.info("Could not #{inspect dev_inf}")
    {:error, :unknown_device_information}
  end

  defp parse_time_stamp(1, <<timestamp::32, rest::binary>>) do
    {
      :ok,
      %{
        timestamp_linux: timestamp,
        timestamp: DateTime.from_unix!(timestamp),
      },
      rest
    }
  end
  defp parse_time_stamp(0, rest), do: {:ok, %{}, rest}

  defp get_version(version) when is_integer(version) and version > 0 do
    major = Kernel.trunc(version / 10)
    minor = rem(version, 10)
    {:ok, major, minor}
  end
  defp get_version(version) do
    Logger.warn("Can't parse version for device information: #{inspect version}")
    {:error, :unknown_version_format}
  end

  defp battery_level(battery) when 0 <= battery and battery <= 100, do: {:ok, :not_charging, battery}
  defp battery_level(battery) when 100 < battery and battery <= 200, do: {:ok, :charging, battery - 100}
  defp battery_level(255), do: {:ok, :not_supported, 0}
  defp battery_level(_), do: {:error, :unknown_battery_level}

  defp door_status(0), do: :open
  defp door_status(1), do: :closed
  defp door_status(_), do: :unknown

  defp lid_status(0), do: :closed
  defp lid_status(1), do: :open
  defp lid_status(_), do: :unknown

  defp connected_or_not(0), do: :not_connected
  defp connected_or_not(1), do: :connected
  defp connected_or_not(_), do: :unknown

  defp sensor_board_type(<<0x00>>), do: :device_information
  defp sensor_board_type(<<0x01>>), do: :"3_axis_accelerometer_sensor_board"
  defp sensor_board_type(<<0x02>>), do: :current_transformer_sensor_board
  defp sensor_board_type(<<0x03>>), do: :dry_contact_sensor_board
  defp sensor_board_type(<<0x04>>), do: :gps_sensor_board
  defp sensor_board_type(<<0x05>>), do: :temperature_and_humidity_sensor_board
  defp sensor_board_type(<<0x06>>), do: :"6_axis_accelerometer_sensor_board"
  defp sensor_board_type(<<0x07>>), do: :button_sensor_board
  defp sensor_board_type(<<0x08>>), do: :rtd_sensor_board
  defp sensor_board_type(<<0x09>>), do: :pir_sensor_board
  defp sensor_board_type(<<0x0A>>), do: :laser_distance_sensor_board
  defp sensor_board_type(<<0x0B>>), do: :ambient_light_sensor_board
  defp sensor_board_type(<<0x0C>>), do: :piezo_sensor_board
  defp sensor_board_type(<<0x0D>>), do: :sound_sensor_board
  defp sensor_board_type(<<0x0E>>), do: :voltage_sensor_board
  defp sensor_board_type(<<0x0F>>), do: :magnetometer_sensor_board
  defp sensor_board_type(<<0x10>>), do: :rs485_sensor_board
  defp sensor_board_type(<<0x11>>), do: :voltage_and_power_cut_sensor_board
  defp sensor_board_type(<<0x12>>), do: :ble_signal_strength_sensor_board
  defp sensor_board_type(<<0x13>>), do: :reed_switch_sensor_board
  defp sensor_board_type(<<0x14>>), do: :soil_moisture_sensor_board
  defp sensor_board_type(<<0x15>>), do: :tilt_switch_sensor_board
  defp sensor_board_type(<<0x16>>), do: :energy_meter_sensor_board
  defp sensor_board_type(<<0x17>>), do: :barometric_pressure_sensor_board
  defp sensor_board_type(<<0x18>>), do: :ultrasonic_sensor_board
  defp sensor_board_type(<<0x19>>), do: :uv_light_sensor_board
  defp sensor_board_type(<<0x1A>>), do: :prototyping_board
  defp sensor_board_type(<<0x1B>>), do: :relay_board
  defp sensor_board_type(sbt) do
    Logger.warn("Can't match sensor board type #{inspect sbt}")
    :unknown_sensor_board_type
  end

  defp edrx_mode(0), do: :using_edrx
  defp edrx_mode(5), do: :not_using_edrx
  defp edrx_mode(_), do: :unknown_edrx_mode

  # 10 minutes * value
  defp psm_periodic_timer_value(0b000, value), do: value * 10 * 60
  # 1 hour * value
  defp psm_periodic_timer_value(0b001, value), do: value * 1 * 60 * 60
  # 10 hours * value
  defp psm_periodic_timer_value(0b010, value), do: value * 10 * 60 * 60
  # 2 seconds * value
  defp psm_periodic_timer_value(0b011, value), do: value * 2
  # 30 seconds * value
  defp psm_periodic_timer_value(0b100, value), do: value * 30
  # 1 minute * value
  defp psm_periodic_timer_value(0b101, value), do: value * 1 * 60
  # 320 hours * value
  defp psm_periodic_timer_value(0b110, value), do: value * 320 * 60 * 60
  # deactivated
  defp psm_periodic_timer_value(0b111, _), do: 0

  # 2 seconds * value
  defp psm_active_timer_value(0b000, value), do: value * 2
  # 1 minute * value
  defp psm_active_timer_value(0b001, value), do: value * 1 * 60
  # 6 minutes * value
  defp psm_active_timer_value(0b010, value), do: value * 6 * 60
  #deactivated
  defp psm_active_timer_value(0b111, _), do: 0

  # Define fields with human readable name and a SI unit if available.
  def fields() do
    [
      %{
        field: "signal_power",
        display: "Signal power",
        unit: "dBm",
      },
      %{
        field: "psm_periodic_timer_value",
        display: "PSM Periodic Timer Value",
        unit: "s",
      },
      %{
        field: "psm_active_timer_value",
        display: "PSM Active Timer Value",
        unit: "s",
      },
      %{
        field: "battery_level",
        display: "Battery Level",
        unit: "%",
      },
      %{
        field: "alive_message_period",
        display: "Alive Message Period",
        unit: "s",
      },
      %{
        field: "ambient_light_level",
        display: "Ambient Light Level",
        unit: "lux"
      }
    ]
  end

  def tests() do
    [
      # Test format:
      # {:parse_hex, received_payload_as_hex, meta_map, expected_result},

      # multiple device informations without device data
      {:parse_hex, "011000006400080044030002000400040001000C00000D000A00000B08060000610061080C00000A080A00000AF8", %{meta: %{frame_port: 22}}, [
          %{
            might_have_an_error: 0,
            serial_number: 268435556,
            slot_number: 1,
            sw_version: "v1.0",
            type: :device_information
          },
          %{
            hw_version: "1.0",
            might_have_an_error: 0,
            serial_number: 268435556,
            slot_number: 1,
            type: :device_information
          },
          %{
            might_have_an_error: 0,
            serial_number: 268435556,
            slot_number: 1,
            type: :device_information
          },
          %{
            might_have_an_error: 0,
            serial_number: 268435556,
            slot_number: 0,
            sw_version: "v1.1",
            type: :device_information
          },
          %{
            hw_version: "1.3",
            might_have_an_error: 0,
            serial_number: 268435556,
            slot_number: 0,
            type: :device_information
          },
          %{
            might_have_an_error: 0,
            serial_number: 268435556,
            slot_1: :connected,
            slot_2: :not_connected,
            slot_3: :not_connected,
            slot_4: :not_connected,
            slot_5: :not_connected,
            slot_6: :not_connected,
            slot_7: :not_connected,
            slot_8: :not_connected,
            slot_number: 0,
            type: :device_information
          },
          %{
            might_have_an_error: 0,
            number_of_slots: 4,
            serial_number: 268435556,
            slot_number: 0,
            type: :device_information
          },
          %{
            fw_version: 17411,
            might_have_an_error: 0,
            serial_number: 268435556,
            slot_number: 0,
            type: :device_information
          }
        ]
      },
      {
        :parse_hex, "01100000640000000000000300000000000000000000000000000000000000000087", %{meta: %{frame_port: 22}}, [
          %{
            might_have_an_error: 0,
            number_of_transmits: 0,
            serial_number: 268435556,
            slot_number: 0,
            type: :device_information
          },
          %{
            might_have_an_error: 0,
            number_of_transmits: 0,
            serial_number: 268435556,
            slot_number: 0,
            type: :device_information
          },
          %{
            might_have_an_error: 0,
            number_of_transmits: 0,
            serial_number: 268435556,
            slot_number: 0,
            type: :device_information
          },
          %{
            might_have_an_error: 0,
            number_of_transmits: 3,
            serial_number: 268435556,
            slot_number: 0,
            type: :device_information
          }
        ]
      },
      { # 5.16 Door sensor without device information
        :parse_hex, "0110000064882013386D4EE601F5", %{meta: %{frame_port: 22}}, [
          %{
            door_status: 1,
            door_status_name: :closed,
            might_have_an_error: 0,
            sensor_board_type: :reed_switch_sensor_board,
            serial_number: 268435556,
            slot_number: 1,
            timestamp: DateTime.from_unix!(946687718),
            timestamp_linux: 946687718,
            type: :door_sensor
          }
        ]
      },
      { # 5.16 Door sensor with device information
        :parse_hex, "011000006400000000001A3388201339A6D054007F", %{meta: %{frame_port: 22}}, [
          %{
            door_status: 0,
            door_status_name: :open,
            might_have_an_error: 0,
            sensor_board_type: :reed_switch_sensor_board,
            serial_number: 268435556,
            slot_number: 1,
            timestamp: DateTime.from_unix!(967233620),
            timestamp_linux: 967233620,
            type: :door_sensor
          },
          %{
            might_have_an_error: 0,
            number_of_transmits: 6707,
            serial_number: 268435556,
            slot_number: 0,
            type: :device_information
          }
        ]
      },

      { # 5.12 Door Counter Sensor
        :parse_hex, "0110000065081806000400045B", %{meta: %{frame_port: 22}}, [
          %{
            type: :door_counter,
            might_have_an_error: 0,
            sensor_board_type: :"6_axis_accelerometer_sensor_board",
            slot_number: 1,
            times_closed: 4,
            times_opened: 4,
            serial_number: 268435557,
          }
        ]
      },

      { # 5.20 Ambient Light Sensor
        :parse_hex, "01100006C388280B0000000000005060BA", %{meta: %{frame_port: 22}}, [
          %{
            ambient_light_level: 205.76,
            type: :ambient_light_sensor,
            might_have_an_error: 0,
            sensor_board_type: :ambient_light_sensor_board,
            slot_number: 1,
            serial_number: 268437187,
            timestamp: ~U[1970-01-01 00:00:00Z],
            timestamp_linux: 0
          }
        ]
      },

    ]
  end
end
