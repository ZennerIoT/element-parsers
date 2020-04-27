defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # ELEMENT IoT Parser for Nexlec D678C Insafe+ Carbon, Temperature and Humidity Sensor.
  #
  # Changelog:
  #   2020-02-28 [jb]: Initial implementation according to "D678C_Insafe+_Carbon_LoRa_Technical_Guide_EN.pdf"
  #

  # Real-Time Data
  def parse(<<0x72, co2_level, temperature, humidity, iaq_global::3, iaq_src::4, iaq_co2::3, iaq_dry::3, iaq_mould::3, iaq_dm::3, hci::2, frame_index::3>>, _meta) do
    %{
      product_type: :insafe_carbon_lora,
      message_type: :real_time_data,
      frame_index: frame_index,
    }
    |> add_range_with_scale(:co2_level, co2_level, 0..250, 0..5000, 255, :error)
    |> add_range_with_scale(:temperature, temperature, 0..250, 0..50, 255, :error)
    |> add_range_with_scale(:humidity, humidity, 0..200, 0..100, 255, :error)
    |> add_from_mapping(:iaq_global, iaq_global, mapping(~w(excellent good fair poor bad reserved reserved error)), :unknown)
    |> add_from_mapping(:iaq_src, iaq_src, mapping(~w(all drought_index mold_index mite_index co co2)), :unknown)
    |> add_from_mapping(:iaq_co2, iaq_co2, mapping(~w(excellent good fair poor bad reserved reserved error)), :unknown)
    |> add_from_mapping(:iaq_dry, iaq_dry, mapping(~w(excellent good fair poor bad reserved reserved error)), :unknown)
    |> add_from_mapping(:iaq_mould, iaq_mould, mapping(~w(excellent good fair poor bad reserved reserved error)), :unknown)
    |> add_from_mapping(:iaq_dm, iaq_dm, mapping(~w(excellent good fair poor bad reserved reserved error)), :unknown)
    |> add_from_mapping(:hci, hci, mapping(~w(good fair poor error)), :unknown)
  end

  # Product Information
  def parse(<<0x73, battery_level::2, hw_status::1, frame_index::3, _unused::2, product_activation, co2_autocalibration, year::6, month::4, day::5, hour::5, minute::6, _::6>>, _meta) do
    %{
      product_type: :insafe_carbon_lora,
      message_type: :product_information,
      frame_index: frame_index,
      product_datetime: "#{2000+year}-#{month}-#{day} #{hour}:#{minute}",
    }
    |> add_from_mapping(:battery_level, battery_level, mapping(~w(high medium low critical)), :unknown)
    |> add_from_mapping(:hardware_status, hw_status, mapping(~w(ok faulty)), :unknown)
    |> add_range_with_scale(:product_activation, product_activation, 0..250, 0..250, 255, :error)
    |> add_range_with_scale(:co2_autocalibration, co2_autocalibration, 0..250, 0..5000, 255, :error)
  end

  # Button Press
  def parse(<<0x74, button_press::3, frame_index::3, _::2>>, _meta) do
    %{
      product_type: :insafe_carbon_lora,
      message_type: :button_press,
      frame_index: frame_index,
    }
    |> add_from_mapping(:button_press, button_press, mapping(~w(short_press)), :reserved)
  end

  # Message datalog
  def parse(<<0x75, n2::3-binary, n1::3-binary, n0::3-binary, time_between::4, frame_index::3, _::1, _::binary>>, %{transceived_at: transceived_at}) do
    template = %{time_between: time_between} = %{
      product_type: :insafe_carbon_lora,
      message_type: :message_datalog,
      frame_index: frame_index,
    }
    |> add_range_with_scale(:time_between, time_between, 0..15, 0..150, nil, :error)

    Enum.map([{n0, time_between*0}, {n1, time_between*-1}, {n2, time_between*-2}], fn
      ({<<co2_level, temperature, humidity>>, minutes_before}) ->
        {
          template
          |> add_range_with_scale(:co2_level, co2_level, 0..250, 0..5000, 255, :error)
          |> add_range_with_scale(:temperature, temperature, 0..250, 0..50, 255, :error)
          |> add_range_with_scale(:humidity, humidity, 0..200, 0..100, 255, :error),
          [
            measured_at: Timex.shift(transceived_at, minutes: trunc(minutes_before))
          ]
        }
    end)
  end

  # Temperature alert
  def parse(<<0x76, temperature, threshold1::1, threshold2::1, frame_index::3, _::3>>, _meta) do
    %{
      product_type: :insafe_carbon_lora,
      message_type: :temperature_alert,
      frame_index: frame_index,
      temperature_threshold1: threshold1,
      temperature_threshold2: threshold2,
    }
    |> add_range_with_scale(:temperature, temperature, 0..250, 0..50, 255, :error)
  end

  # Co2 alert
  def parse(<<0x77, co2_level, frame_index::3, threshold1::1, threshold2::1, _::3>>, _meta) do
    %{
      product_type: :insafe_carbon_lora,
      message_type: :co2_alert,
      frame_index: frame_index,
      co2_threshold1: threshold1,
      co2_threshold2: threshold2,
    }
    |> add_range_with_scale(:co2_level, co2_level, 0..250, 0..5000, 255, :error)
  end

  # Product configuration
  def parse(<<0x78, co2_threshold1, co2_threshold2, sp1_start1::6, sp1_start2::6, sp2_start1::6, sp2_start2::6, sp1::binary-1, sp2::binary-1, altitude>>, _meta) do
    <<sp1_active::1, sp1_mo::1, sp1_tu::1, sp1_we::1, sp1_th::1, sp1_fr::1, sp1_sa::1, sp1_su::1>> = sp1
    <<sp2_active::1, sp2_mo::1, sp2_tu::1, sp2_we::1, sp2_th::1, sp2_fr::1, sp2_sa::1, sp2_su::1>> = sp2
    %{
      product_type: :insafe_carbon_lora,
      message_type: :product_configuration,

      sp1_start1_minutes: sp1_start1*30,
      sp1_start2_minutes: sp1_start2*30,
      sp2_start1_minutes: sp2_start1*30,
      sp2_start2_minutes: sp2_start2*30,

      sp1_active: sp1_active,
      sp1_monday_active: sp1_mo,
      sp1_tuesday_active: sp1_tu,
      sp1_wednesday_active: sp1_we,
      sp1_thursday_active: sp1_th,
      sp1_friday_active: sp1_fr,
      sp1_saturday_active: sp1_sa,
      sp1_sunday_active: sp1_su,

      sp2_active: sp2_active,
      sp2_monday_active: sp2_mo,
      sp2_tuesday_active: sp2_tu,
      sp2_wednesday_active: sp2_we,
      sp2_thursday_active: sp2_th,
      sp2_friday_active: sp2_fr,
      sp2_saturday_active: sp2_sa,
      sp2_sunday_active: sp2_su,

      altitude_meter: altitude*50,
    }
    |> add_range_with_scale(:co2_threshold1, co2_threshold1, 0..250, 0..5000, 255, :error)
    |> add_range_with_scale(:co2_threshold2, co2_threshold2, 0..250, 0..5000, 255, :error)
  end

  # Product general configuration
  def parse(<<0x79, flags::binary-1, meas_period, datalog_factor, temp_alert1, temp_alert2, temp_delta, humi_delta, co2_delta, keepalive, sw_version>>, _meta) do
    <<a::1, b::1, c::1, d::1, e::1, f::1, g::1, _::1>> = flags
    %{
      product_type: :insafe_carbon_lora,
      message_type: :product_general_configuration,

      activate_led_function: a,
      notification_active_button_press: b,
      activate_real_time_data: c,
      activate_datalog_function: d,
      activate_temperature_alerts: e,
      activate_co2_function: f,
      activate_keepalive_function: g,

      measurement_period: meas_period,
      datalog_decimator_factor: datalog_factor,

      keepalive_hours: keepalive,
      sw_version: sw_version,
    }
    |> add_range_with_scale(:temperature_threshold1_alert, temp_alert1, 0..250, 0..50, 255, :error)
    |> add_range_with_scale(:temperature_threshold2_alert, temp_alert2, 0..250, 0..50, 255, :error)
    |> add_range_with_scale(:temperature_delta, temp_delta, 0..250, 0..25, 255, :error)
    |> add_range_with_scale(:humidity_delta, humi_delta, 0..200, 0..100, 255, :error)
    |> add_range_with_scale(:co2_delta, co2_delta, 0..250, 0..5000, 255, :error)
  end

  # Keepalive Message
  def parse(<<0x7A>>, _meta) do
    %{
      product_type: :insafe_carbon_lora,
      message_type: :keep_alive,
    }
  end

  # Fallback
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  # Transforming [:a, :b, :c] to %{0 -> :a, 1 -> :b, 2 -> :c}
  defp mapping(atoms) do
    atoms
    |> Enum.with_index()
    |> Enum.into(%{}, fn({atom, index}) -> {index, atom} end)
  end

  defp add_from_mapping(row, column, value, mapping, error_code) do
    case Map.get(mapping, value, nil) do
      nil ->
        Map.merge(row, %{
          "#{column}_error" => error_code,
        })
      new_value ->
        Map.merge(row, %{
          column => new_value,
        })
    end
  end

  defp add_range_with_scale(row, column, value, _range, _scale, error_value, error_code) when value == error_value do
    Map.merge(row, %{
      "#{column}_error" => error_code,
    })
  end
  defp add_range_with_scale(row, column, value, %Range{first: 0, last: range2}, %Range{first: 0, last: scale2}, _error_value, _error_code) do
    step = scale2 / range2
    new_value = value * step
    Map.merge(row, %{
      column => new_value,
    })
  end

  def fields do
    [
      %{
        field: "co2_level",
        display: "CO2 Level",
        unit: "ppm",
      },
      %{
        field: "temperature",
        display: "Temperatur",
        unit: "°C",
      },
      %{
        field: "humidity",
        display: "Humidity",
        unit: "%rh",
      },

      %{
        field: "product_activation",
        display: "Product Activation",
        unit: "month",
      },
      %{
        field: "time_between",
        display: "Time Between",
        unit: "min",
      },

      %{
        field: "co2_autocalibration",
        display: "CO2 Autocalibration",
        unit: "ppm",
      },

      %{
        field: "message_type",
        display: "Message Type",
      },
    ]
  end

  def tests() do
    [
      # Manual testing
      {:parse_hex, "72424200000000", %{meta: %{frame_port: 1}}, %{
        co2_level: 1320.0,
        frame_index: 0,
        hci: "good",
        humidity: 0.0,
        iaq_co2: "excellent",
        iaq_dm: "excellent",
        iaq_dry: "excellent",
        iaq_global: "excellent",
        iaq_mould: "excellent",
        iaq_src: "all",
        message_type: :real_time_data,
        product_type: :insafe_carbon_lora,
        temperature: 13.200000000000001
      }},

      # Manual testing errors
      {:parse_hex, "72FFFFFFFFFFFF", %{meta: %{frame_port: 1}}, %{
        :frame_index => 7,
        :hci => "error",
        :iaq_co2 => "error",
        :iaq_dm => "error",
        :iaq_dry => "error",
        :iaq_global => "error",
        :iaq_mould => "error",
        :message_type => :real_time_data,
        :product_type => :insafe_carbon_lora,
        "co2_level_error" => :error,
        "humidity_error" => :error,
        "iaq_src_error" => :unknown,
        "temperature_error" => :error
      }},

      # Real time data from docs
      {:parse_hex, "726a75508b0000", %{meta: %{frame_port: 1}}, %{
        co2_level: 2120.0,
        frame_index: 0,
        hci: "good",
        humidity: 40.0,
        iaq_co2: "bad",
        iaq_dm: "excellent",
        iaq_dry: "excellent",
        iaq_global: "bad",
        iaq_mould: "excellent",
        iaq_src: "co2",
        message_type: :real_time_data,
        product_type: :insafe_carbon_lora,
        temperature: 23.400000000000002
      }},

      # Product status from docs
      {:parse_hex, "73000A124d28fb40", %{meta: %{frame_port: 1}}, %{
        battery_level: "high",
        co2_autocalibration: 360.0,
        frame_index: 0,
        hardware_status: "ok",
        message_type: :product_information,
        product_activation: 10.0,
        product_datetime: "2019-4-20 15:45",
        product_type: :insafe_carbon_lora
      }},

      # Button press from docs
      {:parse_hex, "7400", %{meta: %{frame_port: 1}}, %{
        button_press: "short_press",
        frame_index: 0,
        message_type: :button_press,
        product_type: :insafe_carbon_lora
      }},

      # Message datalog from docs
      {:parse_hex, "75 1a674d 186a4c 196f4a 6e", %{meta: %{frame_port: 1}, transceived_at: test_datetime("2020-02-24T12:00:00Z")}, [
        {%{
          co2_level: 500.0,
          frame_index: 7,
          humidity: 37.0,
          message_type: :message_datalog,
          product_type: :insafe_carbon_lora,
          temperature: 22.200000000000003,
          time_between: 60.0
        }, [measured_at: test_datetime("2020-02-24 12:00:00Z")]},
        {%{
          co2_level: 480.0,
          frame_index: 7,
          humidity: 38.0,
          message_type: :message_datalog,
          product_type: :insafe_carbon_lora,
          temperature: 21.200000000000003,
          time_between: 60.0
        }, [measured_at: test_datetime("2020-02-24 11:00:00Z")]},
        {%{
          co2_level: 520.0,
          frame_index: 7,
          humidity: 38.5,
          message_type: :message_datalog,
          product_type: :insafe_carbon_lora,
          temperature: 20.6,
          time_between: 60.0
        }, [measured_at: test_datetime("2020-02-24 10:00:00Z")]}
      ]},

      # Temperature alerts from docs
      {:parse_hex, "7673c0", %{meta: %{frame_port: 1}}, %{
        frame_index: 0,
        message_type: :temperature_alert,
        product_type: :insafe_carbon_lora,
        temperature: 23.0,
        temperature_threshold1: 1,
        temperature_threshold2: 1
      }},

      # Co2 alerts from docs
      {:parse_hex, "773710", %{meta: %{frame_port: 1}}, %{
        co2_level: 1.1e3,
        co2_threshold1: 1,
        co2_threshold2: 0,
        frame_index: 0,
        message_type: :co2_alert,
        product_type: :insafe_carbon_lora
      }},

      # Product configuration
      {:parse_hex, "783255761F482C7E02", %{meta: %{frame_port: 1}}, %{
        altitude_meter: 100,
        co2_threshold1: 1.0e3,
        co2_threshold2: 1.7e3,
        message_type: :product_configuration,
        product_type: :insafe_carbon_lora,
        sp1_active: 0,
        sp1_friday_active: 1,
        sp1_monday_active: 0,
        sp1_saturday_active: 0,
        sp1_start1_minutes: 870,
        sp1_start2_minutes: 990,
        sp1_sunday_active: 0,
        sp1_thursday_active: 1,
        sp1_tuesday_active: 1,
        sp1_wednesday_active: 0,
        sp2_active: 0,
        sp2_friday_active: 1,
        sp2_monday_active: 1,
        sp2_saturday_active: 1,
        sp2_start1_minutes: 1830,
        sp2_start2_minutes: 240,
        sp2_sunday_active: 0,
        sp2_thursday_active: 1,
        sp2_tuesday_active: 1,
        sp2_wednesday_active: 1
      }},

      # Product general configuration
      {:parse_hex, "79E20A065A730A0A0C1816", %{meta: %{frame_port: 1}}, %{
        activate_co2_function: 0,
        activate_datalog_function: 0,
        activate_keepalive_function: 1,
        activate_led_function: 1,
        activate_real_time_data: 1,
        activate_temperature_alerts: 0,
        co2_delta: 240.0,
        datalog_decimator_factor: 6,
        humidity_delta: 5.0,
        keepalive_hours: 24,
        measurement_period: 10,
        message_type: :product_general_configuration,
        notification_active_button_press: 1,
        product_type: :insafe_carbon_lora,
        sw_version: 22,
        temperature_delta: 1.0,
        temperature_threshold1_alert: 18.0,
        temperature_threshold2_alert: 23.0
      }},

      # Keep alive
      {:parse_hex, "7A", %{meta: %{frame_port: 1}}, %{message_type: :keep_alive, product_type: :insafe_carbon_lora}},
    ]
  end

  # Helper for testing
  defp test_datetime(iso8601) do
    {:ok, datetime, _} = DateTime.from_iso8601(iso8601)
    datetime
  end
end
