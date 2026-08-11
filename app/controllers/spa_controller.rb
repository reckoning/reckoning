# frozen_string_literal: true

# Serves the Vue SPA shell. Authentication happens inside the SPA against
# /api/v1, so this action stays open — otherwise Devise would redirect to the
# ERB login before the SPA could render its own.
class SpaController < ApplicationController
  skip_before_action :authenticate_user!

  skip_authorization_check

  layout "spa"

  def index
  end
end
