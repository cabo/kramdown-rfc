#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'rexml/document'
require 'kramdown-rfc/autolink-iref-cleanup'

d = REXML::Document.new(ARGF.read)
autolink_iref_cleanup(d)
puts d.to_s
