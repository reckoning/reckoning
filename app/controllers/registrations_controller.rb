# frozen_string_literal: true

# Devise's registrations controller stays wired up so its routes resolve,
# but nothing is left for it to render: the profile is the SPA's, and saving
# it goes through /api/v1.
class RegistrationsController < Devise::RegistrationsController
end
