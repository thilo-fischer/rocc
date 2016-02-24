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

require 'rocc/session/session'

##
# Things related to the application of the currently running
# session. Part of the session that is more dynamic and is being
# altered by the commands being run during the session. Comes to live
# only after initial target source code parsing has been done.
module Rocc::Session

  class ApplicationContext

    attr_accessor :cursor

    def initialize

      @cursor = session_toplevel
      @cursor_history = []

    end

    # FIXME split into function to resolve path strings to code
    # objects and a function to cd to code objects.
    def cursor_cd(arg)
      @cursor_history << @cursor

      arg = arg.dup # XXX_F

      case arg
          
      when String

        candidates = [@cursor]

        case
        when arg.slice!(/^\.\.\.\//) # .start_with?('.../')
          raise "base directory path not yet implemented"
          # candidates = FilesystemElementIndex#base_directories
        when arg.slice!(/^\/\//) # .start_with?('//')
          candidates = [session_toplevel]
        end

        # TODO_R refactor/rework
        until arg.empty?
          next_candidates = []
          name = arg.slice!(/^.*?(\.|::|\/|$)/)
          name.slice!(/(\.|::|\/)$/)
          candidates.each do |cur|
            case cur
            when Rocc::CodeElements::FileRepresented::CeTranslationUnit
              symbols = cur.find_symbols(:origin => cur, :identifier => name)
              symbols.each do |s|
                next_candidates << s
              end
            else
              raise "not yet implemented (=> #{cur})"
            end # case cur
          end
          candidates = next_candidates
        end # until arg.empty?

        if candidates.empty?
          raise "No such element: #{arg}"
        elsif candidates.length > 1
          raise "#{arg} ambiguous: one of #{candidaties}"
        end
        
        @cursor = candidates.first
        
      when CodeElement
        @cursor = arg
        
      else
        raise "invalid argument #{arg} or not yet supported"
        
      end
    end # def cursor_cd

    # cd -
    def cursor_cd_prev()
      return if @cursor_history.empty?
      new_cursor = @cursor_history[-1]
      @cursor_history[-1] = @cursor
      @cursor = new_cursor
    end
    
    def cursor_hist(depth)
      if depth == 0
        @cursor
      elsif depth > 0
        @cursor_history[-depth]
      else
        raise "invalid argument"
      end
    end

    def session_toplevel
      result = Session.instance.modules
      if result.count == 1
        result = result.first
        if result.translation_units.count == 1
          result = result.translation_units.first
        end
      end
    end
    
    def find_symbols(criteria = {})
      result = []
      Session.instance.modules.each do |mod|
        mod.translation_units.each do |tu|
          result += tu.find_symbols(criteria)
        end
      end
      result
    end
    
  end # class ApplicationContext

end # Rocc::Session

