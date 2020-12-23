defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for DECENTLAB DL-MBX-001/002/003 Ultrasonic Distance Sensor
  # According to documentation:
  #   https://cdn.decentlab.com/download/datasheets/Decentlab-DL-MBX-datasheet.pdf
  #
  # Changelog
  #   2020-12-23 [jb]: Initial implementation

  def parse(<<2, device_id::16, flags::binary-2, rest::binary>>, _meta) do
    <<_::14, battery?::1, distance?::1>> = flags

    {distance, rest} = parse_distance(distance?, rest)
    {battery, _rest} = parse_battery(battery?, rest)

    %{device_id: device_id}
    |> Map.merge(distance)
    |> Map.merge(battery)
  end

  def parse(payload, meta) do
    Logger.warn(
      "Could not parse payload #{inspect(payload)} with frame_port #{
        inspect(get_in(meta, [:meta, :frame_port]))
      }"
    )

    []
  end

  def parse_distance(1, <<distance::16, samples::16, rest::binary>>) do
    {%{distance: distance, samples: samples}, rest}
  end

  def parse_distance(0, rest), do: {%{}, rest}

  def parse_battery(1, <<battery::16, rest::binary>>) do
    {%{battery: battery / 1000}, rest}
  end

  def parse_battery(0, rest), do: {%{}, rest}

  def fields do
    [
      %{
        "field" => "distance",
        "display" => "Distance",
        "unit" => "mm"
      },
      %{
        "field" => "samples",
        "display" => "Samples"
      },
      %{
        "field" => "device_id",
        "display" => "Device-ID"
      },
      %{
        "field" => "battery",
        "display" => "Battery",
        "unit" => "V"
      }
    ]
  end

  def tests() do
    [
      {
        :parse_hex,
        "02012f00020bb1",
        %{},
        %{battery: 2.993, device_id: 303}
      },
      {
        :parse_hex,
        "02012f000304d200010bb1",
        %{},
        %{battery: 2.993, device_id: 303, distance: 1234, samples: 1}
      }
    ]
  end
end
