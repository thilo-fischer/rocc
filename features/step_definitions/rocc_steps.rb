When /^I invoke as "([^"]*)" on "([^"]*)"$/ do |command, input|

  @command   = command
  @input     = input.split(/\s+/)
  @input_dir = File.dirname(@input.first)

  @input.map! {|i| i = "\"#{File.join(TESTDATA_DIR, i)}\""}
  
  step %(I run `ooccor -e '#{@command}' #{@input.join(" ")}`)

end

Then /^the output should look as specified in the according file$/ do

  @result_file = File.join(
                           TESTDATA_DIR,
                           @input_dir,
                           "expected_results",
                           @command.gsub(/\W/, '_')
                           )

  @expected_result = IO.read(@result_file)

  # fixme: is there a better syntax? e.g. with `step' instead of `steps'?
  steps %Q{
Then the output should contain exactly:
"""
#{@expected_result}
"""
}
end

