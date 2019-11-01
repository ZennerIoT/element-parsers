defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # Parser for ELSYS devices according to "Elsys-LoRa-payload_v8.pdf"
  # https://www.elsys.se/en/wp-content/uploads/sites/3/2016/09/Elsys-LoRa-payload_v8.pdf
  #
  #
  # Changelog
  #   2018-04-12 [jb]: Initial implementation, not yet all sTypes implemented
  #   2018-07-16 [as]: Added sTypes 04, 05, 06
  #   2019-02-22 [jb]: Added sTypes 03, 0F, 14. Fields and  Tests.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.

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

  def parse_parts(<<nob::2, 0x01::6, temp::16, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
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
    parse_parts(rest, add_part(parts, :motion, motion, %{offset: offset, unit: ""}))
  end

  def parse_parts(<<nob::2, 0x06::6, co2::16, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :co2, co2, %{offset: offset, unit: "ppm"}))
  end

  def parse_parts(<<nob::2, 0x07::6, battery::16, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :battery, battery, %{offset: offset, unit: "mV"}))
  end

  # Missing 0x08 .. 0x09

  def parse_parts(<<nob::2, 0x0A::6, pulse_count::16, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :pulse_count, pulse_count, %{offset: offset, unit: "count"}))
  end

  def parse_parts(<<nob::2, 0x0B::6, pulse_count_abs::32, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :pulse_count_abs, pulse_count_abs, %{offset: offset, unit: "count"}))
  end

  # Motion(accelerationmovements); 0‐255
  def parse_parts(<<nob::2, 0x0F::6, motion::8, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :acceleration_motion, motion, %{offset: offset, unit: "count"}))
  end

  # Pressure; Pressuredata(hPa)
  def parse_parts(<<nob::2, 0x14::6, pressure::32, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :pressure, pressure, %{offset: offset, unit: "hPa"}))
  end

  # Missing 0x0C ..

  def parse_parts(<<>>, parts), do: {:ok, parts} # Done parsing
  def parse_parts(rest, parts), do: {:error, {parts, rest}} # Can not parse rest

  # Adding a name and value to a map, increasing counter of key already exists.
  def add_part(parts, name, value, meta, counter \\ 1) do
    key = "#{name}_#{counter}"
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


  def fields() do
    # Generate list of possible Fields.
    Enum.flat_map([
      {:temperature, "Temperature", "C"},
      {:humidity, "Humidity", "%"},
      {:acceleration_sum, "Total-Acceleration", "G"},
      {:acceleration_x, "X-Acceleration", "G"},
      {:acceleration_y, "Y-Acceleration", "G"},
      {:acceleration_z, "Z-Acceleration", "G"},
      {:lux, "Lux", "lux"},
      {:motion, "Motion", ""},
      {:co2, "CO2", "ppm"},
      {:battery, "Battery", "mW"},
      {:pulse_count, "Pulse Count", "count"},
      {:pulse_count_abs, "Absolute Pulse Count", "count"},
      {:acceleration_motion, "Acceleration Motion", "count"},
      {:pressure, "Pressure", "hPa"},
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
        "acceleration_motion_1_offset" => 0,
        "acceleration_motion_1_unit" => "count",
        "acceleration_sum_1" => -1.0793650793650793,
        "acceleration_sum_1_offset" => 0,
        "acceleration_sum_1_unit" => "G",
        "acceleration_x_1" => -0.07936507936507936,
        "acceleration_x_1_offset" => 0,
        "acceleration_x_1_unit" => "G",
        "acceleration_y_1" => 0.0,
        "acceleration_y_1_offset" => 0,
        "acceleration_y_1_unit" => "G",
        "acceleration_z_1" => -1.0,
        "acceleration_z_1_offset" => 0,
        "acceleration_z_1_unit" => "G",
        "battery_1" => 3659,
        "battery_1_offset" => 0,
        "battery_1_unit" => "mV",
        "humidity_1" => 39,
        "humidity_1_offset" => 0,
        "humidity_1_unit" => "%",
        "pressure_1" => 999802,
        "pressure_1_offset" => 0,
        "pressure_1_unit" => "hPa",
        "temperature_1" => 21.3,
        "temperature_1_offset" => 0,
        "temperature_1_unit" => "C"
      }},
      {:parse_hex, "0100E1022603F9FDC0070E380F0014000F3D4D", %{meta: %{frame_port: 5}}, %{
        "acceleration_motion_1" => 0,
        "acceleration_motion_1_offset" => 0,
        "acceleration_motion_1_unit" => "count",
        "acceleration_sum_1" => -1.1746031746031744,
        "acceleration_sum_1_offset" => 0,
        "acceleration_sum_1_unit" => "G",
        "acceleration_x_1" => -0.1111111111111111,
        "acceleration_x_1_offset" => 0,
        "acceleration_x_1_unit" => "G",
        "acceleration_y_1" => -0.047619047619047616,
        "acceleration_y_1_offset" => 0,
        "acceleration_y_1_unit" => "G",
        "acceleration_z_1" => -1.0158730158730158,
        "acceleration_z_1_offset" => 0,
        "acceleration_z_1_unit" => "G",
        "battery_1" => 3640,
        "battery_1_offset" => 0,
        "battery_1_unit" => "mV",
        "humidity_1" => 38,
        "humidity_1_offset" => 0,
        "humidity_1_unit" => "%",
        "pressure_1" => 998733,
        "pressure_1_offset" => 0,
        "pressure_1_unit" => "hPa",
        "temperature_1" => 22.5,
        "temperature_1_offset" => 0,
        "temperature_1_unit" => "C"
      }},
    ]
  end



end
