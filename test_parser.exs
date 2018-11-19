
defmodule Platform.Parsing.Behaviour do
  # Empty modules so tests work so far.

  def __using__(_) do
    # TODO: Add needed callbacks here.
  end

end

defmodule TestParser do

  def test_parser_from_file(file) do
    file
    |> Code.require_file
    |> get_tests_from_parser
    |> run_tests
    |> exit_program
  end

  defp get_tests_from_parser([{parser_module, _}|_]) do
    {parser_module, apply(parser_module, :tests, [])}
  end

  defp run_tests({parser_module, tests}) do
    Enum.map(tests, fn({:parse_hex = test_type, payload_hex, meta, expected_result}) ->
      payload_binary = Base.decode16!(payload_hex)
      actual_result = apply(parser_module, :parse, [payload_binary, meta])

      case actual_result do
        ^expected_result ->
          IO.puts("[#{test_type}] Test payload #{payload_hex} matches expected_result")
          :ok
        _ ->
          IO.puts("[#{test_type}] Test payload #{payload_hex} DID NOT MATCH expected_result")
          IO.inspect(expected_result, label: "EXPECTED")
          IO.inspect(actual_result, label: "ACTUAL")
          :error
      end
    end)
  end

  defp exit_program(results) do
    if Enum.member?(results, :error) do
      System.halt(1)
    else
      System.halt(0)
    end
  end
end

[parser_file] = System.argv()

TestParser.test_parser_from_file(parser_file)
