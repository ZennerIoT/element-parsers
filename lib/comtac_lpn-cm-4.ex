defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for comtac LPN CM4 - Temperature and Humidity Sensor.
  #
  # Changelog:
  #   2020-02-24 [jb]: Initial implementation according to E1446-CM-4_EN_V00.pdf
  #   2020-02-28 [jb]: Added "Taupunkt" calculation.
  #   2020-05-12 [jb]: Fixed single temperature value.
  #


  defp default_measurement_rate(), do: 3840 # Seconds


  # Port 3: Application Data
  def parse(<<1, status::binary-2, battery_voltage, rest::binary>>, %{meta: %{frame_port: 3}, transceived_at: transceived_at}) do
    %{
      message_type: :app_data,
      battery: Kernel.trunc(battery_voltage * 0.5),
    }
    |> Map.merge(parse_status(status))
    |> parse_payload(rest)
    |> case do
      rows when is_list(rows) ->
        Enum.map(rows, fn(%{_measured_offset: offset} = row) ->
          {
            Map.drop(row, [:_measured_offset]),
            [measured_at: Timex.shift(transceived_at, seconds: offset)]
          }
        end)
      row ->
        row
    end
  end

  # Port 100: Configuration Data
  def parse(<<
    1,
    status::binary-2, battery_voltage,
    meas_rate::16-little, history_trigger,
    temp_offset::16-little, temp_max, temp_min,
    hum_offset, hum_max, hum_min,
    _rest::binary
  >>, %{meta: %{frame_port: 100}}) do
    %{
      message_type: :config_data,
      battery: Kernel.trunc(battery_voltage * 0.5),
      measurement_rate: meas_rate,
      history_trigger: history_trigger,
      temperature_offset: temp_offset/100,
      temperature_max: temp_max,
      temperature_min: temp_min,
      humidity_offset: hum_offset,
      humidity_max: hum_max,
      humidity_min: hum_min,
    }
    |> Map.merge(parse_status(status))
  end

  # Port 101: Info Data
  def parse(<<1, status::binary-2, battery_voltage, app_main_version, app_minor_version, _rest::binary>>, %{meta: %{frame_port: 101}}) do
    %{
      message_type: :info,
      app_version: "#{app_main_version}.#{app_minor_version}",
      battery: Kernel.trunc(battery_voltage * 0.5),
    }
    |> Map.merge(parse_status(status))
  end

  # Fallback
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  defp parse_payload(acc, <<
    04,
    temp0::16-signed, humi0::8, # According to documentation, these should be "little", but it is not.
    temp1::16-signed, humi1::8,
    temp2::16-signed, humi2::8,
    temp3::16-signed, humi3::8,
    temp4::16-signed, humi4::8,
    temp5::16-signed, humi5::8,
    temp6::16-signed, humi6::8,
    temp7::16-signed, humi7::8,
    rest::binary
  >>) do
    [
      {0, temp0, humi0},
      {1, temp1, humi1},
      {2, temp2, humi2},
      {3, temp3, humi3},
      {4, temp4, humi4},
      {5, temp5, humi5},
      {6, temp6, humi6},
      {7, temp7, humi7},
    ] |> Enum.map(fn({factor, temp, humi}) ->
      acc
      |> add_temp_and_humidty(temp, humi)
      |> Map.merge(%{
        _measured_offset: -1 * factor * default_measurement_rate(),
      })
      |> parse_payload(rest)
    end)
  end
  defp parse_payload(acc, <<03, temp::16-signed, humi::8, rest::binary>>) do
    acc
    |> add_temp_and_humidty(temp, humi)
    |> parse_payload(rest)
  end
  defp parse_payload(acc, <<>>), do: acc
  defp parse_payload(acc, <<rest::binary>>), do: Map.merge(acc, %{error: "unknown_binary_part: #{inspect rest}"})

  defp add_temp_and_humidty(acc, temp, humi) when temp == 25000 or humi == 250 do
    # Handling invalid values according to docs.
    Map.merge(acc, %{
      temperature_invalid: 1,
      humidity_invalid: 1,
    })
  end
  defp add_temp_and_humidty(acc, temp, humi) do
    acc
    |> Map.merge(%{
      temperature: temp/100,
      humidity: humi,
    })
    |> Map.merge(taupunkt(temp/100, humi))
  end

  defp parse_status(<<
    0::1, 0::1, bat_low::1, last_temp_valid::1, ext_mem::1, acc::1, temp_i2c::1, temp_pt100::1,
    0::1, 0::1, info_req::1, config_rx::1, button::1, alarming::1, history::1, async::1,
  >>) do
    event_type = cond do
      async == 1 -> :async
      history == 1 -> :history
      alarming == 1 -> :alarming
      button == 1 -> :button
      config_rx == 1 -> :config_rx
      info_req == 1 -> :info_req
      true -> :unknown
    end
    %{
      battery_low: bat_low,
      last_temp_valid: last_temp_valid,
      ext_mem: ext_mem,
      acc: acc,
      temp_i2c: temp_i2c,
      temp_pt100: temp_pt100,
      event_type: event_type,
    }
  end


  # Given temperature in celsius and relative humidity in percent
  # it will return dampfdruck, dampfdichte, taupunkttemperatur
  defp taupunkt(temp, rel) when rel >= 0 and rel <= 100 do
    mw = 18.016 # Molekulargewicht des Wasserdampfes (kg/kmol)
    gk = 8214.3 # universelle Gaskonstante (J/(kmol*K))
    t0 = 273.15 # Absolute Temperatur von 0 °C (Kelvin)
    tk = temp + t0 # Temperatur in Kelvin

    {a, b} = if temp >= 0 do
      {7.5, 237.3}
    else
      {7.6, 240.7}
    end

    # Sättigungsdampfdruck (hPa)
    sdd = 6.1078 * :math.pow(10, (a*temp)/(b+temp))

    # Dampfdruck (hPa)
    dd = sdd * (rel/100)

    # Wasserdampfdichte bzw. absolute Feuchte (g/m3)
    af = :math.pow(10,5) * mw/gk * dd/tk

    # v-Parameter
    v = :math.log10(dd/6.1078)

    # Taupunkttemperatur (°C)
    td = (b*v) / (a-v)

    %{
      dew_temperature: td, # Taupunkttemperatur
      water_steam_density: af, # Wasserdampfdichte
      vapor_pressure: dd, # Dampfdruck
    }
  end
  defp taupunkt(_temp, _rel) do
    %{}
  end

  def fields do
    [
      %{
        field: "temperature",
        display: "Temperatur",
        unit: "°C",
      },
      %{
        field: "humidity",
        display: "Luftfeuchtigkeit",
        unit: "%",
      },
      %{
        field: "battery",
        display: "Batterie",
        unit: "%",
      },
      %{
        field: "event_type",
        display: "Event",
      },
      %{
        field: "measurement_rate",
        display: "Messrate",
        unit: "s",
      },

      # Calculated from taupunkt()
      %{
        field: "dew_temperature",
        display: "Tautemperatur",
        unit: "°C"
      },
      %{
        field: "water_steam_density",
        display: "Wasserdampfdichte",
        unit: "g/m3"
      },
      %{
        field: "vapor_pressure",
        display: "Dampfdruck",
        unit: "hPa"
      },
    ]
  end

  def tests() do
    [
      {:parse_hex, "011202C804096A22096A21096622096921095C21095721095721094820", %{meta: %{frame_port: 3}, transceived_at: test_datetime("2020-02-24T12:00:00Z")}, [
        {%{
          acc: 0,
          battery: 100,
          battery_low: 0,
          dew_temperature: 7.270188984784662,
          event_type: :history,
          ext_mem: 0,
          humidity: 34,
          last_temp_valid: 1,
          message_type: :app_data,
          temp_i2c: 1,
          temp_pt100: 0,
          temperature: 24.1,
          vapor_pressure: 10.205463591647652,
          water_steam_density: 7.530064350214593
        }, [measured_at: test_datetime("2020-02-24 12:00:00Z")]},
        {%{
          acc: 0,
          battery: 100,
          battery_low: 0,
          dew_temperature: 6.835231577308151,
          event_type: :history,
          ext_mem: 0,
          humidity: 33,
          last_temp_valid: 1,
          message_type: :app_data,
          temp_i2c: 1,
          temp_pt100: 0,
          temperature: 24.1,
          vapor_pressure: 9.905302897775663,
          water_steam_density: 7.308591869325929
        }, [measured_at: test_datetime("2020-02-24 10:56:00Z")]},
        {%{
          acc: 0,
          battery: 100,
          battery_low: 0,
          dew_temperature: 7.235173500131055,
          event_type: :history,
          ext_mem: 0,
          humidity: 34,
          last_temp_valid: 1,
          message_type: :app_data,
          temp_i2c: 1,
          temp_pt100: 0,
          temperature: 24.06,
          vapor_pressure: 10.181006668947344,
          water_steam_density: 7.51302990324025
        }, [measured_at: test_datetime("2020-02-24 09:52:00Z")]},
        {%{
          acc: 0,
          battery: 100,
          battery_low: 0,
          dew_temperature: 6.826508879110664,
          event_type: :history,
          ext_mem: 0,
          humidity: 33,
          last_temp_valid: 1,
          message_type: :app_data,
          temp_i2c: 1,
          temp_pt100: 0,
          temperature: 24.09,
          vapor_pressure: 9.899363838384009,
          water_steam_density: 7.304455490278295
        }, [measured_at: test_datetime("2020-02-24 08:48:00Z")]},
        {%{
          acc: 0,
          battery: 100,
          battery_low: 0,
          dew_temperature: 6.713109791224383,
          event_type: :history,
          ext_mem: 0,
          humidity: 33,
          last_temp_valid: 1,
          message_type: :app_data,
          temp_i2c: 1,
          temp_pt100: 0,
          temperature: 23.96,
          vapor_pressure: 9.822438298922272,
          water_steam_density: 7.2508655669852455
        }, [measured_at: test_datetime("2020-02-24 07:44:00Z")]},
        {%{
          acc: 0,
          battery: 100,
          battery_low: 0,
          dew_temperature: 6.669492773707506,
          event_type: :history,
          ext_mem: 0,
          humidity: 33,
          last_temp_valid: 1,
          message_type: :app_data,
          temp_i2c: 1,
          temp_pt100: 0,
          temperature: 23.91,
          vapor_pressure: 9.792990728946211,
          water_steam_density: 7.230344324892815
        }, [measured_at: test_datetime("2020-02-24 06:40:00Z")]},
        {%{
          acc: 0,
          battery: 100,
          battery_low: 0,
          dew_temperature: 6.669492773707506,
          event_type: :history,
          ext_mem: 0,
          humidity: 33,
          last_temp_valid: 1,
          message_type: :app_data,
          temp_i2c: 1,
          temp_pt100: 0,
          temperature: 23.91,
          vapor_pressure: 9.792990728946211,
          water_steam_density: 7.230344324892815
        }, [measured_at: test_datetime("2020-02-24 05:36:00Z")]},
        {%{
          acc: 0,
          battery: 100,
          battery_low: 0,
          dew_temperature: 6.0929923998638795,
          event_type: :history,
          ext_mem: 0,
          humidity: 32,
          last_temp_valid: 1,
          message_type: :app_data,
          temp_i2c: 1,
          temp_pt100: 0,
          temperature: 23.76,
          vapor_pressure: 9.411015456937292,
          water_steam_density: 6.951835307937581
        }, [measured_at: test_datetime("2020-02-24 04:32:00Z")]}
      ]
      },
      {:parse_hex, "010201C8000F0400003200004614", %{meta: %{frame_port: 100}}, %{
        acc: 0,
        battery: 100,
        battery_low: 0,
        event_type: :async,
        ext_mem: 0,
        history_trigger: 4,
        humidity_max: 70,
        humidity_min: 20,
        humidity_offset: 0,
        last_temp_valid: 0,
        measurement_rate: 3840,
        temp_i2c: 1,
        temp_pt100: 0,
        temperature_max: 50,
        temperature_min: 0,
        temperature_offset: 0.0,
        message_type: :config_data
      }},
      {:parse_hex, "010201C80100", %{meta: %{frame_port: 101}}, %{
        acc: 0,
        app_version: "1.0",
        battery: 100,
        battery_low: 0,
        event_type: :async,
        ext_mem: 0,
        last_temp_valid: 0,
        message_type: :info,
        temp_i2c: 1,
        temp_pt100: 0
      }},
      {:parse_hex, "011204C80302D347",
        %{
          meta: %{
            frame_port: 3,
          },
          transceived_at: test_datetime("2020-02-24T12:00:00Z")
        },
        %{
          acc: 0,
          battery: 100,
          battery_low: 0,
          dew_temperature: 2.332753960374585,
          event_type: :alarming,
          ext_mem: 0,
          humidity: 71,
          last_temp_valid: 1,
          message_type: :app_data,
          temp_i2c: 1,
          temp_pt100: 0,
          temperature: 7.23,
          vapor_pressure: 7.225952271070698,
          water_steam_density: 5.652438820473279
        }
      },
    ]
  end

  # Helper for testing
  defp test_datetime(iso8601) do
    {:ok, datetime, _} = DateTime.from_iso8601(iso8601)
    datetime
  end
end
