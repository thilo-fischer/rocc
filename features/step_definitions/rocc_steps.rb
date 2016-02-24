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

  filecontent = IO.read(filename_out)
  parts = filecontent.split('///')
  if parts.length == 1
    # use string match if no regular expression specified in
    # expectiation file => better diff display if test fails
    @expect_out = filecontent
    # XXX_R is there a better syntax? e.g. with `step' instead of
    # `steps'?
    steps %Q{
    Then the output should contain exactly:
"""
#{@expect_out}
"""
    }
  else
    literals = []
    regexps  = []
    parts.each_slice(2) do |slc|
      literals << slc[0]
      regexps  << slc[1]
    end
    @expect_out = ''
    literals.each_with_index do |l, idx|
      @expect_out << Regexp.escape(l)
      @expect_out << regexps[idx] if regexps[idx]
    end
    #warn "AAAA #{@expect_out}"
    
    # XXX_R is there a better syntax? e.g. with `step' instead of
    # `steps'?
    steps %Q{
    Then the output should match:
"""
#{@expect_out}
"""
    }
  end
  
  filename_err = @basepath + '.stderr'
  if File.exist?(filename_err)
    @expect_err = IO.read(filename_err)
  else
    @expect_err = nil
  end
  
  if @expect_err
    # XXX_R is there a better syntax? e.g. with `step' instead of
    # `steps'?
    steps %Q{
      And the stderr should contain exactly:
"""
#{@expect_err}
"""
  }
  end
  
end

