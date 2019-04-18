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
# For more information on flight-account, please visit:
# https://github.com/alces-software/flight_cache
#===============================================================================

require 'open-uri'

class FlightCache
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

        def list(tag: nil, scope: nil)
          build_enum do |c|
            if tag
              c.get(paths.tagged(tag, 'blobs'), scope: scope).body.data
            else
              c.get(join, scope: scope).body.data
            end
          end
        end

        def delete(id:)
          build do |con|
            con.delete(join(id)).body.data
          end
        end

        def download(id:, &b)
          url = client.connection.get(join(id, 'download')).headers["location"]
          open(url, &b)
        end

        def uploader(filename:, io:)
          Uploader.new(self, filename, io)
        end
      end

      data_id
      data_attribute :checksum
      data_attribute :filename
      data_attribute :size, from: :byte_size
      data_attribute :tag_name
      data_attribute :scope
      data_attribute :protected
      data_attribute :admin
      data_attribute :title
      data_attribute :label

      def download
        builder.download(id: self.id)
      end
    end
  end
end
