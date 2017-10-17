defmodule Parser do
  use Platform.Parsing.Behaviour

  def parse(<< type :: integer-4, subtype :: integer-4, rest :: binary >>, _meta) do
    case type do
      1 ->
        %{
          value: parse_subtype(subtype, rest)
        }
      2 ->
        case rest do
          << _ :: binary-2, month :: binary-4 >> ->
            %{
              value: parse_subtype(subtype, month)
            }
          _ ->
            []
        end
      5 ->
        case rest do
          << ch1 :: binary-4, ch2 :: binary-4, status :: binary-2 >> ->
            %{
              value_1: parse_subtype(subtype, ch1),
              value_2: parse_subtype(subtype, ch2)
            }
          _ ->
            []
        end
      6 ->
        case rest do
          << _ :: binary-2, ch1 :: binary-4, ch2 :: binary-4 >> ->
            %{
              value_1: parse_subtype(subtype, ch1),
              value_2: parse_subtype(subtype, ch2)
            }
          _ ->
            []
        end
      _ ->
        []
    end
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
end
