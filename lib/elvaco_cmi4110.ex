defmodule Parser do

  use Platform.Parsing.Behaviour
  require Logger

  # Parser for Elvaco CMi4110 devices according to "CMi4110 User's Manual English.pdf"
  #
  # CMi4110 is a cost-effective MCM, which is mounted in a Landis+Gyr UH50 meter to, in a very energy-efficient way, deliver high-precision meter data using the LoRaWAN network.
  #
  # Changelog:
  #   2018-03-21 [jb]: initial version
  #   2019-07-02 [gw]: update according to v1.3 of documentation by adding precise error messages.
  #   2019-07-08 [gw]: Use LibWmbus library to parse the dibs. Changes most of the field names previously defined.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #   2020-06-29 [jb]: Added filter_unknown_data() filtering :unknown Mbus data.

  # When using payload style 0, the payload is made up of DIBs on M-Bus format, excluding M-Bus header.
  def parse(<<type::8, dibs_binary::binary,>>, _meta) do
    dibs =
      dibs_binary
      |> LibWmbus.Dib.parse_dib()
      |> filter_unknown_data()
      |> merge_data_into_parent()
      |> map_values()
      |> Enum.reduce(Map.new(), fn m, acc -> Map.merge(m, acc) end)
      |> Map.drop([:unit, :tariff, :memory_address, :sub_device])

    Enum.into(dibs, %{
      payload_style: type,
    })
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end


  #--- Internals ---

  # Will remove all unknown fields from LibWmbus.Dib.parse_dib(payload) result.
  defp filter_unknown_data(parse_dib_result) do
    Enum.filter(parse_dib_result, fn
      (%{data: %{desc: desc}}) ->
        case to_string(desc) do
          <<"unkown_", _::binary>> -> false
          <<"unknown_", _::binary>> -> false
          _ -> true
        end
      (_) ->
        true
    end)
  end

  defp merge_data_into_parent(map) do
    Enum.map(map, fn
      %{data: data} = parent ->
        parent
        |> Map.merge(data)
        |> Map.delete(:data)
    end)
  end

  defp map_values(map) do
    map
    |> Enum.map(fn
      %{desc: :error_codes, value: v} = map ->
        v_as_int = String.to_integer(v)
        <<error::binary>> = Base.decode16!(v)
        map
        |> Map.merge(%{:error_codes => (if v_as_int > 0, do: 1, else: 0), :error => build_error_string(error)})
        |> Map.drop([:desc, :value])
      %{desc: :fabrication_block, value: v} = map ->
        map
        |> Map.merge(%{:fabrication_block => v, :fabrication_block_unit => "MeterID"})
        |> Map.drop([:desc, :value])
      %{desc: d = :energy, value: v, unit: "Wh"} = map ->
        map
        |> Map.merge(%{d => Float.round(v / 1000, 3), :energy_unit => "kWh"})
        |> Map.drop([:desc, :value])
      %{desc: d, value: v, unit: u} = map ->
        map
        |> Map.merge(%{d => v, "#{d}_unit" => u})
        |> Map.drop([:desc, :value])
    end )
  end

  defp build_error_string(<<status::binary-1>>), do: build_error_string(<<0>> <> status)
  defp build_error_string(<<_rfu::2, _not_relevant_for_lora::2, eeprom_heads_up::1, dirt_heads_up::1, electronic_error::1, eight_hours_exceeded::1,
    internal_memory_disturbance::1, short_circuit_temperature_sensor_cold_side::1, short_circuit_temperature_sensor_warm_side::1,
    _supply_voltage_low::1, electronic_malfunction::1, disruption_temperature_sensor_cold_side::1, disruption_temperature_sensor_warm_side::1,
    error_flow_measurement::1>>) do
    []
    |> concat_if(eeprom_heads_up, "EEPROM-Vorwarnung")
    |> concat_if(dirt_heads_up, "Verschmutzungs-Vorwarnung der Messstrecke")
    |> concat_if(electronic_error, "F9 - Fehler in der Elektronik (ASIC)")
    |> concat_if(eight_hours_exceeded, "F8 - F1, F2, F3, F5 oder F6 stehen länger als 8 Stunden an")
    |> concat_if(internal_memory_disturbance, "F7 - Störung im internen Speicher (ROM oder EEPROM")
    |> concat_if(short_circuit_temperature_sensor_cold_side, "F6 - Kurzschluss Termperaturfühler kalte Seite")
    |> concat_if(short_circuit_temperature_sensor_warm_side, "F5 - Kurzschluss Termperaturfühler warme Seite")
    |> concat_if(electronic_malfunction, "F3 - Elektronik für Temperaturauswertung defekt")
    |> concat_if(disruption_temperature_sensor_cold_side, "F2 - Unterbrechung Temperaturfühler kalte Seite")
    |> concat_if(disruption_temperature_sensor_warm_side, "F1 - Unterbrechung Temperaturfühler warme Seite")
    |> concat_if(error_flow_measurement, "F0 - Fehler bei Durchflussmessung (z.B. Luft im Messrohr")
    |> List.flatten()
    |> Enum.into("")
  end

  defp concat_if(acc, 0, _), do: acc
  defp concat_if([], 1, string), do: [string]
  defp concat_if(acc, 1, string), do: [acc, ";", string]


  def fields() do
    [
      %{
        field: "payload_style",
        display: "Payload Style",
      },
      %{
        field: "energy",
        display: "Energie",
        unit: "kWh",
      },
      %{
        field: "flow",
        display: "Fluss",
        unit: "m³/h",
      },
      %{
        field: "power",
        display: "Power",
        unit: "W",
      },
      %{
        field: "supply_temperature",
        display: "Vorlauftemperatur",
        unit: "°C",
      },
      %{
        field: "return_temperature",
        display: "Rücklauftemperatur",
        unit: "°C",
      },
      %{
        field: "volume",
        display: "Volumen",
        unit: "m³",
      },
    ]
  end

  # Function for testing. Run with `elixir -r payload_parser/elvaco_cmi4110/parser.exs -e "Parser.test()"`
  def tests() do
    [
      # From PDF
      {
        :parse_hex, "000C06384612000C14059753000B2D5201000B3B5706000A5A05030A5E05010C7889478268046D3231542302FD170000", %{}, %{
          "datetime_unit" => "",
          "flow_unit" => "m³/h",
          "power_unit" => "W",
          "return_temperature_unit" => "°C",
          "supply_temperature_unit" => "°C",
          "volume_unit" => "m³",
          datetime: ~N[2018-03-20 17:50:00],
          energy: 124638.0,
          energy_unit: "kWh",
          error_codes: 0,
          error: "",
          fabrication_block: 68824789,
          fabrication_block_unit: "MeterID",
          flow: 0.657,
          function_field: :current_value,
          supply_temperature: 30.5,
          payload_style: 0,
          power: 15200,
          return_temperature: 10.5,
          volume: 5397.05,
        }
      },

      # From real device
      {
        :parse_hex, "000C06150110000C782791206802FD170600", %{}, %{
          energy: 100115.0,
          energy_unit: "kWh",
          error_codes: 1,
          error: "F2 - Unterbrechung Temperaturfühler kalte Seite;F1 - Unterbrechung Temperaturfühler warme Seite",
          fabrication_block: 68209127,
          fabrication_block_unit: "MeterID",
          function_field: :current_value,
          payload_style: 0,
        }
      },

      # From real device
      {
        :parse_hex, "000C06748823000C14099850000B2D0801000B3B6201000A5A54090A5E79030C788851276702FD170000", %{}, %{
          "flow_unit" => "m³/h",
          "power_unit" => "W",
          "return_temperature_unit" => "°C",
          "supply_temperature_unit" => "°C",
          "volume_unit" => "m³",
          energy: 238874.0,
          energy_unit: "kWh",
          error_codes: 0,
          error: "",
          flow: 0.162,
          function_field: :current_value,
          supply_temperature: 95.4,
          fabrication_block: 67275188,
          fabrication_block_unit: "MeterID",
          payload_style: 0,
          power: 10800,
          return_temperature: 37.9,
          volume: 5098.09
        }
      },
      {
        :parse_hex, "000C06365518000C14136528003B2E0000003B3E0000003A5B00003A5F00000C788414916502FD170304", %{}, %{
          "flow_unit" => "m³/h",
          "power_unit" => "W",
          "return_temperature_unit" => "°C",
          "supply_temperature_unit" => "°C",
          "volume_unit" => "m³",
          :energy => 185536.0,
          :energy_unit => "kWh",
          :error => "Verschmutzungs-Vorwarnung der Messstrecke;F1 - Unterbrechung Temperaturfühler warme Seite;F0 - Fehler bei Durchflussmessung (z.B. Luft im Messrohr",
          :error_codes => 1,
          :fabrication_block => 65911484,
          :fabrication_block_unit => "MeterID",
          :flow => 0,
          :function_field => :current_value,
          :payload_style => 0,
          :power => 0,
          :return_temperature => 0,
          :supply_temperature => 0,
          :volume => 2865.13,
        }
      },
    ]
  end

end
