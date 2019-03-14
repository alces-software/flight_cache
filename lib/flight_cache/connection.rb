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

module FlightCache
  class Connection < DelegateClass(Faraday::Connection)
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

    # TODO: Remove Me!
    class CoerceIntoModels < Faraday::Middleware
      def call(req)
        @app.call(req).on_complete do |res|
          next if res.body.is_a?(String)
          res.body.data = Models.coerce_data(res.body.data)
        end
      end
    end

    def initialize(host:, token:)
      faraday = Faraday::Connection.new(host) do |conn|
        conn.token_auth(token)
        conn.request :json

        conn.use CoerceIntoModels
        conn.use FaradayMiddleware::FollowRedirects
        conn.use RaiseError

        conn.use FaradayMiddleware::Mashify
        conn.response :json, :content_type => /\bjson$/

        conn.adapter Faraday.default_adapter
      end
      super(faraday)
    end

    def get_by_id(id)
      get("/blobs/#{id}")
    end

    def download_by_id(id)
      get("/blobs/#{id}/download")
    end

    def get_container_by_id(id)
      get(container_path(id))
    end

    def upload_to_container_id(id, name, io)
      upload_path = container_path(id, 'upload', name)
      post(upload_path, io.read) do |req|
        req.headers['Content-Type'] = 'application/octet-stream'
      end
    end

    def gets_by_tag(tag)
      get(File.join("/tags/#{tag}/blobs"))
    end

    private

    def container_path(id, *path)
      File.join('/containers', id, *path)
    end
  end
end
