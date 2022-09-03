# frozen_string_literal: true

class AppEndpointResolver
  def domain
    Rails.configuration.app.domain
  end

  def frontend_endpoint
    "#{scheme}://#{domain}"
  end

  def api_endpoint
    "#{scheme}://#{domain}/api/#{Rails.configuration.app.api_version}"
  end

  def cable_endpoint
    "#{websocket_scheme}://#{domain}/cable"
  end

  private def scheme
    if Rails.configuration.force_ssl
      'https'
    else
      'http'
    end
  end

  private def websocket_scheme
    if Rails.configuration.force_ssl
      'wss'
    else
      'ws'
    end
  end
end
