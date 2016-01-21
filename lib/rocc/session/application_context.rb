# -*- coding: utf-8 -*-

# Copyright (C) 2014-2016  Thilo Fischer.
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
# Things related to the application of the currently running
# session. Part of the session that is more dynamic and is being
# altered by the commands being run during the session. Comes to live
# only after initial target source code parsing has been done.
module Rocc::Session

  class ApplicationContext

    attr_accessor :cursor

    def initialize(cursor)
      @cursor = cursor
    end
    
  end # class ApplicationContext

end # Rocc::Session

