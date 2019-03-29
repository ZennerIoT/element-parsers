
# Test if all files in lib/ are linked correctly in README.md


parser_files = Path.wildcard("lib/**")

readme_content = File.read!("README.md")

Enum.each(parser_files, fn(parser_file) ->
  if(String.contains?(readme_content, "[#{parser_file}](#{parser_file})")) do
    IO.puts "Found parser in README: #{parser_file}"
  else
    raise "Missing parser in README: #{parser_file}"
  end
end)

IO.puts "\nALL parsers linked in readme :)\n"


