defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for NAS "Pulse + Analog Reader UM3023"  v0.5.0 and v0.7.0
  # Author NKlein
  # Link: https://www.nasys.no/product/lorawan-pulse-analog-reader/
  # Documentation:
  #      0.5.0: https://www.nasys.no/wp-content/uploads/Pulse-Analog-Reader_UM3023.pdf
  #      0.7.0: https://www.nasys.no/wp-content/uploads/Pulse_readeranalog_UM3023.pdf

  # Changelog
  #   2018-09-04 [jb]: Added tests. Handling Configuration request on port 49
  #   2019-05-07 [gw]: Updated with information from 0.7.0 document. Fix rssi and medium_type mapping.

  # Status Message
  def parse(<<settings, battery::unsigned, temp::signed, rssi::signed, interface_status::binary>>, %{meta: %{frame_port:  24}}) do
    map = %{
      battery: battery,
      temp: temp,
      rssi: rssi * -1,
    }
    parse_reporting(settings, interface_status)
    |> Map.merge(map)

  end

  # Status Message
  def parse(<<settings, interface_status::binary>>, %{meta: %{frame_port:  25}}) do
    parse_reporting(settings, interface_status)
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

  # Catchall for any other message.
  def parse(payload, %{meta: %{frame_port:  frame_port}}) do
    %{
      error: "unparseable_message",
      payload: Base.encode16(payload),
      meta_frame_port: frame_port,
    }
  end

  def parse_reporting(settings, interface_status) do
    <<_rfu::1, user_triggered::1, mbus::1, ssi::1, analog2_reporting::1, analog1_reporting::1, digital2_reporting::1, digital1_reporting::1>> = <<settings>>
    map = %{
      user_triggered: (1 == user_triggered),
      mbus: (1 == mbus),
      ssi: (1 == ssi)
    }

    reportingKeys = Enum.filter([digital1_reporting: digital1_reporting, digital2_reporting: digital2_reporting, analog1_reporting: analog1_reporting, analog2_reporting: analog2_reporting], fn {_,y} -> y == 1 end)
    |> Enum.map(&elem(&1,0))

    parse_single_reporting(reportingKeys, interface_status)
    |> Map.merge(map)
  end

  def parse_single_reporting([type | more_types], <<settings::8, counter::little-32, rest::binary>>) when type in [:digital1_reporting, :digital2_reporting] do
    <<medium_type::4, _rfu::1, trigger_alert::1, trigger_mode::1, value_high::1>> = <<settings>>
    result = %{
      type => counter,
      "#{type}_medium_type" => medium_type(medium_type),
      "#{type}_trigger_alert" => %{0=>:ok, 1=>:alert}[trigger_alert],
      "#{type}_trigger_mode2" => %{0=>:disabled, 1=>:enabled}[trigger_mode],
      "#{type}_value_during_reporting" => %{0=>:low, 1=>:high}[value_high],
    }

    result
    |> Map.merge(parse_single_reporting(more_types, rest))
  end

  # analog: both current (instant) and average value are sent
  def parse_single_reporting([type | more_types], <<status_settings, rest::binary>>) when type in [:analog1_reporting, :analog2_reporting] do
    <<average_flag::1, instant_flag::1, _rfu::4, _thresh_alert::1, mode::1>> = <<status_settings>>

    {map, new_rest} =
      {%{}, rest}
      |> parse_analog_value("#{type}_current_value", instant_flag)
      |> parse_analog_value("#{type}_average_value", average_flag)

    map
    |> Map.put("#{type}_mode", %{0 => "0..10V", 1 => "4..20mA"}[mode])
    |> Map.merge(parse_single_reporting(more_types, new_rest))
  end

  def parse_single_reporting(_, _) do
    %{}
  end

  def parse_analog_value({map, <<value::float-little-32, rest::binary>>}, key, 1) do
    {
      Map.put(map, key, value),
      rest
    }
  end
  def parse_analog_value({map, rest}, _, 0), do: {map, rest}

  def medium_type(0x00), do: :not_available
  def medium_type(0x01), do: :pulses
  def medium_type(0x02), do: :water_in_liter
  def medium_type(0x03), do: :electricity_in_wh
  def medium_type(0x04), do: :gas_in_liter
  def medium_type(0x05), do: :heat_in_wh
  def medium_type(_),    do: :rfu


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
      {
        :parse_hex, "4F46185D503000000020820F00004229CE6E4042F5D56940", %{meta: %{frame_port: 24}}, %{}
      },
      { # Example Payload from docs v0.7.0
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
