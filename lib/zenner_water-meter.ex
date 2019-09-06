defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for ZENNER Water meters
  # According to documentation provided by ZENNER International
  # Link:  https://www.zenner.com
  #
  # Changelog:
  #   2018-04-26 [jb]: Added fields(), tests() and value_m3
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads
  #

  def fields() do
    [
      %{
        field: "value_m3",
        display: "Volume",
        unit: "m3",
      },
      %{
        field: "value",
        display: "Liter",
        unit: "l",
      },
    ]
  end

  def parse(<< type :: integer-4, subtype :: integer-4, rest :: binary >>, _meta) do
    case type do
      1 ->
        value = parse_subtype(subtype, rest)
        %{
          value: value,
          value_m3: value / 1000,
        }
      2 ->
        case rest do
          << _ :: binary-2, month :: binary-4 >> ->
            value = parse_subtype(subtype, month)
            %{
              value: value,
              value_m3: value / 1000,
            }
          _ ->
            []
        end
      5 ->
        case rest do
          << ch1 :: binary-4, ch2 :: binary-4, _status :: binary-2 >> ->
            value_1 = parse_subtype(subtype, ch1)
            value_2 = parse_subtype(subtype, ch2)
            %{
              value_1: value_1,
              value_1_m3: value_1 / 1000,
              value_2: value_2,
              value_2_m3: value_2 / 1000,
            }
          _ ->
            []
        end
      6 ->
        case rest do
          << _ :: binary-2, ch1 :: binary-4, ch2 :: binary-4 >> ->
            value_1 = parse_subtype(subtype, ch1)
            value_2 = parse_subtype(subtype, ch2)
            %{
              value_1: value_1,
              value_1_m3: value_1 / 1000,
              value_2: value_2,
              value_2_m3: value_2 / 1000,
            }
          _ ->
            []
        end
      _ ->
        []
    end
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  def parse_subtype(subtype, <<data :: binary-4 >>) do
    case subtype do
      0 ->
        parse_bcd(data, 0)
      1 ->
        <<int::little-integer-32>> = data
        int
      2 ->
        <<int::little-integer-32>> = data
        int
      _ ->
        0
    end
  end
  def parse_subtype(_, _), do: 0

  def parse_bcd(<< num :: integer-4, rest :: bitstring >>, acc) do
    parse_bcd(rest, num + 10 * acc)
  end
  def parse_bcd("", acc), do: acc


  def tests() do
    [
      {:parse_hex, "112C000000", %{}, %{value: 44, value_m3: 0.044}},
      {:parse_hex, "11FC010000", %{}, %{value: 508, value_m3: 0.508}},
      {:parse_hex, "111E000000", %{}, %{value: 30, value_m3: 0.03}},

      # TODO: Implement: 9132015624000000000000
      # TODO: Implement: 9219001701010001100005CE4B92000000
    ]
  end

end
