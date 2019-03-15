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

module FlightCache
  module Models
    class Blob < Model
      builder_class do
        api_name 'blobs'

        def get(id)
          build do |con|
            con.get(join(id)).body.data
          end
        end

        def list(tag:)
          coerce_build do |con|
            con.get("/tags/#{tag}/blobs").body.data
          end
        end

        def download(id)
          client.connection.get(join(id, 'download')).body
        end
      end

      data_id
      data_attribute :checksum
      data_attribute :filename
      data_attribute :size, from: :byte_size
    end
  end
end
