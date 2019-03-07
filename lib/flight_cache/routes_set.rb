# frozen_string_literal: true

#
# =============================================================================
# Copyright (C) 2019 Stephen F. Norledge and Alces Flight Ltd
#
# This file is part of Flight Cache
#
# Flight Cache is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Flight Cache is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Flight Cache.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Flight Cache, please visit:
# https://github.com/alces-software/flight-cache
# https://github.com/alces-software/flight-cache-cli
# ==============================================================================
#

# Require Dummy rack module (So it can define the constants)
require 'rack'

# ActiveSupport Modules
require 'active_support/concern'
require 'active_support/dependencies/autoload'
require 'active_support/core_ext/class/attribute_accessors'

# Rails routing library
require 'action_dispatch/routing'
require 'action_dispatch/http/mime_type'
require 'action_dispatch/http/content_security_policy'

# Require the parameters from active_controller
require 'action_controller/metal/strong_parameters'

module FlightCache
  class RoutesSet < SimpleDelegator
    CONFIG = File.expand_path(
      File.join(__dir__, '../../opt/flight-cache-server/config/routes.rb')
    )

    def self.new
      $global_routes = ActionDispatch::Routing::RouteSet.new
      load(CONFIG)
      super($global_routes)
    end

    def app_urls(token)
      UrlBuilder.new(self, token)
    end

    UrlBuilder = Struct.new(:app, :token) do
      def initialize(*_a)
        super
        app.routes.map { |r| :"#{r.name}_url" }.each do |s|
          next unless app.url_helpers.respond_to?(s)
          define_singleton_method(s) do |*a, **params|
            params[:flight_sso_token] = token
            app.url_helpers.public_send(s, *a, params)
          end
        end
      end
    end
  end
end

