defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for comtac LPN CM1
  # According to documentation provided ThingPark Market
  # Link: http://www.comtac.ch/de/produkte/lora/condition-monitoring/lpn-cm-1.html
  # Documentation: https://drive.google.com/file/d/0B6TBYAxODZHHa29GVWFfN0tIYjQ/view
  #
  # Changelog:
  #   2019-xx-xx [jb]: Initial implementation.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #   2020-01-08 [jb]: Added Taupunkttemperatur calculation.
  #

  def parse(<<
              status::binary-1,
              _mintemp::signed-8,
              _maxtemp::signed-8,
              _minhum::signed-8,
              _maxhum::signed-8,
              sendinterval::16,
              battery::16,
              temperature::signed-16,
              humidity::signed-16
            >>, _meta) do

    <<
      _max_temp_on::1,
      _min_temp_on::1,
      0::1,
      _tx_on_event::1,
      _max_hum_on::1,
      _min_hum_on::1,
      0::1,
      _booster_on::1
    >> = status

    temperature = temperature/100
    humidity = humidity/100

    %{
      send_interval: sendinterval,
      temperature_c: temperature,
      humidity_percent: humidity,
      battery_volt: battery/ 1000,
    }
    |> Map.merge(taupunkt(temperature, humidity))
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
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
        field: "humidity_percent",
        display: "Humidity",
        unit: "%"
      },
      %{
        field: "temperature_c",
        display: "Temperature",
        unit: "°C"
      },
      %{
        field: "battery_volt",
        display: "Battery",
        unit: "V"
      },
      %{
        field: "send_interval",
        display: "Intervall",
        unit: "min"
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
      {:parse_hex, "00F1F10000000F0AA708610E7D", %{meta: %{frame_port: 3}}, %{
        battery_volt: 2.727,
        dew_temperature: 6.201028481630173,
        humidity_percent: 37.09,
        send_interval: 15,
        temperature_c: 21.45,
        vapor_pressure: 9.481581259298867,
        water_steam_density: 7.05888070029484
      }},
    ]
  end

end
