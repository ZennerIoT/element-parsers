defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for globalsat indoor climate monitor
  #
  # Author F. Wolf fw@alpha-omega-technology.de
  #
  # Changelog:
  #   2019-xx-xx [fw]: Initial implementation
  #   2020-01-27 [jb]: Added taupunkt calculation
  #

  def parse(<<type::big-8, temp::signed-big-16, humid::big-16, sens::big-16>>, _meta) do
    sensor = case type do
      1 -> "CO2"
      2 -> "CO"
      3 -> "PM 2.5"
      _ -> "unknown"
    end

    temperature = temp/100
    humidity = humid/100

    %{
      temperature: temperature,
      humidity: humidity,
      sens: sens,
      type: sensor,
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
        "field" => "humidity",
        "display" => "rel. Luftfeuchte",
        "unit" => "%"
      },
      %{
        "field" => "temperature",
        "display" => "Temperature",
        "unit" => "°C"
      },
      %{
        "field" => "sens",
        "display" => "Concentration",
        "unit" => "ppm"
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
      {:parse_hex, "03001B2710004C", %{meta: %{frame_port: 2}}, %{
        dew_temperature: 0.2699999999999999,
        humidity: 100.0,
        sens: 76,
        temperature: 0.27,
        type: "PM 2.5",
        vapor_pressure: 6.228860593456033,
        water_steam_density: 4.996502918065849
      }},
    ]
  end

end