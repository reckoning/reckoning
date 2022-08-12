# frozen_string_literal: true

Refile.backends['store'] = Refile::Backend::FileSystem.new(Rails.public_path.join('uploads'))
