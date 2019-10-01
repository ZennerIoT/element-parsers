
defmodule Platform.Parsing.Behaviour do
  # Empty modules so tests work so far.

  defmacro __using__(_) do
    quote do

      # Helper functions for data structure access in parsers.
      # DO NOT REMOVE
      def get(meta, access, default \\ nil)
      def get(meta, [], _) do
        meta
      end
      # Map access
      def get(meta, [atom | rest], default) when is_atom(atom) and is_map(meta) do
        get(Map.get(meta, atom, Map.get(meta, to_string(atom), default)), rest, default)
      end
      # List access
      def get(meta, [int | rest], default) when is_integer(int) and is_list(meta) do
        get(Enum.at(meta, int, default), rest, default)
      end
      # Tuple access
      def get(meta, [int | rest], default) when is_integer(int) and is_tuple(meta) do
        try do
          get(elem(meta, int), rest, default)
        rescue
          e in ArgumentError -> default
        end
      end
      # Fallback
      def get(_, _, default) do
        default
      end

      def tests() do
        []
      end

      def get_last_reading(meta, []) do
        Map.get(meta, :_last_reading, nil)
      end
      def get_last_reading(meta, query) do
        meta
        |> Map.get(:_last_reading_map, %{})
        |> case do
          map when is_map(map) -> Access.get(map, query)
          _ -> nil
        end
      end

      # TODO: Add needed callbacks here.

      defoverridable tests: 0
    end
  end

end

defmodule TestParser do

  require Logger

  def test_parser_from_file(file) do
    file
    |> Code.require_file
    |> get_tests_from_parser
    |> run_tests(file)
    |> exit_program
  end

  defp get_tests_from_parser([{parser_module, _}|_]) do
    {parser_module, apply(parser_module, :tests, [])}
  end

  defp run_tests({parser_module, []}, file) do
    warn("WARN: No tests fround in file #{inspect file} with parser_module: #{inspect parser_module}")
    []
  end
  defp run_tests({parser_module, tests}, _file) do
    Enum.map(tests, fn
      ({:parse_hex = test_type, payload_hex, meta, expected_result}) ->
        payload_hex = String.replace(payload_hex, " ", "")
        payload_binary = Base.decode16!(payload_hex, case: :mixed)
        actual_result = apply(parser_module, :parse, [payload_binary, meta])
        compare_results(actual_result, expected_result, test_type, payload_hex)

      ({:parse = test_type, payload, meta, expected_result}) ->
        actual_result = apply(parser_module, :parse, [payload, meta])
        compare_results(actual_result, expected_result, test_type, payload |> inspect |> String.slice(0, 50))
    end)
  end

  def compare_results(actual_result, expected_result, test_type, payload) when actual_result == expected_result do
    success("[#{test_type}] Test payload #{inspect payload} matches expected_result")
    :ok
  end
  def compare_results(actual_result, expected_result, test_type, payload) do
    error("[#{test_type}] Test payload #{inspect payload} DID NOT MATCH expected_result")
    IO.inspect(expected_result, label: "EXPECTED")
    IO.inspect(actual_result, label: "ACTUAL")
    :error
  end


  defp exit_program(results) do
    if Enum.member?(results, :error) do
      System.halt(1)
    else
      System.halt(0)
    end
  end

  defp success(line) do
    [:green, to_string(line)] |> IO.ANSI.format |> IO.puts
  end
  defp warn(line) do
    [:yellow, to_string(line)] |> IO.ANSI.format |> IO.puts
  end
  defp error(line) do
    [:red, to_string(line)] |> IO.ANSI.format |> IO.puts
  end

end

[parser_file] = System.argv()

TestParser.test_parser_from_file(parser_file)
