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

require 'hashie/trash'

module FlightCache
  module Models
    class Blob < Hashie::Trash
      module ModelHelpers
        module ClassMethods
          def data_attribute(key, from: nil)
            from ||= key
            property key, require: :data?, from: :__data__, with: ->(data) do
              data&.attributes&.[](from)
            end
          end
        end

        def self.included(base)
          base.extend ClassMethods
          base.instance_exec { property :__data__ }
        end

        def to_h
          super().dup.tap { |h| h.delete(:__data__) }
        end

        def data?
          !!__data__
        end
      end
      include ModelHelpers

      property :id,
               required: :data?,
               from: :__data__,
               with: ->(d) { d&.id }

      property :container,
               required: :data?,
               from: :__data__,
               with: ->(data) do
                 Container.api_build(data.relationships&.container&.data)
               end

      data_attribute :checksum
      data_attribute :filename
      data_attribute :size, from: :byte_size

      def self.api_build(data)
        new(__data__: data)
      end

      def self.index_by_tag(tag, client:)
        client.connection.gets_by_tag(tag).body.data.map { |b| api_build(b) }
      end

      def self.show(id, client:)
        api_build(client.connection.get_by_id(id).body.data)
      end

      def self.download(id, client:)
        client.connection.download_by_id(id).body
      end
    end
  end
end
