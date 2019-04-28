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
      # TODO: Deprecated
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

        def get(id: nil, tag: nil, filename: nil, scope: :user, admin: false)
          build do |con|
            path = get_path(id, scope, tag, filename)
            con.get(path, admin: admin).body.data
          end
        end

        def list(tag: nil, scope: nil, admin: nil, label: nil, wild: false)
          build_enum do |con|
            con.get(join, scope: scope, admin: admin, tag: tag, label: label, wild: wild)
               .body
               .data
          end
        end

        def delete(id: nil, tag: nil, filename: nil, scope: :user, admin: false)
          build do |con|
            path = get_path(id, scope, tag, filename)
            con.delete(path, admin: admin).body.data
          end
        end

        def download(id: nil, tag: nil, filename: nil, scope: :user, admin: false, &b)
          path = get_path(id, scope, tag, filename)
          url = client.connection
                      .get("#{path}/download", admin: admin)
                      .headers["location"]
          open(url, &b)
        end

        def upload(filename:,
                   io:,
                   title: nil,
                   label: nil,
                   container_id: nil,
                   tag: nil,
                   scope: :user,
                   admin: :false)
          path = if id
                   client.containers.join(id, 'blobs')
                 elsif tag && scope
                   paths.bucket(scope, tag, 'blobs')
                 else
                   raise BadRequestError
                 end

          payload = {
            filename: filename,
            admin: admin,
            payload: Faraday::UploadIO.new(io, 'application/octet-stream')
          }.tap do |hash|
            hash[:title] = title if title
            hash[:label] = label if label
          end

          build do |con|
            con.post(path, payload).body.data
          end
        end

        def update(id: nil,
                   container_id: nil,
                   tag: nil,
                   scope: :user,
                   admin: false,
                   filename: nil,
                   new_filename: nil,
                   title: nil,
                   label: nil,
                   io: nil)
          path = if id
                   join(id)
                 elsif container_id && filename
                   client.containers.join(container_id, 'blobs', filename)
                 elsif tag && scope && filename
                   paths.bucket(scope, tag, 'blobs', filename)
                 else
                   raise BadRequestError
                 end

          payload = { admin: admin }.tap do |hash|
            hash[:filename] = new_filename if new_filename
            hash[:title] = title if title
            hash[:payload] = Faraday::UploadIO.new(io, 'application/octet-stream') if io
            hash[:label] = label if label
          end

          build do |con|
            con.put(path, payload).body.data
          end
        end

        # TODO: Deprecated!
        def uploader(filename:, io:)
          Uploader.new(self, filename, io)
        end

        private

        def get_path(id, scope, tag, filename)
          if id
            join(id)
          elsif tag && filename && scope
            paths.bucket(scope, tag, 'blobs', URI.encode(filename))
          else
            raise BadRequestError
          end
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
      data_attribute :title, required: false, default: ''
      data_attribute :label

      def download
        builder.download(id: self.id)
      end
    end
  end
end
