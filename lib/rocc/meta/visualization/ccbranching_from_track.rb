#!/usr/bin/env ruby
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
# converts a YAML stream of rocc operations track data from STDIN to a
# SVG graphic vizualizing how the parsing process divides into several
# compilation branches and outputs the SVG document to STDOUT.
#
# SVG reference: https://www.w3.org/TR/SVG/

require 'yaml'

require 'rexml/document'
include REXML

svgdoc = Document.new <<SVGDOCUMENT
<svg xmlns="http://www.w3.org/2000/svg" version="1.1">
  <defs>
    <marker id="Triangle"
      viewBox="0 0 10 8" refX="8" refY="4" 
      markerUnits="strokeWidth"
      markerWidth="8" markerHeight="6"
      orient="auto">
      <path d="M 0 0 L 10 4 L 0 8 z" />
    </marker>
    <marker id="Circle"
      viewBox="0 0 10 10" refX="5" refY="5" 
      markerUnits="strokeWidth"
      markerWidth="5" markerHeight="5"
      orient="auto">
      <path d="M 5,0 A 5,5 0 1,0 5,10 A 5,5 0 1,0 5,0" /><!-- XXX_F draw circle at once instead of drawing two 180 degree arcs -->
    </marker>
  </defs>
  <g stroke-linecap="round" /> <!-- stroke="black" stroke-width="1.0" -->
</svg>
SVGDOCUMENT

$svgroot = svgdoc.root.elements['g']

# Some default value constants
STROKE_WIDTH = 1.0
CODE_X = 0.0
Y_DIFF = 25.0
WIDTH = 1000.0
CURVE_RADIUS = 20.0
TEXT_X_PAD = 2.5
TEXT_Y_PAD_BTM = 2.5
TEXT_Y_SHIFT_TOP = 10.0
FONT_SIZE = 12

def svg_line(from, to, attributes = {})
  attributes['x1'] = from[0]
  attributes['y1'] = from[1]
  attributes['x2'] = to[0]
  attributes['y2'] = to[1]
  attributes['stroke'] ||= 'black'
  attributes['stroke-width'] ||= STROKE_WIDTH.to_s
  $svgroot.add_element('line', attributes)
end

def svg_arrow(from, to, attributes = {})
  attributes['marker-end'] = 'url(#Triangle)'
  svg_line(from, to, attributes)
end

def svg_fork_arrow(from, to, attributes = {})
  attributes['d'] = "M #{from[0]},#{from[1]} H #{to[0]-CURVE_RADIUS} a #{CURVE_RADIUS},#{CURVE_RADIUS} 0 0,1 #{'-' if from[0] > to[0]}#{CURVE_RADIUS},#{CURVE_RADIUS} V #{to[1]}"
  attributes['fill'] = 'none'
  attributes['stroke'] ||= 'black'
  attributes['stroke-width'] ||= STROKE_WIDTH.to_s
  attributes['marker-start'] = 'url(#Circle)'
  attributes['marker-end'] = 'url(#Triangle)'
  $svgroot.add_element('path', attributes)
end

def svg_join_arrow(from, to, attributes = {})
  if from[0] < to[0]
    to_x = to[0] - (Branch::BAR_WIDTH * 0.5)
  else
    to_x = to[0] + (Branch::BAR_WIDTH * 0.5)
  end
  attributes['d'] = "M #{from[0]},#{from[1]} V #{to[1]-CURVE_RADIUS} a #{CURVE_RADIUS},#{CURVE_RADIUS} 0 0,#{from[0] > to[0] ? '1 -' : '0 '}#{CURVE_RADIUS},#{CURVE_RADIUS} H #{to_x}"
  attributes['fill'] = 'none'
  attributes['stroke'] ||= 'black'
  attributes['stroke-width'] ||= STROKE_WIDTH.to_s
  attributes['marker-end'] = 'url(#Triangle)'
  $svgroot.add_element('path', attributes)
end

def svg_text(pos, text, attributes = {})
  attributes['x'] = pos[0]
  attributes['y'] = pos[1]
  attributes['style'] ||= 'font-size:#{FONT_SIZE}'
  e = Element.new('text')
  e.add_attributes(attributes)
  e.text = text
  $svgroot.add(e)
end

def svg_codetext(pos, text, attributes = {})
  attributes['style'] ||= 'font-size:#{FONT_SIZE};font-family:Courier New'
  svg_text(pos, text, attributes)
end

class Branch

  BAR_WIDTH = 12.0
  PADDING = 80.0
  LABEL_PAD = 5.0

  @@next_x_pos = 2 * PADDING

  attr_reader :x_pos, :id, :parent

  def initialize(y_creation, id, parent)
    @id = id
    @parent = parent
    @x_pos = @@next_x_pos
    @@next_x_pos += PADDING
    @recent_y_pos = y_creation
    @active = true
    @forks = 0
    svg_text([@x_pos + TEXT_X_PAD, y_creation - LABEL_PAD], @id) #, {'text-anchor' => 'middle'})
    hbar(y_creation)
  end

  def active?
    @active
  end

  def activate(y_pos)
    catch_up_lines(y_pos)
    @active = true
  end

  def deactivate(y_pos)
    catch_up_lines(y_pos)
    @active = false
  end
  
  def quit(y_pos)
    catch_up_lines(y_pos)
    hbar(y_pos) if @continue_dblline
  end

  def add_fork(y_pos)
    catch_up_lines(y_pos)
    @forks += 1
  end

  def rm_fork(y_pos)
    catch_up_lines(y_pos)
    @forks -= 1
  end

  def catch_up_lines(y_pos)
    return if y_pos == @recent_y_pos
    if active?
      if @forks > 0
        thick_vline(@recent_y_pos, y_pos)
      else
        dbl_vline(@recent_y_pos, y_pos)
      end
    else
      dashed_vline(@recent_y_pos, y_pos)
    end
    @recent_y_pos = y_pos    
  end

  def hbar(y_pos)
    svg_line([@x_pos - BAR_WIDTH * 0.5, y_pos], [@x_pos + BAR_WIDTH * 0.5, y_pos])
  end

  def dbl_vline(y_from, y_to)
    hbar(y_from) unless @continue_dblline
    svg_line([@x_pos - BAR_WIDTH * 0.5, y_from], [@x_pos - BAR_WIDTH * 0.5, y_to])
    svg_line([@x_pos + BAR_WIDTH * 0.5, y_from], [@x_pos + BAR_WIDTH * 0.5, y_to])
    @continue_dblline = true
  end
  
  def thick_vline(y_from, y_to)
    hbar(y_from) if @continue_dblline
    svg_line([@x_pos, y_from], [@x_pos, y_to],
             {} # TODO
            )
    @continue_dblline = false
  end

  def dashed_vline(y_from, y_to)
    hbar(y_from) if @continue_dblline
    svg_line([@x_pos, y_from], [@x_pos, y_to],
             {'stroke-dasharray' => '10,10'}
            )
    @continue_dblline = false
  end

end # class Branch

y_pos = 0.0
branches = { '*' => Branch.new(y_pos, '*', nil) }

YAML.load_stream(STDIN) do |incident|
  case incident
  when Hash
    case incident[:incident]
    when nil
      raise
      
    when :logic_line_pursue
      warn "INCIDENT #{incident[:incident]}: #{incident[:content]}"
      y_pos += Y_DIFF
      svg_line([0.0, y_pos], [WIDTH, y_pos], {'stroke' => 'gray', 'stroke-dasharray' => '5,5'})
      svg_codetext([CODE_X, y_pos - TEXT_Y_PAD_BTM], incident[:content], {'fill' => 'gray'})
      
    when :ccbranch_new
      warn "INCIDENT #{incident[:incident]}: #{incident[:id]}"
    when :ccbranch_fork
      warn "INCIDENT #{incident[:incident]}: #{incident[:fork_id]}"
      parent = branches[incident[:parent]]
      fork_y_pos = y_pos + Y_DIFF
      fork_id = incident[:fork_id]
      fork = branches[fork_id] = Branch.new(fork_y_pos, fork_id, parent)
      parent.add_fork(y_pos)
      svg_text([parent.x_pos + Branch::BAR_WIDTH + TEXT_X_PAD, y_pos - TEXT_Y_PAD_BTM], incident[:condition], {'fill' => 'blue'})
      svg_fork_arrow([parent.x_pos, y_pos], [fork.x_pos, fork_y_pos]) if parent
      y_pos = fork_y_pos
      fork.dbl_vline(y_pos, y_pos + 2.0)
      y_pos += 2.0
    when :ccbranch_merge
      warn "INCIDENT #{incident[:incident]}: #{incident[:first_id]}, #{incident[:second_id]}"
      next_y_pos = y_pos + Y_DIFF

      first = branches.delete(incident[:first_id])
      first.quit(y_pos)
      second = branches.delete(incident[:second_id])
      second.quit(y_pos)

      into_id = incident[:into_id]
      into = branches[into_id] = Branch.new(next_y_pos, into_id, first.parent)
      first.parent.rm_fork(y_pos)

      svg_join_arrow([first.x_pos , y_pos], [into.x_pos, next_y_pos])
      svg_join_arrow([second.x_pos, y_pos], [into.x_pos, next_y_pos])

      y_pos = next_y_pos
      
      into.dbl_vline(y_pos, y_pos + 2.0)
      y_pos += 2.0
    when :ccbranch_join
      warn "INCIDENT #{incident[:incident]}: #{incident[:from_id]}"
      
      from = branches.delete(incident[:from_id])
      from.quit(y_pos)
      into = branches[incident[:into_id]]
      
      next_y_pos = y_pos + Y_DIFF
      into.rm_fork(next_y_pos)
      svg_join_arrow([from.x_pos, y_pos], [into.x_pos, next_y_pos])
      y_pos = next_y_pos
      
    when :ccbranch_activate
      warn "INCIDENT #{incident[:incident]}: #{incident[:branch_id]}"
      branches[incident[:branch_id]].activate(y_pos)
    when :ccbranch_deactivate
      warn "INCIDENT #{incident[:incident]}: #{incident[:branch_id]}"
      branches[incident[:branch_id]].deactivate(y_pos)
      
    else
      warn "unhandled incident: `#{incident[:incident]}'"
    end
  else
    raise
  end
end

y_pos += Y_DIFF

rootbranch = branches.delete('*')
rootbranch.deactivate(y_pos)

branches.each do |id, obj|
  b.abort(y_pos)
end

svgdoc.write($stdout, 0)
