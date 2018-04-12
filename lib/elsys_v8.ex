defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for various ELSYS devices
  # According to ELSYS Payload v8
  # Products: https://www.elsys.se/en/#
  # Documentation: https://www.elsys.se/en/elsys-payload/

  # not yet defined for all available products

  def parse(payload, _meta) do
    case parse_parts(payload, %{}) do
      {:ok, parts} ->
        parts
      {:error, {parts, rest}} ->
        Map.put(parts, :unparsed_binary, Base.encode16(rest))
    end
  end

  # First two bits define length of optional offset
  # Second 6 bits define type of part,
  # Size of values is defined by type of part.

  def parse_parts(<<nob::2, 0x01::6, temp::16, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :temperature, temp/10, %{offset: offset, unit: "C"}))
  end

  def parse_parts(<<nob::2, 0x02::6, humidity::8, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :humidity, humidity, %{offset: offset, unit: "%"}))
  end

  # Missing 0x03 .. 0x06

  def parse_parts(<<nob::2, 0x07::6, battery::16, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :battery, battery, %{offset: offset, unit: "mV"}))
  end

  # Missing 0x08 .. 0x09

  def parse_parts(<<nob::2, 0x0A::6, pulse_count::16, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :pulse_count, pulse_count, %{offset: offset, unit: "count"}))
  end

  def parse_parts(<<nob::2, 0x0B::6, pulse_count_abs::32, offset::unit(8)-size(nob), rest::bitstring>>, parts) do
    parse_parts(rest, add_part(parts, :pulse_count_abs, pulse_count_abs, %{offset: offset, unit: "count"}))
  end

  # Missing 0x0C ..

  def parse_parts(<<>>, parts), do: {:ok, parts} # Done parsing
  def parse_parts(rest, parts), do: {:error, {parts, rest}} # Can not parse rest


  # Adding a name and value to a map, increasing counter of key already exists.
  def add_part(parts, name, value, meta, counter \\ 1) do
    key = "#{name}_#{counter}"
    if Map.has_key?(parts, key) do
      add_part(parts, name, value, meta, counter+1)
    else
      prefixed_meta = Enum.into(meta, %{}, fn({k, v}) ->
        {"#{key}_#{k}", v}
      end)
      parts
      |> Map.put(key, value)
      |> Map.merge(prefixed_meta)
    end
  end

end
