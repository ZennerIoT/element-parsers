defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # Parser for device ATIM Metering and Dry Contact DIND160/80/88/44.
  #
  # Changelog:
  #   2020-06-18 [jb]: Initial implementation according to "ATIM_ACW-DIND160-80-88-44_UG_EN_V1.7.pdf"
  #   2020-06-23 [jb]: Added feature :append_last_digital_inputs default: false
  #

  def config() do
    %{
      # Will append the last digital_inputs from previous packet. Might not work correctly with reparsing.
      append_last_digital_inputs: false,
    }
  end
  defp config(key, meta), do: get(meta, [:_config, key], Map.get(config(), key))

  def parse(<<0x00, _::binary>>, _meta), do: %{type: :undocumented_format_0}
  def parse(<<0x06, _::binary>>, _meta), do: %{type: :undocumented_format_6}
  def parse(<<0x08, _::binary>>, _meta), do: %{type: :undocumented_format_8}

  def parse(<<0x01, power1::16, power2::16, 0x64>>, _meta) do
    %{
      type: :keep_alive,
      power_supply1: power1,
      power_supply2: power2,
    }
  end
  def parse(<<0x05, counter>>, _meta) do
    %{
      type: :test,
      counter: counter,
    }
  end
  def parse(<<0x07, 0x02, device_type, acw_version::little-16, radio_type, radio_version::little-16, serial_number::binary>>, _meta) do
    %{
      type: :cmd_response,
      command: :about,
      device_type: device_type(device_type),
      acw_version: acw_version,
      radio_type: radio_type(radio_type),
      radio_version: radio_version,
      serial_number: Base.encode16(serial_number),
    }
  end
  def parse(<<0x07, 0x03, exit_code>>, _meta) do
    %{
      type: :cmd_response,
      command: :reconfiguration,
      exit_code: exit_code,
    }
  end
  def parse(<<0x07, cmd, _::binary>>, _meta) do
    %{
      type: :cmd_response,
      command: cmd,
    }
  end
  def parse(<<0x41, digital_inputs::binary-2>>, meta) do
    %{
      type: :digital_inputs,
    }
    |> parse_digital_inputs(digital_inputs)
    |> append_last_digital_inputs(meta)
  end
  def parse(<<0x42, digital_inputs::binary-2>>, meta) do
    %{
      type: :digital_inputs,
    }
    |> parse_digital_inputs(digital_inputs)
    |> append_last_digital_inputs(meta)
  end
  def parse(<<0x43, counter>>, _meta) do
    %{
      type: :alarm_of_shock,
      counter: counter,
    }
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  defp device_type(9), do: "DIND160"
  defp device_type(11), do: "DIND80"
  defp device_type(15), do: "DIND88"
  defp device_type(14), do: "DIND44"
  defp device_type(_), do: :unknown

  defp radio_type(3), do: "Sigfox-only-uplink"
  defp radio_type(4), do: "Sigfox"
  defp radio_type(5), do: "LoRaWAN"
  defp radio_type(_), do: :unknown

  defp parse_digital_inputs(row, <<
    i8::1, i7::1, i6::1, i5::1, i4::1, i3::1, i2::1, i1::1,
    i16::1, i15::1, i14::1, i13::1, i12::1, i11::1, i10::1, i9::1
  >>) do
    Map.merge(row, %{
      input1: i1,
      input2: i2,
      input3: i3,
      input4: i4,
      input5: i5,
      input6: i6,
      input7: i7,
      input8: i8,
      input9: i9,
      input10: i10,
      input11: i11,
      input12: i12,
      input13: i13,
      input14: i14,
      input15: i15,
      input16: i16,
    })
  end

  defp append_last_digital_inputs(row, meta) do
    if config(:append_last_digital_inputs, meta) do
      meta
      |> get_last_reading([input1: :_])
      |> case do
        %{data: data} ->
          Map.merge(row, %{
            input1_last: Map.get(data, "input1"),
            input2_last: Map.get(data, "input2"),
            input3_last: Map.get(data, "input3"),
            input4_last: Map.get(data, "input4"),
            input5_last: Map.get(data, "input5"),
            input6_last: Map.get(data, "input6"),
            input7_last: Map.get(data, "input7"),
            input8_last: Map.get(data, "input8"),
            input9_last: Map.get(data, "input9"),
            input10_last: Map.get(data, "input10"),
            input11_last: Map.get(data, "input11"),
            input12_last: Map.get(data, "input12"),
            input13_last: Map.get(data, "input13"),
            input14_last: Map.get(data, "input14"),
            input15_last: Map.get(data, "input15"),
            input16_last: Map.get(data, "input16"),
          })
        _ ->
          row
      end
    else
      row
    end
  end

#  defp parse_temperature(row, <<temp::signed-16>>) do
#    Map.merge(row, %{
#      temperature: temp/10,
#    })
#  end

  # Define fields with human readable name and a SI unit if available.
  def fields() do
    [
      # The first field should be a numeric value, so it can be used for graphs.
      %{
        field: "counter",
        display: "Counter",
      },
      %{
        field: "type",
        display: "Type",
      },
      %{
        field: "cmd",
        display: "Command-Type",
      },
      %{
        field: "power_supply1",
        display: "Power-Supply 1",
        unit: "mV",
      },
      %{
        field: "power_supply2",
        display: "Power-Supply 2",
        unit: "mV",
      },
    ] ++ Enum.map(1..16, fn(i) ->
      %{
        field: "input#{i}",
        display: "Input #{i}",
      }
    end)
  end

  def tests() do
    [
      # test frame
      {:parse_hex, "0523", %{meta: %{frame_port: 1}}, %{counter: 35, type: :test}},

      # keep alive
      {:parse_hex, "015F845F8464", %{meta: %{frame_port: 1}}, %{power_supply1: 24452, power_supply2: 24452, type: :keep_alive}},

      # 41100F
      {:parse_hex, "41100F", %{meta: %{frame_port: 1}}, %{
        input1: 0,
        input10: 1,
        input11: 1,
        input12: 1,
        input13: 0,
        input14: 0,
        input15: 0,
        input16: 0,
        input2: 0,
        input3: 0,
        input4: 0,
        input5: 1,
        input6: 0,
        input7: 0,
        input8: 0,
        input9: 1,
        type: :digital_inputs
      }},

      # Digital inputs frame
      {:parse_hex, "42EFFF", %{meta: %{frame_port: 1}}, %{
        input1: 1,
        input10: 1,
        input11: 1,
        input12: 1,
        input13: 1,
        input14: 1,
        input15: 1,
        input16: 1,
        input2: 1,
        input3: 1,
        input4: 1,
        input5: 0,
        input6: 1,
        input7: 1,
        input8: 1,
        input9: 1,
        type: :digital_inputs
      }},

      # Alarm of shock frame
      {:parse_hex, "4327", %{meta: %{frame_port: 1}}, %{counter: 39, type: :alarm_of_shock}},

      # Frame of digital IN/OUT and temperature
      {:parse_hex, "07100F00", %{meta: %{frame_port: 1}}, %{command: 16, type: :cmd_response}},

      # Testing feature :append_last_digital_inputs
      {
        :parse_hex,
        "42EFFF",
        %{
          meta: %{frame_port: 1},
          _config: %{
            append_last_digital_inputs: true,
          },
          _last_reading_map: %{
            [input1: :_] =>
              %{
                data: %{
                  "input1" => 0,
                  "input10" => 0,
                  "input11" => 0,
                  "input12" => 0,
                  "input13" => 0,
                  "input14" => 0,
                  "input15" => 0,
                  "input16" => 0,
                  "input2" => 0,
                  "input3" => 0,
                  "input4" => 0,
                  "input5" => 1,
                  "input6" => 0,
                  "input7" => 0,
                  "input8" => 0,
                  "input9" => 0,
                }
            },
          },
        },
        %{
          input11_last: 0,
          input8: 1,
          input2: 1,
          input11: 1,
          input5_last: 1,
          input5: 0,
          input3_last: 0,
          input9: 1,
          input7_last: 0,
          input16: 1,
          type: :digital_inputs,
          input1_last: 0,
          input8_last: 0,
          input13_last: 0,
          input6: 1,
          input1: 1,
          input14: 1,
          input16_last: 0,
          input10_last: 0,
          input12: 1,
          input7: 1,
          input2_last: 0,
          input4_last: 0,
          input4: 1,
          input3: 1,
          input14_last: 0,
          input15_last: 0,
          input15: 1,
          input10: 1,
          input13: 1,
          input12_last: 0,
          input6_last: 0,
          input9_last: 0
        }
      }
    ]
  end
end
