# -*- coding: utf-8 -*-

# Copyright (C) 2014  Thilo Fischer.
# Free software licensed under GPL v3. See LICENSE.txt for details.

module Ooccor::CodeObjects
  module Tokens

    class TknComment               < CoToken;         end
    class TknLineComment           < TknComment;      end
    class TknBlockComment          < TknComment;      end
    class TknMultiLineBlockComment < TknBlockComment; end


    class TknComment < CoToken

      @PICKING_REGEXP = /^(\/\/.*$|\/\*.*?(\*\/|$))/

      def self.pick(env, str = nil)
        if env.tokenization[:ongoing_comment] then
          TknMultiLineBlockComment.pick(env)
        else
          str ||= pick_string(env)
          if str then
            if str.start_with?("/*") then
              # block comment
              if str.end_with?("*/") then
                super(env, str, TknBlockComment)
              else
                tkn = super(env, str, TknMultiLineBlockComment)
                env.tokenization[:ongoing_comment] = tkn
              end
            else
              # line comment
              super(env, str, TknLineComment)
            end
          end
        end
      end # pick

      #  def self.pick!(env)
      #    unless env.tokenization[:ongoing_comment] then
      #warn "FOO"
      #      tkn = super
      #      if tkn and tkn.text.start_with?("/*") and not tkn.text.end_with?("*/") then
      #        # start of multiline comment
      #        env.tokenization[:ongoing_comment] = tkn
      #      end
      #      tkn
      #    else
      #warn "BAR"
      #      TknMultiLineComment.pick!(env)
      #    end
      #  end # pick!

      def expand(env)
        nil
      end

      def expand_with_context(env, ctxt)
        nil
      end

    end


    # Shall be picked directly only if env.tokenization[:ongoing_comment]. Shall be picked indirectly through TknComment otherwise.
    class TknMultiLineBlockComment < TknBlockComment

      @PICKING_REGEXP = /^.*?(\*\/|$)/

      def self.pick(env, str = nil)
        raise "Shall not be picked directly unless env.tokenization[:ongoing_comment]." unless env.tokenization[:ongoing_comment] # fixme: exception message

        str ||= self.pick_string(env)
        tkn = env.tokenization[:ongoing_comment]
        tkn.add_line(env.expansion_stack.last, str)
        env.tokenization[:ongoing_comment] = nil if str.end_with?("*/")
        tkn
      end # pick

      # fixme: make protected
      def add_line(line, text)

        @text += "\n" + text

        if @origin.is_a? CoContainer then
          @origin.append line
        else
          @origin = CoContainer.new([@origin, line])
          # todo (code enhancement): use range instead of array (not yet supported by CoContainer)
          # --> @origin = CoContainer.new(@origin..line)
        end

      end # add_line

    end

  end # module Tokens
end # module Ooccor::CodeObjects
