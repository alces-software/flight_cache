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

require 'faraday_middleware'
require 'flight_cache/error'
require 'flight_cache/models'

class FlightCache
  class Client
    class RaiseError < Faraday::Response::RaiseError
      def call(req)
        @app.call(req).on_complete do |res|
          case res.status
          when 401
            raise UnauthorizedError, res.body&.error
          when 403
            raise ForbiddenError
          else
            on_complete(req)
          end
        end
      end
    end

    attr_reader :host
    attr_reader :token

    def initialize(host, token)
      @host = host
      @token = token
    end

    def connection
      Faraday::Connection.new(host) do |conn|
        conn.token_auth(token)
        conn.request :json

        conn.use RaiseError

        conn.use FaradayMiddleware::Mashify
        conn.response :json, :content_type => /\bjson$/

        conn.adapter Faraday.default_adapter
      end
    end

    def host
      (v = @host).to_s.empty? ? (raise 'No host given') : v
    end

    def token
      (v = @token).to_s.empty? ? (raise 'No token given'): v
    end

    def blobs
      Models::Blob.builder(self)
    end

    def containers
      Models::Container.builder(self)
    end
  end
end
