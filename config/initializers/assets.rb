# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.5'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
# Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
Rails.application.config.assets.precompile += %w[pdf.css pdfjs-dist/build/pdf.worker.js]
Rails.application.config.assets.precompile += Dir[Rails.root.join('vendor/assets/bower_components/**/img/*')]

Rails.application.config.assets.configure do |env|
  env.export_concurrent = false
end
