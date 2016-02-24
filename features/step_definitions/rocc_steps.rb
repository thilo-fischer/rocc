When /^I invoke "([^"]*)" on "([^"]*)"$/ do |command, input|

  @command   = command
  @input     = input.split(/\s+/)
  @input_dir = File.dirname(@input.first)

  @input.map! {|i| i = "\"#{File.join(TESTDATA_DIR, 'code', i)}\""}
  
  step %(I run `rocc -e '#{@command}' #{@input.join(" ")}`)

end

Then /^the output should look as specified by "([^"]*)"$/ do |basepath|

  basepath = File.join(TESTDATA_DIR, 'expect', basepath)

  filename_out = basepath + '.stdout'

  expect_out = IO.read(filename_out)
  out_parts = expect_out.split('///')
  if out_parts.length == 1
    # use string match if no regular expression specified in
    # expectiation file => better diff display if test fails
    
    # XXX_R is there a better syntax? e.g. with `step' instead of
    # `steps'?
    steps %Q{
    Then the output should contain exactly:
"""
#{expect_out}
"""
    }
  else
    literals = []
    regexps  = []
    out_parts.each_slice(2) do |slc|
      literals << slc[0]
      regexps  << slc[1]
    end
    regexp_source = ''
    literals.each_with_index do |l, idx|
      regexp_source << Regexp.escape(l)
      regexp_source << regexps[idx] if regexps[idx]
    end
    #warn "AAAA #{regexp_source}"
    
    # XXX_R is there a better syntax? e.g. with `step' instead of
    # `steps'?
    steps %Q{
    Then the output should match:
"""
#{regexp_source}
"""
    }
  end
  
  filename_err = basepath + '.stderr'
  if File.exist?(filename_err)
    expect_err = IO.read(filename_err)
  else
    expect_err = nil
  end
  
  if expect_err
    # XXX_R is there a better syntax? e.g. with `step' instead of
    # `steps'?
    steps %Q{
      And the stderr should contain exactly:
"""
#{expect_err}
"""
  }
  end
  
end

