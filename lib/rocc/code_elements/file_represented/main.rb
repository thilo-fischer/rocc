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
# Groups those code elements that correspond to files that would be
# input, intermediate result or output of regular compilations.
module Rocc::CodeElements::FileRepresented

  require 'rocc/code_elements/file_represented/module'
  require 'rocc/code_elements/file_represented/translation_unit'
  require 'rocc/code_elements/file_represented/filesystem_element'
  require 'rocc/code_elements/file_represented/file'
  require 'rocc/code_elements/file_represented/dir'
  require 'rocc/code_elements/file_represented/basedir'
  
end # module Rocc::CodeElements::FileRepresented
