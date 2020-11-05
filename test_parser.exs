
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
        |> Map.get(:_last_reading_map, nil)
        |> case do
          map when is_map(map) -> Access.get(map, query)
          _ -> Map.get(meta, :_last_reading, nil) # Fallback to last reading if not found, makes writing tests easier
        end
      end

      # TODO: Add needed callbacks here.

      defoverridable tests: 0
    end
  end

end

defmodule TestParser do

  def run(args) do
    default_opts = [
      test: :all,
    ]
    case OptionParser.parse(args, strict: [test: :integer]) do
      {opts, [test_file], []} ->
        opts = Keyword.merge(default_opts, opts)
        test_parser_from_file(test_file, opts)
      {_opts, _args, []} ->
        IO.puts("ERROR: Only one test file!")
        System.halt(2)
      {_opts, _args, errors} ->
        IO.puts("ERROR in Args: #{inspect errors}")
        System.halt(3)
    end
  end

  def test_parser_from_file(file, opts) do
    file
    |> Code.require_file
    |> get_tests_from_parser
    |> run_tests(opts)
    |> output_summary_and_exit
  end

  defp get_tests_from_parser([{parser_module, _}|_]) do
    {parser_module, apply(parser_module, :tests, [])}
  end

  defp run_tests({parser_module, tests}, opts) do
    tests
    |> Enum.with_index(1)
    |> Enum.filter(fn({_test, index}) ->
      case Keyword.get(opts, :test) do
        :all -> true
        number -> (index == number)
      end
    end)
    |> Enum.map(fn({{test_type, payload, meta, expected_result}, index}) ->

      {payload, payload_human} = handle_encoding(test_type, payload)

      actual_result = apply(parser_module, :parse, [payload, meta])

      comment = case meta do
        %{_comment: comment} -> "(#{comment})"
        _ -> ""
      end

      test_result = case actual_result do
        ^expected_result ->
          success("[#{test_type}] Test payload #{payload_human} matches expected_result #{comment}")
          :ok
        _ ->
          warn("[#{test_type}] Test payload #{payload_human} DID NOT MATCH expected_result #{comment}")
          IO.inspect(expected_result, label: "EXPECTED")
          IO.inspect(actual_result, label: "ACTUAL")
          :error
      end

      {{test_type, payload, payload_human, meta, expected_result}, index, test_result}
    end)
  end

  # Will return {payload, payload_human_readable}
  defp handle_encoding(:parse_hex, payload_hex) do
    payload = payload_hex
              |> to_string
              |> String.trim
              |> String.replace(" ", "")
              |> Base.decode16!(case: :mixed)
    {payload, to_string(payload_hex)}
  end
  defp handle_encoding(:parse_json, json) do
    json = json |> to_string
    payload = json |> Jason.decode!
    payload_human = json |> String.replace("\n", " ") |> String.slice(0..50)
    {payload, payload_human}
  end
  defp handle_encoding(:parse, payload) do
    payload_human = payload |> inspect |> String.replace("\n", " ") |> String.slice(0..50)
    {payload, payload_human}
  end
  defp handle_encoding(test_type, _payload), do: raise "unknown test type: #{test_type}"


  defp output_summary_and_exit(results) do

    {success, failure, failed} = Enum.reduce(results, {0, 0, []}, fn
      ({_test, _index, :ok}, {success, failure, failed}) -> {success+1, failure, failed}
      ({_test, _index, :error} = result, {success, failure, failed}) -> {success, failure+1, [result|failed]}
    end)

    failed = Enum.reverse(failed)

    IO.puts("")
    IO.puts("--- TEST SUMMARY:")
    IO.puts("   Success: #{success}")
    IO.puts("   Failure: #{failure}")

    exit_code = case failure do
      0 ->
        0 # success!
      _ ->
        newline()
        error("    #{failure} tests failed:")
        newline()
        Enum.each(failed, fn({{cmd, _payload, payload_human, meta, _result}, index, result}) ->
          comment = Map.get(meta, :_comment, "")
          error("     #{String.pad_leading("#"<> to_string(index), 3)}: #{cmd} for #{inspect payload_human} with result #{inspect result} (#{comment})")
        end)
        1 # Thats an error
    end

    System.halt(exit_code)
  end

  def newline() do
    IO.puts("")
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

TestParser.run(System.argv())

