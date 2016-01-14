# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

##
# Things related to the currently running program instance.

module Rocc::Session

  ##
  # All currently active program options.
  #
  # Options configured at the rocc internal command line override
  # options given by command line arguments which override options
  # given by configuriton files. Local overrides global overrides
  # system configuration file.
  #
  # Read-only interface to be used by all classes not intended to
  # alter the options.
  #
  # An option which will be either active or inactive will be called
  # _switch_. An option which will be associated with a specific value
  # will be called _flag_.
  class Options

    ##
    # Instantiate an Options instance with all default values.
    def initialize
      set_defaults
    end

    ##
    # Instantiate an Options instance providing access to the option
    # configuration held by the +other+ Options object.
    def initilaize(other)
      @switches = other.switches
      @flags    = other.flags
    end
    
    ##
    # Whether the switch associated with the symbol given by +switch+ is active.
    def enabled?(switch)
      assert_switchname(switch)
      @switches[switch]
    end

    ##
    # Whether the flag associated with the symbol given by +flag+ is active.
    def active?(flag)
      value(flag) != nil
    end

    ##
    # Get the value of the flag associated with the symbol given by +flag+.
    def value(flag)
      assert_flagname(flag)
      @flags[flag]
    end


    protected

    attr_reader :switches, :flags
    
    def enable(switch)
      assert_switchname(switch)
      @switches[switch] = true    
    end
    
    def disable(switch)
      assert_switchname(switch)
      @switches[switch] = false    
    end

    def set(flag, value)
      assert_flagname(flag)
      value.freeze
      @flags[flag] = value
    end

    private

    def set_defaults
      @switches = {
        :on_the_fly => false,
      }
      @flags = {
        :verbosity => "WARN",
        :change_detection => "mtime",
      }
    end

    def assert_switchname(name)
      raise "Invalid option name: `#{name}'" unless @switches.key?(name)
    end
    
    def assert_flagname(name)
      raise "Invalid option name: `#{name}'" unless @flags.key?(name)
    end
    
  end # Options

  ##
  # See Options.
  # Read-Write interface to be used by classes intended to alter the options.
  class OptionsRw < Options

    ##
    # Activate the switch associated with the symbol given by +switch+.
    def enable(switch)
      super
    end
    
    ##
    # Deactivate the switch associated with the symbol given by +switch+.
    def disable(switch)
      super
    end

    ##
    # Set the flag associated with the symbol given by +flag+ to +value+.
    # Deactivates the flag if +value+ is nil.
    def set(flag, value)
      super
    end

    ##
    # Returns an Options object based on this object's maps, i.e. a
    # read-only interface to this object's option configuration.
    def read_only
      @read_only ||= Options.new(self)
    end
    
  end # OptionsRw

end # Rocc::Session

