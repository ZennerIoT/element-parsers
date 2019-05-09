defmodule Parser do
  use Platform.Parsing.Behaviour

  require Logger

  # ELEMENT IoT Parser for NAS "Pulse + Analog Reader UM30x3" v0.5.0 and v0.7.0
  # Author NKlein
  # Link: https://www.nasys.no/product/lorawan-pulse-analog-reader/
  # Documentation:
  #   UM3023
  #     0.5.0: https://www.nasys.no/wp-content/uploads/Pulse-Analog-Reader_UM3023.pdf
  #     0.7.0: https://www.nasys.no/wp-content/uploads/Pulse_readeranalog_UM3023.pdf
  #   UM3033
  #     0.7.0: https://www.nasys.no/wp-content/uploads/Pulse_ReaderMbus_UM3033.pdf

  # Changelog
  #   2018-09-04 [jb]: Added tests. Handling Configuration request on port 49
  #   2019-05-07 [gw]: Updated with information from 0.7.0 document. Fix rssi and medium_type mapping.
  #   2019-05-07 [gw]: Also handling UM3033 devices.

  # Status Message
  def parse(<<settings::binary-1, battery::unsigned, temp::signed, rssi::signed, interface_status::binary>>, %{meta: %{frame_port:  24}}) do
    status_map = %{
      battery: battery,
      temp: temp,
      rssi: rssi * -1,
    }
    parse_reporting(status_map, settings, interface_status)
  end

  # Status Message
  def parse(<<settings::binary-1, interface_status::binary>>, %{meta: %{frame_port:  25}}) do
    parse_reporting(%{}, settings, interface_status)
  end

  # Boot Message
  def parse(<<0x00, serial::4-binary, firmware::3-binary, reset_reason>>, %{meta: %{frame_port:  99}}) do
    %{
      type: :boot,
      serial: Base.encode16(serial),
      firmware: Base.encode16(firmware),
      reset_reason: reset_reason,
    }
  end
  # Shutdown Message
  def parse(<<0x01>>, %{meta: %{frame_port:  99}}) do
    %{
      type: :shutdown,
    }
  end
  # Error Code Message
  def parse(<<0x10, error_code>>, %{meta: %{frame_port:  99}}) do
    %{
      type: :error,
      error_code: error_code,
    }
  end

  # Configuration Message
  def parse(_payload, %{meta: %{frame_port:  49}}) do
    %{
      type: :config_req,
    }
  end

  # MBus connect Message
  def parse(<<0x01, packet_info::binary-1, rest::binary>>, %{meta: %{frame_port: 53}}) do
    <<only_drh::1, mbus_fixed_header::1, _rfu::2, packets_to_follow::1, packet_number::3>> = packet_info
    packet_info_map = %{
      type: :mbus_connect,
      packet_number: packet_number,
      packets_to_follow: (packets_to_follow == 1),
      mbus_fixed_header: sent_or_not(mbus_fixed_header),
      only_drh: (only_drh == 1),
    }

    mbus_fixed = if mbus_fixed_header == 1 do
      <<bcd_ident_number::little-32, manufacturer_id::binary-2, sw_version::binary-1, medium::binary-1, access_number:: binary-1, status::binary-1, signature::binary-2, _drh_bytes::binary>> = rest

      %{
        bcd_ident_number: Base.encode16(<<bcd_ident_number::32>>),
        manufacturer_id: Base.encode16(manufacturer_id),
        sw_version: Base.encode16(sw_version),
        medium: Base.encode16(medium),
        access_number: Base.encode16(access_number),
        status: Base.encode16(status),
        signature: Base.encode16(signature),
      }
    else
      %{}
    end

    Map.merge(packet_info_map, mbus_fixed)
  end

  # Catchall for any other message.
  def parse(payload, %{meta: %{frame_port:  frame_port}}) do
    %{
      error: "unparseable_message",
      payload: Base.encode16(payload),
      meta_frame_port: frame_port,
    }
  end

  defp parse_reporting(map, <<settings::binary-1>>, interface_status) do
    <<_rfu::1, user_triggered::1, mbus::1, ssi::1, analog2_reporting::1, analog1_reporting::1, digital2_reporting::1, digital1_reporting::1>> = settings
    settings_map = %{
      user_triggered: (1 == user_triggered),
      mbus: (1 == mbus),
      ssi: (1 == ssi)
    }
    
    [digital1_reporting: digital1_reporting, digital2_reporting: digital2_reporting, analog1_reporting: analog1_reporting, analog2_reporting: analog2_reporting, mbus_reporting: mbus]
    |> Enum.filter(fn {_,y} -> y == 1 end)
    |> Enum.map(&elem(&1,0))
    |> parse_single_reporting(Map.merge(settings_map, map), interface_status)
  end

  defp parse_single_reporting([type | _more_types], map, <<status::binary-1, mbus_status, dr::binary>>) when type in [:mbus_reporting] do
    <<_rfu::4, parameter::4>> = status
    mbus_map = %{
      mbus_parameter: mbus_parameter(parameter),
      mbus_status: mbus_status,
    }

    [Map.merge(mbus_map, map)] ++ filter_and_flatmap_mbus_data(dr)
  end

  defp parse_single_reporting([type | more_types], map, <<settings::8, counter::little-32, rest::binary>>) when type in [:digital1_reporting, :digital2_reporting] do
    <<medium_type::4, _rfu::1, trigger_alert::1, trigger_mode::1, value_high::1>> = <<settings>>
    result = %{
      type => counter,
      "#{type}_medium_type" => medium_type(medium_type),
      "#{type}_trigger_alert" => %{0=>:ok, 1=>:alert}[trigger_alert],
      "#{type}_trigger_mode2" => %{0=>:disabled, 1=>:enabled}[trigger_mode],
      "#{type}_value_during_reporting" => %{0=>:low, 1=>:high}[value_high],
    }

    parse_single_reporting(more_types, Map.merge(map, result), rest)
  end

  # analog: both current (instant) and average value are sent
  defp parse_single_reporting([type | more_types], map, <<status_settings::binary-1, rest::binary>>) when type in [:analog1_reporting, :analog2_reporting] do
    <<average_flag::1, instant_flag::1, _rfu::4, _thresh_alert::1, mode::1>> = status_settings

    {new_map, new_rest} =
      {map, rest}
      |> parse_analog_value("#{type}_current_value", instant_flag)
      |> parse_analog_value("#{type}_average_value", average_flag)

    result_map = Map.put(new_map, "#{type}_mode", %{0 => "0..10V", 1 => "4..20mA"}[mode])
    parse_single_reporting(more_types, result_map, new_rest)
  end

  defp parse_single_reporting(_, map, _) do
    map
  end

  defp parse_analog_value({map, <<value::float-little-32, rest::binary>>}, key, 1) do
    {
      Map.put(map, key, value),
      rest
    }
  end
  defp parse_analog_value({map, rest}, _, 0), do: {map, rest}

  defp filter_and_flatmap_mbus_data(mbus_data) do
    mbus_data
    |> LibWmbus.Dib.parse_dib()
    |> Enum.map(fn
      %{data: data} = map ->
        Map.merge(map, data)
        |> Map.delete(:data)
    end)
    |> Enum.map(fn
      %{desc: "error codes", value: v} = map ->
        Map.merge(map, %{"error codes" => v, :unit => ""})
        |> Map.drop([:desc, :value])
      %{desc: d = "energy", value: v, unit: "Wh"} = map ->
        Map.merge(map, %{d => Float.round(v / 1000, 3), :unit => "kWh"})
        |> Map.drop([:desc, :value])
      %{desc: d, value: v} = map ->
        Map.merge(map, %{d => v})
        |> Map.drop([:desc, :value])
    end)
  end

  defp mbus_parameter(0x00), do: :ok
  defp mbus_parameter(0x01), do: :nothing_requested
  defp mbus_parameter(0x02), do: :bus_unpowered
  defp mbus_parameter(0x03), do: :no_response
  defp mbus_parameter(0x04), do: :empty_response
  defp mbus_parameter(0x05), do: :invalid_data
  defp mbus_parameter(_), do: :rfu

  defp medium_type(0x00), do: :not_available
  defp medium_type(0x01), do: :pulses
  defp medium_type(0x02), do: :water_in_liter
  defp medium_type(0x03), do: :electricity_in_wh
  defp medium_type(0x04), do: :gas_in_liter
  defp medium_type(0x05), do: :heat_in_wh
  defp medium_type(_),    do: :rfu

  defp sent_or_not(0), do: :not_sent
  defp sent_or_not(1), do: :sent
  defp sent_or_not(_), do: :unknown

  def tests() do
    [
      {
        :parse_hex,  "03E6172C50000000002000000000", %{meta: %{frame_port: 24}},  %{
          :battery => 230,
          :digital1_reporting => 0,
          :digital2_reporting => 0,
          :mbus => false,
          :rssi => -44,
          :ssi => false,
          :temp => 23,
          :user_triggered => false,
          "digital1_reporting_medium_type" => :heat_in_wh,
          "digital1_reporting_trigger_alert" => :ok,
          "digital1_reporting_trigger_mode2" => :disabled,
          "digital1_reporting_value_during_reporting" => :low,
          "digital2_reporting_medium_type" => :water_in_liter,
          "digital2_reporting_trigger_alert" => :ok,
          "digital2_reporting_trigger_mode2" => :disabled,
          "digital2_reporting_value_during_reporting" => :low
        },
      },
      { # Example Payload for UM3023 from docs v0.7.0
        :parse_hex, "0FF61A4B120100000010C40900004039C160404140C9D740", %{meta: %{frame_port: 24}}, %{
          :battery => 246,
          :digital1_reporting => 1,
          :digital2_reporting => 2500,
          :temp => 26,
          :rssi => -75,
          :mbus => false,
          :ssi => false,
          :user_triggered => false,
          "analog1_reporting_current_value" => 3.511793375015259,
          "analog1_reporting_mode" => "0..10V",
          "analog2_reporting_current_value" => 6.743316650390625,
          "analog2_reporting_mode" => "4..20mA",
          "digital1_reporting_medium_type" => :pulses,
          "digital1_reporting_trigger_alert" => :ok,
          "digital1_reporting_trigger_mode2" => :enabled,
          "digital1_reporting_value_during_reporting" => :low,
          "digital2_reporting_medium_type" => :pulses,
          "digital2_reporting_trigger_alert" => :ok,
          "digital2_reporting_trigger_mode2" => :disabled,
          "digital2_reporting_value_during_reporting" => :low,
        }
      },
      # Commented the following test, as it is using a library that is not publicly available yet
#      { # Example Payload for UM3033 from docs v0.7.0
#        :parse_hex, "63F51B361000000000100000000000000B2D4700009B102D5800000C0616160000046D0A0E5727", %{meta: %{frame_port: 24}}, [
#          %{
#            :battery => 245,
#            :digital1_reporting => 0,
#            :digital2_reporting => 0,
#            :temp => 27,
#            :rssi => -54,
#            :mbus => true,
#            :mbus_parameter => :ok,
#            :mbus_status => 0,
#            :ssi => false,
#            :user_triggered => true,
#            "digital1_reporting_medium_type" => :pulses,
#            "digital1_reporting_trigger_alert" => :ok,
#            "digital1_reporting_trigger_mode2" => :disabled,
#            "digital1_reporting_value_during_reporting" => :low,
#            "digital2_reporting_medium_type" => :pulses,
#            "digital2_reporting_trigger_alert" => :ok,
#            "digital2_reporting_trigger_mode2" => :disabled,
#            "digital2_reporting_value_during_reporting" => :low,
#          },
#          %{
#            :function_field => :current_value,
#            :memory_address => 0,
#            :sub_device => 0,
#            :tariff => 0,
#            :unit => "W",
#            "power" => 4700
#          },
#          %{
#            :function_field => :max_value,
#            :memory_address => 0,
#            :sub_device => 0,
#            :tariff => 1,
#            :unit => "W",
#            "power" => 5800
#          },
#          %{
#            :function_field => :current_value,
#            :memory_address => 0,
#            :sub_device => 0,
#            :tariff => 0,
#            :unit => "kWh",
#            "energy" => 1616.0
#          },
#          %{
#            :function_field => :current_value,
#            :memory_address => 0,
#            :sub_device => 0,
#            :tariff => 0,
#            :unit => "",
#            "datetime" => ~N[2018-07-23 14:10:00]
#          }
#        ]
#      },
      {
        :parse_hex,  "0350000000002006000000", %{meta: %{frame_port: 25}},  %{
          :digital1_reporting => 0,
          :digital2_reporting => 6,
          :mbus => false,
          :ssi => false,
          :user_triggered => false,
          "digital1_reporting_medium_type" => :heat_in_wh,
          "digital1_reporting_trigger_alert" => :ok,
          "digital1_reporting_trigger_mode2" => :disabled,
          "digital1_reporting_value_during_reporting" => :low,
          "digital2_reporting_medium_type" => :water_in_liter,
          "digital2_reporting_trigger_alert" => :ok,
          "digital2_reporting_trigger_mode2" => :disabled,
          "digital2_reporting_value_during_reporting" => :low
        },
      },

      { # Example Payload from docs 0.7.0
        :parse_hex, "0F12010000001000000000C0DA365C400B7E5E40C140C9D740DC73D940", %{meta: %{frame_port: 25}}, %{
          :digital1_reporting => 1,
          :digital2_reporting => 0,
          :mbus => false,
          :ssi => false,
          :user_triggered => false,
          "analog1_reporting_current_value" => 3.440847873687744,
          "analog1_reporting_average_value" => 3.47644305229187,
          "analog1_reporting_mode" => "0..10V",
          "analog2_reporting_current_value" => 6.743316650390625,
          "analog2_reporting_average_value" => 6.795392990112305,
          "analog2_reporting_mode" => "4..20mA",
          "digital1_reporting_medium_type" => :pulses,
          "digital1_reporting_trigger_alert" => :ok,
          "digital1_reporting_trigger_mode2" => :enabled,
          "digital1_reporting_value_during_reporting" => :low,
          "digital2_reporting_medium_type" => :pulses,
          "digital2_reporting_trigger_alert" => :ok,
          "digital2_reporting_trigger_mode2" => :disabled,
          "digital2_reporting_value_during_reporting" => :low,
        }
      },
      {
        :parse_hex,  "00D002A005000357020000803F27020000803F", %{meta: %{frame_port: 49}},  %{type: :config_req},
      },
      {
        :parse_hex, "01C888020969A732070415000000097409700C060C140B2D0B3B0B5A0B5E0B620C788910713C220C220C268C9010069B102D", %{meta: %{frame_port: 53}}, %{
          :type => :mbus_connect,
          :packet_number => 0,
          :packets_to_follow => true,
          :mbus_fixed_header => :sent,
          :only_drh => true,
          :bcd_ident_number => "69090288",
          :manufacturer_id => "A732",
          :sw_version => "07",
          :medium => "04",
          :access_number => "15",
          :status => "00",
          :signature => "0000"
        }
      },
      {
        :parse_hex, "01819B103B9B105A9B105E9410AD6F9410BB6F9410DA6F9410DE6F4C064C147C224C26CC901006DB102DDB103BDB105ADB105E848F0F6D046D", %{meta: %{frame_port: 53}}, %{
          :type => :mbus_connect,
          :packet_number => 1,
          :packets_to_follow => false,
          :mbus_fixed_header => :not_sent,
          :only_drh => true
        }
      },
      {
        :parse_hex,  "01", %{meta: %{frame_port: 99}}, %{type: :shutdown},
      },
      {
        :parse_hex,  "1001", %{meta: %{frame_port: 99}}, %{error_code: 1, type: :error},
      },
      {
        :parse_hex,  "00D701164C0007081002", %{meta: %{frame_port: 99}},  %{
          error: "unparseable_message",
          meta_frame_port: 99,
          payload: "00D701164C0007081002"
        },
      },
    ]
  end


end
