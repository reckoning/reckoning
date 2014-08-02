module Reckoning
  CODENAME = "constellation"
  VERSION = `git describe --abbrev=0 --tags`.strip.gsub(/(\-.*)/, "") unless defined? VERSION
end
