# frozen_string_literal: true

Refile.backends['store'] = Refile::Backend::FileSystem.new(Rails.root.join('public/uploads'))
