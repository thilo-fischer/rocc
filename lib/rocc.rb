# -*- coding: utf-8 -*-

# Copyright (C) 2014-2015  Thilo Fischer.
# Software is free for non-commercial and most commercial use. Integration into commercial applications may require according licensing. See LICENSE.txt for details.

##
# This is the central rocc lib file. Software using the rocc lib
# should require this file, all relevant additional .rb files will be
# required indirectly then.
#
# This block comment is also the central place for general
# documentation and alike. Aside rdoc documentation in the source
# code, UML diagrams on rocc architecture can be found in the design
# folder. UML diagrams are in plantuml (http://plantuml.com/) format.
# 
# = TODOs
#
# == Conventions
#
# Some shortcuts are taken in implementation. When some code is
# written, and it is known upon time of writing that the code is not
# that great because it does not handle special corner cases, has
# suboptimal performance, is not flexible, extendable, easy to read
# and understand or unclean in another way, this code section should
# be marked accordingly. To mark these code sections, a commet is
# added including an according keyword that marks it as a TODO
# comment. Keywords are used according to the conventions of the
# Eclipse IDE:
#
# [FIXME] marks high priority issues.
# [TODO]  marks medium priority issues.
# [XXX]   marks low priority issues.
#
# As a general guideline, FIXME is used for issues that *should* be
# fixed before a stable release, e.g. possible bugs on corner cases,
# issues with huge performance impact and such.
#
# TODO is used for issues that should be fixed ASAP.
#
# XXX marks nice to have issues that should be fixed some day.
#
# Most todo comments are located at those code sections they apply
# to. Some comments with general scope or affecting multiple code
# sections are placed in the central todo list below.
#
# == Central TODO list
#
# * FIXME adapt copyright note (2014-201*6*)
# * test suite
#   * XXX more tests
#
#     Not really an item for a todo list -- you would always want more test. This is just a collection of sources where to find fancy C and C++ code that would be good to have in a test ...
#
#     * http://deneke.biz/2014/02/great-presentation-dark-corners-c/
#     * https://docs.google.com/presentation/d/1h49gY3TSiayLMXYmRMaAEMl05FaJ-Z6jDOWOz3EsqqQ/edit?pli=1#slide=id.gaf50702c_0123
#   * use cucumber
#   * TODO add unit tests
# * refactor code
#   * "forward declarations" needed?
#     * "implemented"-hook ?
#   * make some protected methods private ?
# * exceptions
#   * TODO provide appropriate exception classes
#   * TODO review all `raise' expressions and provide appropriate messages and exception classes
#   * FIXME top-level exception handling to prevent program crashes
#   * FIXME raise "not yet implemented"/raise "not yet supported"
# * review module hierarchy and file structure


module Rocc

  require 'rocc/version'
  require 'rocc/compilers/compilers'

  require 'rocc/session/session'
  require 'rocc/commands/commands'
  
#  require 'rocc/code_objects/program'

end # module Rocc
