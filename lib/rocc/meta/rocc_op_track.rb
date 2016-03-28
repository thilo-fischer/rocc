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

require 'singleton'
require 'yaml'

require 'rocc/session/logging'
require 'rocc/helpers'

module Rocc::Meta

  ##
  # To be extended by classes to allow announcing incidents to the
  # RoccOpTracker easily by the +track+ method from class
  # methods and in combination with the OpTrackClientInstanceMixin
  # from instance methods.
  module OpTrackClientClassMixin

    def track
      if RoccOpTracker.instance.active?
        RoccOpTracker.instance.track(yield)
      end
    end

  end

  ##
  # To be included by classes to allow announcing incidents to the
  # RoccOpTracker easily by the +track+ method from instance
  # methods. (Classes must also extend the OpTrackClientClassMixin.)
  module OpTrackClientInstanceMixin

    def track
      self.class.track { yield } # XXX_F will it yield only if RoccOpTracker.instance.active? ?
    end

  end

  ##
  # Track internal operation of rocc.
  class RoccOpTracker
    
    include Singleton

    extend  Rocc::Session::LogClientClassMixin
    include Rocc::Session::LogClientInstanceMixin

    def initialize
      @outstream = nil
    end # initialize

    def active?
      @outstream
    end

    def outstream=(stream)
      @outstream = stream
    end

    def track(incident)
      log.debug do
        "TRACK `" +
          Rocc::Helpers::String.str_abbrev_inline(
          case incident
          when Hash
            incident.inspect
          else
            incident.to_s
          end, 64
        ) + "'"
      end
      @outstream.puts(incident.to_yaml)
    end

    def finalize
      if @outstream != nil and @outstream.is_a?(File)
        @outstream.close
      end
    end

  end # class RoccOpTracker

end
