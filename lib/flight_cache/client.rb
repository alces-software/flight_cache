# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of flight_cache.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# This project is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with this project. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on flight_cache, please visit:
# https://github.com/alces-software/flight_cache
#===============================================================================

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
          when 404
            if req.body.respond_to?(:error)
              raise NotFoundError, req.body.error
            else
              on_complete(req)
            end
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
        conn.request :multipart
        conn.request :url_encoded

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

    def tags
      Models::Tag.builder(self)
    end
  end
end
