When /^I invoke "([^"]*)" on "([^"]*)"$/ do |command, input|

  @command   = command
  @input     = input.split(/\s+/)
  @input_dir = File.dirname(@input.first)

  @input.map! {|i| i = "\"#{File.join(TESTDATA_DIR, 'code', i)}\""}
  
  step %(I run `rocc -e '#{@command}' #{@input.join(" ")}`)

end

Then /^the output should look as specified by "([^"]*)"$/ do |basepath|

  @basepath = File.join(TESTDATA_DIR, 'expect', basepath)

  filename_out = @basepath + '.stdout'
  @expect_out = IO.read(filename_out) 
  
  filename_err = @basepath + '.stderr'
  if File.exist?(filename_err)
    @expect_err = IO.read(filename_err)
  else
    @expect_err = nil
  end
  
  # fixme: is there a better syntax? e.g. with `step' instead of `steps'?
  steps %Q{
    Then the stdout should contain exactly:
"""
#{@expect_out}
"""
  }
  
  if @expect_err
    # fixme: is there a better syntax? e.g. with `step' instead of `steps'?
    steps %Q{
      And the stderr should contain exactly:
"""
#{@expect_err}
"""
  }
  end
  
end

