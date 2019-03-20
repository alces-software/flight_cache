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
# https://github.com/alces-software/flight_cache
# ==============================================================================
#

module FlightCache
  module Models
    class Blob < Model
      Uploader = Struct.new(:builder, :filename, :io) do
        def to_container(id:)
          path = container_upload_path(id)
          builder.build do |con|
            con.post(path, io.read) do |req|
              req.headers['Content-Type'] = 'application/octet-stream'
            end.body.data
          end
        end

        def to_tag(tag:, scope: nil)
          ctr = builder.client.containers.get(tag: tag, scope: scope)
          to_container(id: ctr.id)
        end

        private

        def container_upload_path(container_id)
          builder.client.containers.join(container_id, 'upload', filename)
        end
      end

      builder_class do
        api_type 'blob'
        api_name 'blobs'

        def get(id:)
          build do |con|
            con.get(join(id)).body.data
          end
        end

        def list(tag:, scope: nil)
          build_enum do |c|
            c.get(paths.tag(tag, 'blobs'), scope: scope).body.data
          end
        end

        def download(id:)
          client.connection.get(join(id, 'download')).body
        end

        def uploader(filename:, io:)
          Uploader.new(self, filename, io)
        end
      end

      data_id
      data_attribute :checksum
      data_attribute :filename
      data_attribute :size, from: :byte_size
    end
  end
end
