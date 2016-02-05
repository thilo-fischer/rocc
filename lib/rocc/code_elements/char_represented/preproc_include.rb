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

require 'rocc/contexts/lineread_context'
require 'rocc/contexts/comment_context'
require 'rocc/contexts/compilation_context'

module Rocc::CodeElements::CharRepresented

  class CeCoPpInclude < CeCoPpDirective

    @REGEXP = /#\s*include\s*(?<comments>(\/\*.*?\*\/\s*)+|\s)\s*(?<file>(<|").*?(>|"))/ # XXX_R not capable of handling `#include "foo\"bar"' or `#include <foo\>bar>'

    attr_reader :file

    def self.pick!(tokenization_context)

      tkn = super

      if tkn
        # TODO_F(pick_captures) Super just did match the @PICKING_REGEXP, and we match it here a second time (redundantly). Consider returning Regexp.last_match in CharObject.peek and CharObject.pick_string! and passing Regexp.last_match.named_captures to the CharObject.create. (=> same performance?)
        tkn.text =~ picker.picking_regexp

        tkn.file = $~[:file]
        comments = $~[:comments]

        #warn "XXXX #{tkn.name_dbg} file: `#{tkn.file}' from `#{tkn.text}'"
        
        # `comments' captures either all comments or -- if no comments are present -- all whitespace in between `include' and file name
        if not comments.strip.empty? then
          tkn.text.sub!(comments, " ")
        end
        while not comments.strip!.empty? do
          CeCoComment.pick!(tokenization_context, comments)
        end
        
      end

      tkn

    end # pick

    # FIXME_R make private?
    def file=(arg)
      raise if @file
      @file = arg
    end

    def path
      # strip quote characters
      @file[1..-2]
    end

    def quote
      if @file.start_with?('"') and @file.end_with?('"')
        :doublequote
      elsif @file.start_with?('<') and @file.end_with?('>')
        :anglebracket
      else
        raise # FIXME
      end
    end

    def pursue(compilation_context)

      super_duty = super
      return nil if super_duty.nil?

      current_dir = logic_line.first_physic_line.file.parent_dir
      path_abs = find_include_file(path, current_dir)
            
      file = compilation_context.fs_element_index.announce_element(Rocc::CodeElements::FileRepresented::CeFile, path_abs, self)
      compilation_context.translation_unit.add_include_file(file)

      lineread_context = Rocc::Contexts::LinereadContext.new(Rocc::Contexts::CommentContext.new(compilation_context)) # TODO should be handled as ParsingContext interal
      file.pursue(lineread_context)
    end

    # TODO move to another, more appropriate class
    def find_include_file(path, current_dir)

      if path == File.absolute_path(path)
        # include directive gives absolute pathname
        path_abs = path
      else
        #warn "try to find `#{path}' for #{name_dbg}: will test #{File.absolute_path(path, current_dir.path_full)} if #{quote}==doublequote, include dirs are: `#{Rocc::Session::Session.current_session.include_dirs}'"
        if quote == :doublequote and File.exist?(File.absolute_path(path, current_dir.path_full))
          path_abs = File.absolute_path(path, current_dir.path_full)
        else
          session = Rocc::Session::Session.current_session
          dir = session.include_dirs.find {|d| File.exist?(File.absolute_path(path, d))}
          raise "Cannot find file included from #{self}: #{path}" unless dir
          path_abs = File.absolute_path(path, dir)
        end
      end

      path_abs
    end
    private :find_include_file

  end # class CeCoPpInclude

end # module Rocc::CodeElements::CharRepresented::Tokens
