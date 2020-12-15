defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # Parser for ELSYS devices according to "Elsys-LoRa-payload.pdf"
  #
  # All Elsys LoRa sensor devices use the same payload structure.
  #
  # Documentation:
  #   https://elsys.se/public/documents/Elsys-LoRa-payload.pdf
  #
  # Changelog
  #   2018-04-12 [jb]: Initial implementation, not yet all sTypes implemented
  #   2018-07-16 [as]: Added sTypes 04, 05, 06
  #   2019-02-22 [jb]: Added sTypes 03, 0F, 14. Fields and Tests.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #   2020-04-07 [jb]: Added all missing sTypes. Fixed negative temperature bugs. Removed offset=0 values.
  #   2020-12-15 [jb]: Updating to Payload v1.11. Adding sTypes 00, 10, 13, 1A, 1B, 3E

  def parse(payload, _meta) when is_binary(payload) do
    case parse_parts(payload, %{}) do
      {:ok, parts} ->
        parts
      {:error, {parts, rest}} ->
        Map.put(parts, :unparsed_binary, Base.encode16(rest))
    end
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  # First two bits define length of optional offset
  # Second 6 bits define type of part,
  # Size of values is defined by type of part.

  # 0x00 Reserved
  def parse_parts(<<_nob::2, 0x00::6, reserved::binary>>, parts) do
    parse_parts(<<>>, add_part(parts, :reserved_00, Base.encode16(reserved), %{}))
  end

  def parse_parts(<<nob::2, 0x01::6, temp::16-signed, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :temperature, temp/10, %{offset: offset, unit: "C"}))
  end

  def parse_parts(<<nob::2, 0x02::6, humidity::8, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :humidity, humidity, %{offset: offset, unit: "%"}))
  end

  # Acceleration/level; X,Y,Z ‐127‐127(63=1G)
  def parse_parts(<<nob::2, 0x03::6, x::signed-8, y::signed-8, z::signed-8, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(
      rest,
      parts
      |> add_part(:acceleration_sum, (x/63)+(y/63)+(z/63), %{offset: offset, unit: "G"})
      |> add_part(:acceleration_x, x/63, %{offset: offset, unit: "G"})
      |> add_part(:acceleration_y, y/63, %{offset: offset, unit: "G"})
      |> add_part(:acceleration_z, z/63, %{offset: offset, unit: "G"})
    )
  end

  def parse_parts(<<nob::2, 0x04::6, lux::16, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :lux, lux, %{offset: offset, unit: "lux"}))
  end

  def parse_parts(<<nob::2, 0x05::6, motion::8, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :motion, motion, %{offset: offset}))
  end

  def parse_parts(<<nob::2, 0x06::6, co2::16, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :co2, co2, %{offset: offset, unit: "ppm"}))
  end

  def parse_parts(<<nob::2, 0x07::6, battery::16, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :battery, battery, %{offset: offset, unit: "mV"}))
  end

  def parse_parts(<<nob::2, 0x08::6, analog1::16, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :analog1, analog1, %{offset: offset, unit: "mV"}))
  end

  def parse_parts(<<nob::2, 0x09::6, gps::binary-6, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    <<lat::24, lon::24>> = gps
    parse_parts(
      rest,
      parts
        |> add_part(:gps_lat, lat, %{offset: offset, unit: "?"}) # TODO: Not documented how data looks like and no example payload at hand
        |> add_part(:gps_lon, lon, %{offset: offset, unit: "?"}) # TODO: Not documented how data looks like and no example payload at hand
    )
  end

  def parse_parts(<<nob::2, 0x0A::6, pulse_count::16, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :pulse_count, pulse_count, %{offset: offset, unit: "count"}))
  end

  def parse_parts(<<nob::2, 0x0B::6, pulse_count_abs::32, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :pulse_count_abs, pulse_count_abs, %{offset: offset, unit: "count"}))
  end

  def parse_parts(<<nob::2, 0x0C::6, temp::16-signed, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :external_temp1, temp/10, %{offset: offset, unit: "C"}))
  end

  def parse_parts(<<nob::2, 0x0D::6, on_off::8, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :digital1, on_off, %{offset: offset, unit: "bool"}))
  end

  def parse_parts(<<nob::2, 0x0E::6, distance::16, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :external_distance, distance, %{offset: offset, unit: "mm"}))
  end

  # Motion(accelerationmovements); 0‐255
  def parse_parts(<<nob::2, 0x0F::6, motion::8, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :acceleration_motion, motion, %{offset: offset, unit: "count"}))
  end

  def parse_parts(<<nob::2, 0x10::6, temps::binary-4, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    <<temp_internal::16-signed, temp_external::16-signed>> = temps
    parse_parts(
      rest,
      parts
        |> add_part(:internal_temp, temp_internal/10, %{offset: offset, unit: "C"})
        |> add_part(:external_temp, temp_external/10, %{offset: offset, unit: "C"})
    )
  end

  def parse_parts(<<nob::2, 0x11::6, occupancy::8, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :occupancy, occupancy, %{offset: offset, unit: "count"}))
  end

  def parse_parts(<<nob::2, 0x12::6, water_leak::8, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :external_water_leak, water_leak, %{offset: offset}))
  end

  # Grideye(roomoccupancy)
  def parse_parts(<<nob::2, 0x13::6, ref, pixels::binary-64, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(
      rest,
      parts
      |> add_part(:grideye_ref, ref, %{offset: offset})
      |> add_part(:grideye_pixels, Base.encode16(pixels), %{offset: offset})
    )
  end

  # Pressure; Pressuredata(hPa)
  def parse_parts(<<nob::2, 0x14::6, pressure::32, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :pressure, pressure, %{offset: offset, unit: "hPa"}))
  end

  def parse_parts(<<nob::2, 0x15::6, sounds::binary-2, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    <<peak::8, avg::8>> = sounds
    parse_parts(
      rest,
      parts
        |> add_part(:sound_peak, peak, %{offset: offset, unit: "dB"})
        |> add_part(:sound_avg, avg, %{offset: offset, unit: "dB"})
    )
  end

  def parse_parts(<<nob::2, 0x16::6, pulse_count::16, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :pulse_count2, pulse_count, %{offset: offset, unit: "count"}))
  end

  def parse_parts(<<nob::2, 0x17::6, pulse_count_abs::32, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :pulse_count2_abs, pulse_count_abs, %{offset: offset, unit: "count"}))
  end

  def parse_parts(<<nob::2, 0x18::6, analog2::16, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :analog2, analog2, %{offset: offset, unit: "mV"}))
  end

  def parse_parts(<<nob::2, 0x19::6, temp::16-signed, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :external_temp2, temp/10, %{offset: offset, unit: "C"}))
  end

  def parse_parts(<<nob::2, 0x1A::6, on_off::8, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :digital2, on_off, %{offset: offset, unit: "bool"}))
  end

  def parse_parts(<<nob::2, 0x1B::6, analog::32-signed, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :external_analog_uv, analog, %{offset: offset, unit: "uV"}))
  end

  def parse_parts(<<nob::2, 0x3D::6, debug::binary-4, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :debug, Base.encode16(debug), %{offset: offset}))
  end

  # Sensor setting sent to server at startup (first package). Sent on Port+1. See sensor settings for more information.
  def parse_parts(<<_nob::2, 0x3E::6, sensor_settings::binary>>, parts) do
    # Not documented how to handle this. Stop parsing here.
    parse_parts(<<>>, add_part(parts, :sensor_settings, Base.encode16(sensor_settings), %{}))
  end

  def parse_parts(<<>>, parts), do: {:ok, parts} # Done parsing
  def parse_parts(rest, parts), do: {:error, {parts, rest}} # Can not parse rest

  # Adding a name and value to a map, increasing counter of key already exists.
  def add_part(parts, name, value, meta, counter \\ 1) do
    key = "#{name}_#{counter}"
    meta = remove_empty_offset(meta)
    if Map.has_key?(parts, key) do
      add_part(parts, name, value, meta, counter+1)
    else
      prefixed_meta = Enum.into(meta, %{}, fn({k, v}) ->
        {"#{key}_#{k}", v}
      end)
      parts
      |> Map.put(key, value)
      |> Map.merge(prefixed_meta)
    end
  end

  def remove_empty_offset(%{offset: 0} = map), do: Map.drop(map, [:offset])
  def remove_empty_offset(map), do: map

  def fields() do
    # Generate list of possible Fields.
    Enum.flat_map([
      {:temperature, "Temperature", "C"},
      {:external_temp, "Ext.Temperature", "C"},
      {:internal_temp, "Int.Temperature", "C"},
      {:external_temp1, "Ext.Temperature1", "C"},
      {:external_temp2, "Ext.Temperature2", "C"},
      {:occupancy, "Occupancy", "count"},
      {:external_water_leak, "Ext.Water-Leak", ""},
      {:sound_peak, "Sound-Peak", "dB"},
      {:sound_avg, "Sound-Avg", "dB"},
      {:humidity, "Humidity", "%"},
      {:acceleration_sum, "Total-Acceleration", "G"},
      {:acceleration_x, "X-Acceleration", "G"},
      {:acceleration_y, "Y-Acceleration", "G"},
      {:acceleration_z, "Z-Acceleration", "G"},
      {:lux, "Lux", "lux"},
      {:motion, "Motion", ""},
      {:co2, "CO2", "ppm"},
      {:battery, "Battery", "mW"},
      {:analog1, "Analog1", "mW"},
      {:analog2, "Analog2", "mW"},
      {:external_analog_uv, "Ext.Analog", "uV"},
      {:gps_lat, "GPS-Lat", "?"},
      {:gps_lon, "GPS-Lon", "?"},
      {:digital1, "Digital1", "bool"},
      {:digital2, "Digital2", "bool"},
      {:external_distance, "Ext.Distance", "mm"},
      {:pulse_count, "Pulse Count", "count"},
      {:pulse_count_abs, "Absolute Pulse Count", "count"},
      {:pulse_count2, "Pulse Count2", "count"},
      {:pulse_count2_abs, "Absolute Pulse Count2", "count"},
      {:acceleration_motion, "Acceleration Motion", "count"},
      {:pressure, "Pressure", "hPa"},
      {:grideye_ref, "GrideyeRef", nil},
      {:grideye_pixels, "GrideyePixels", nil},
      {:sensor_settings, "SensorSettings", nil},
    ], fn({field_prefix, display_prefix, unit}) ->
      Enum.map([1, 2, 3], fn(counter) ->
        %{
          "field" => "#{field_prefix}_#{counter}",
          "display" => "#{display_prefix} #{counter}",
          "unit" => unit,
        }
      end)
    end)
  end


  def tests() do
    [
      {:parse_hex, "0100D5022703FB00C1070E4B0F0014000F417A", %{meta: %{frame_port: 5}}, %{
        "acceleration_motion_1" => 0,
        "acceleration_motion_1_unit" => "count",
        "acceleration_sum_1" => -1.0793650793650793,
        "acceleration_sum_1_unit" => "G",
        "acceleration_x_1" => -0.07936507936507936,
        "acceleration_x_1_unit" => "G",
        "acceleration_y_1" => 0.0,
        "acceleration_y_1_unit" => "G",
        "acceleration_z_1" => -1.0,
        "acceleration_z_1_unit" => "G",
        "battery_1" => 3659,
        "battery_1_unit" => "mV",
        "humidity_1" => 39,
        "humidity_1_unit" => "%",
        "pressure_1" => 999802,
        "pressure_1_unit" => "hPa",
        "temperature_1" => 21.3,
        "temperature_1_unit" => "C"
      }},
      {:parse_hex, "0100E1022603F9FDC0070E380F0014000F3D4D", %{meta: %{frame_port: 5}}, %{
        "acceleration_motion_1" => 0,
        "acceleration_motion_1_unit" => "count",
        "acceleration_sum_1" => -1.1746031746031744,
        "acceleration_sum_1_unit" => "G",
        "acceleration_x_1" => -0.1111111111111111,
        "acceleration_x_1_unit" => "G",
        "acceleration_y_1" => -0.047619047619047616,
        "acceleration_y_1_unit" => "G",
        "acceleration_z_1" => -1.0158730158730158,
        "acceleration_z_1_unit" => "G",
        "battery_1" => 3640,
        "battery_1_unit" => "mV",
        "humidity_1" => 38,
        "humidity_1_unit" => "%",
        "pressure_1" => 998733,
        "pressure_1_unit" => "hPa",
        "temperature_1" => 22.5,
        "temperature_1_unit" => "C"
      }},
      {:parse_hex, "080E38 09000001000002 0C00D5 0D00 0D01", %{meta: %{frame_port: 5}}, %{
        "analog1_1" => 3640,
        "analog1_1_unit" => "mV",
        "digital1_1" => 0,
        "digital1_1_unit" => "bool",
        "digital1_2" => 1,
        "digital1_2_unit" => "bool",
        "external_temp1_1" => 21.3,
        "external_temp1_1_unit" => "C",
        "gps_lat_1" => 1,
        "gps_lat_1_unit" => "?",
        "gps_lon_1" => 2,
        "gps_lon_1_unit" => "?"

      }},
      {:parse_hex, "0E0042 1101 151337 160001 1700000002 180023", %{meta: %{frame_port: 5}}, %{
        "analog2_1" => 35,
        "analog2_1_unit" => "mV",
        "external_distance_1" => 66,
        "external_distance_1_unit" => "mm",
        "occupancy_1" => 1,
        "occupancy_1_unit" => "count",
        "pulse_count2_1" => 1,
        "pulse_count2_1_unit" => "count",
        "pulse_count2_abs_1" => 2,
        "pulse_count2_abs_1_unit" => "count",
        "sound_avg_1" => 55,
        "sound_avg_1_unit" => "dB",
        "sound_peak_1" => 19,
        "sound_peak_1_unit" => "dB"

      }},
      {:parse_hex, "190042 3DCAFEBABE", %{meta: %{frame_port: 5}}, %{
        "debug_1" => "CAFEBABE",
        "external_temp2_1" => 6.6,
        "external_temp2_1_unit" => "C"
      }},
      {:parse_hex, "00 AFFE", %{meta: %{frame_port: 5}}, %{"reserved_00_1" => "AFFE"}},
      {:parse_hex, "10 001F FFAA", %{meta: %{frame_port: 5}}, %{
        "external_temp_1" => -8.6,
        "external_temp_1_unit" => "C",
        "internal_temp_1" => 3.1,
        "internal_temp_1_unit" => "C"
      }},
      {:parse_hex, "13 42 00000001 00000002 00000003 00000004 00000005 00000006 00000007 00000008 00000009 00000010 00000011 00000012 00000013 00000014 00000015 00000016", %{meta: %{frame_port: 5}}, %{
        "grideye_pixels_1" => "00000001000000020000000300000004000000050000000600000007000000080000000900000010000000110000001200000013000000140000001500000016",
        "grideye_ref_1" => 66
      }},
      {:parse_hex, "1A 01 1B 0BBBBBBB 3E CAFE", %{meta: %{frame_port: 5}}, %{
        "digital2_1" => 1,
        "digital2_1_unit" => "bool",
        "external_analog_uv_1" => 196852667,
        "external_analog_uv_1_unit" => "uV",
        "sensor_settings_1" => "CAFE"
      }},
    ]
  end



end
