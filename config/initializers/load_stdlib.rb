# frozen_string_literal: true

# Explicit stdlib loads.
#
# Ruby 3.4+ stopped auto-loading parts of stdlib that were previously
# pulled in as a transitive side-effect of various gems. The list of
# gems that happened to `require "ostruct"` has shrunk over time —
# whenever a Gemfile bump drops the last such gem from the dep tree,
# any view / helper using `OpenStruct` 500s with
# `NameError: uninitialized constant ::OpenStruct`.
#
# `app/views/shared/tables/_filter.html.erb` uses `OpenStruct.new`,
# and an indeterminate set of other call sites may too. Pulling the
# require in here makes the app immune to which gems happen to load
# it transitively.
require "ostruct"
