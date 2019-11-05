defmodule Parser do

  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for lobaro oskar v2 sensor. smart waste ultrasonic sensor
  # According to documentation provided by lobaro:
  # https://github.com/lobaro/docs/wiki/Usonic-Range
  #
  # If there is a profile named "oscar" one can set the fields "amplitude" and "width"
  # both need to by of type "integer" and are used as min value to be considered a valid reading.
  # Amplitude defaults to 100 and width to 50.
  # If after filtering multiple values seem valid, a median is calculated.
  #
  # Changelog:
  #   2019-10-04 [nk]: Initial implementation according documentation provided by Lobaro
  #

  def preloads do
    [device: [profile_data: [:profile]]]
  end

  def parse(<<fw::24, vbat::little-16, temp::little-16-signed>>, %{meta: %{frame_port: 1 }}) do
    %{
      messagetype: "status",
      temperature: temp / 10,
      battery: vbat / 1000
    }
  end

  def parse(<<vbat :: little - 16, temp :: little - 16 - signed, _res, data :: binary>>, %{meta: %{frame_port: 2}} = meta) do
    min_width = get_min_width(meta)
    min_amplitude = get_min_amplitude(meta)
    readings = for <<dist :: little - 32, tof_us :: little - 16, width, amplitude <- data>> do
      %{distance1_mm: dist, tof_us: tof_us, width: width, amplitude: amplitude}
    end
    |> Enum.filter(fn
      %{width: width, amplitude: amplitude} ->
        width >= min_width && amplitude >= min_amplitude
    end)
    |> Enum.sort_by(fn %{distance1_mm: dist} -> dist end)

    num_readings = length(readings)

    cond do
      num_readings == 0 ->
        []
      rem(num_readings, 2) == 1 ->
        dist = readings
               |> Enum.at(div(num_readings, 2))
               |> get([:distance1_mm])
        %{
          temperature: temp / 10,
          distance1_m: dist / 1000,
          distance1_mm: dist
        }
      true ->
        one = readings
              |> Enum.at(div(num_readings, 2) - 1)
              |> get([:distance1_mm])
        two = readings
              |> Enum.at(div(num_readings, 2))
              |> get([:distance1_mm])
        dist = div(one + two, 2)
        %{
          temperature: temp / 10,
          distance1_m: dist / 1000,
          distance1_mm: dist
        }
    end
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  def get_min_amplitude(meta) do
    get(meta, [:device, :fields, :oscar, :amplitude], 100)
  end

  def get_min_width(meta) do
    get(meta, [:device, :fields, :oscar, :width], 50)
  end

  def fields do
    [
      %{
        field: "temperature",
        display: "Temperature",
        unit: "°C"
      },
      %{
        field: "distance1_mm",
        display: "Distance",
        unit: "mm"
      },
    ]
  end

  def tests() do
    [
      {:parse_hex, "5B0DE6000158080000113181DB", %{meta: %{frame_port: 2}}, %{distance1_m: 2.136, distance1_mm: 2136, temperature: 23.0}},

      {:parse_hex, "5F0DE90001930100009709EFF5", %{meta: %{frame_port: 2}}, %{distance1_m: 0.403, distance1_mm: 403, temperature: 23.3}},

      {:parse_hex, "2E0AF000017C0100001009A5EB", %{meta: %{frame_port: 2}}, %{distance1_m: 0.38, distance1_mm: 380, temperature: 24.0}},
    ]
  end
end