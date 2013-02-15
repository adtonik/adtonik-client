#!/usr/bin/env ruby

ver = `git describe --tags`.strip

if ver.size == 0
  ver = `git rev-parse HEAD`.strip if ver.empty?
end

path = File.join(File.dirname(__FILE__), "adtonik/internal/common")

template = open(File.join(path, "ADTVersion.h.in")).read
template.gsub!(/\$\$ADT_BUILD_TAG\$\$/m, ver)

open(File.join(path, "ADTVersion.h"), "w") do |fd|
  fd << template
end
