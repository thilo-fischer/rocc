# -*- coding: utf-8 -*-

# Copyright (c) 2014-2016  Thilo Fischer.
#
# This file is part of rocc.
#
# rocc is free software with a multi-license approach: you can
# redistribute it and/or modify it as if it was under the terms of the
# GNU General Public License as long as the things you publish to
# satisfy the GPL's copyleft still can be integrated into the rocc
# project's main codebase without restricting the multi-license
# approach. See LICENSE.txt from the top-level directory for details.

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
    # Without an argument, initialize an Options object with all
    # options set to their default values. If another Options object
    # is given as +other+ argument, instantiate an Options instance
    # providing access to that objects option set. (Shallow copy,
    # i.e. both objects will share the same data structures and
    # modification to one object will always also affect the other
    # object.)
    def initialize(other = nil)
      if other
        @switches = other.switches
        @flags    = other.flags
      else
        set_defaults
      end
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
    def readonly
      @readonly ||= Options.new(self)
    end
    
  end # OptionsRw

end # Rocc::Session

