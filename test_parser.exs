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

      def fields() do
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
          # Fallback to last reading if not found, makes writing tests easier
          _ -> Map.get(meta, :_last_reading, nil)
        end
      end

      # TODO: Add needed callbacks here.

      defoverridable tests: 0, fields: 0
    end
  end
end

defmodule TestParser do
  defmodule State do
    defmodule Test do
      defstruct definition: nil,
                index: nil,
                result: nil,
                command: nil,
                message: nil,
                comment: nil
    end

    defstruct file: nil,
              test_filter: :all,
              tests: [],
              module: Parser
  end

  def run(args) do
    case OptionParser.parse(args, strict: [test: :integer]) do
      {opts, [test_file], []} ->
        test_parser(%State{
          file: test_file,
          test_filter: Keyword.get(opts, :test, :all)
        })

      {_opts, _args, []} ->
        raise("ERROR: Only one test file!")

      {_opts, _args, errors} ->
        raise("ERROR in Args: #{inspect(errors)}")
    end
  rescue
    error in RuntimeError ->
      error("Fatal ERROR: #{Exception.message(error)}")
      System.halt(1)
  end

  defp test_parser(state) do
    state
    |> load_tests
    |> run_tests
    |> output_summary_and_exit
  end

  defp add_additional_definitions(definitions) do
    # a pid is neither a map nor a binary, so it will not match.
    payload_that_will_not_be_matched = self()

    Enum.concat(definitions, [
      {:function, :fields, [],
       fn result ->
         case result do
           [] ->
             warn("[function] MISSING field definition!")
             :ok

           [_ | _] ->
             success("[function] Fields returning non empty list.")
             :ok

           _ ->
             error("[function] fields() NOT returning a list")
             :error
         end
       end},
      {:parse, payload_that_will_not_be_matched, %{_comment: "Catchall check"}, []}
    ])
  end

  defp load_tests(%State{file: file, module: module} = state) do
    file
    |> Code.require_file()
    |> case do
      [{^module, _compiled}] ->
        tests = apply(module, :tests, [])

        tests =
          tests
          |> add_additional_definitions()
          |> Enum.with_index(1)
          |> Enum.map(fn {definition, index} ->
            %State.Test{
              definition: definition,
              index: index,
              command: definition |> Tuple.to_list() |> hd
            }
          end)

        %State{state | tests: tests}

      [] ->
        raise "No 'Parser' module in file #{file}"

      _ ->
        raise "Can not load 'Parser' module from file #{file}"
    end
  end

  defp run_tests(%State{tests: tests} = state) do
    tests =
      tests
      |> filter_tests(state)
      |> Enum.map(&run_test(&1, state))

    %State{state | tests: tests}
  end

  defp filter_tests(tests, %State{test_filter: :all}) do
    tests
  end

  defp filter_tests(tests, %State{test_filter: only_index}) do
    tests
    |> Enum.filter(fn %State.Test{index: index} ->
      index == only_index
    end)
  end

  defp execute_function(%State{module: module}, function, args) do
    apply(module, function, args)
  end

  defp comment(%{_comment: comment}) do
    "#{comment}"
  end

  defp comment(_meta) do
    ""
  end

  defp run_test(
         %State.Test{definition: {:parse_hex, payload_hex, meta, expected_result}} = test,
         state
       ) do
    payload =
      payload_hex
      |> to_string
      |> String.trim()
      |> String.replace(" ", "")
      |> Base.decode16!(case: :mixed)

    parse_result = execute_function(state, :parse, [payload, meta])

    result = compare_results(parse_result, expected_result, :parse_hex, payload_hex)

    %State.Test{test | result: result, comment: comment(meta), message: "#{payload_hex}"}
  end

  defp run_test(%State.Test{definition: {:parse_json, json, meta, expected_result}} = test, state) do
    json = json |> to_string
    payload = json |> Jason.decode!()
    payload_human = json |> String.replace("\n", " ") |> String.slice(0..50)

    parse_result = execute_function(state, :parse, [payload, meta])

    result = compare_results(parse_result, expected_result, :parse_json, payload_human)

    %State.Test{test | result: result, comment: comment(meta), message: "#{payload_human}"}
  end

  defp run_test(%State.Test{definition: {:parse, payload, meta, expected_result}} = test, state) do
    payload_human = payload |> inspect |> String.replace("\n", " ") |> String.slice(0..50)

    parse_result = execute_function(state, :parse, [payload, meta])

    result = compare_results(parse_result, expected_result, :parse, payload_human)

    %State.Test{test | result: result, comment: comment(meta), message: "#{payload_human}"}
  end

  defp run_test(%State.Test{definition: {:function, function, args, checker}} = test, state) do
    payload_human =
      "#{function}(#{inspect(args)})" |> String.replace("\n", " ") |> String.slice(0..50)

    result = execute_function(state, function, args)

    result = checker.(result)

    %State.Test{test | result: result, message: "#{payload_human}"}
  end

  defp compare_results(parse_result, expected_result, command, payload_human) do
    case parse_result do
      ^expected_result ->
        success("[#{command}] Test payload #{payload_human} matches expected_result")
        :ok

      _ ->
        warn("[#{command}] Test payload #{payload_human} DID NOT MATCH expected_result")
        IO.inspect(expected_result, label: "EXPECTED")
        IO.inspect(parse_result, label: "ACTUAL")
        :error
    end
  end

  defp output_summary_and_exit(%State{tests: tests}) do
    {success, failure, failed} =
      Enum.reduce(tests, {0, 0, []}, fn
        %State.Test{result: :ok}, {success, failure, failed} ->
          {success + 1, failure, failed}

        %State.Test{result: :error} = result, {success, failure, failed} ->
          {success, failure + 1, [result | failed]}
      end)

    failed = Enum.reverse(failed)

    IO.puts("")
    IO.puts("--- TEST SUMMARY:")
    IO.puts("   Success: #{success}")
    IO.puts("   Failure: #{failure}")

    case failure do
      0 ->
        System.halt(0)

      _ ->
        newline()
        error("    #{failure} tests failed:")
        newline()

        Enum.each(failed, fn %State.Test{
                               index: index,
                               comment: comment,
                               command: command,
                               message: message,
                               result: result
                             } ->
          error(
            "     #{String.pad_leading("#" <> to_string(index), 3)}: #{command} for #{message} with result #{
              inspect(result)
            } (#{comment})"
          )
        end)

        System.halt(1)
    end
  end

  def newline() do
    IO.puts("")
  end

  defp success(line) do
    [:green, to_string(line)] |> IO.ANSI.format() |> IO.puts()
  end

  defp warn(line) do
    [:yellow, to_string(line)] |> IO.ANSI.format() |> IO.puts()
  end

  defp error(line) do
    [:red, to_string(line)] |> IO.ANSI.format() |> IO.puts()
  end
end

TestParser.run(System.argv())
