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

require 'hashie'

module FlightCache
  class Model < Hashie::Trash
    include Hashie::Extensions::Dash::Coercion

    Builder = Struct.new(:klass, :client) do
      MODEL_METHOD = :flight_cache_model_method

      def method_missing(s, *a, &b)
        if respond_to_missing?(s) == MODEL_METHOD
          klass.send(s, *a, client: client, &b)
        else
          super
        end
      end

      def respond_to_missing?(s)
        return MODEL_METHOD if klass.respond_to?(s)
        super
      end
    end

    def self.builder(client)
      Builder.new(self, client)
    end

    def self.build(data, complete: true)
      new(__data__: data, complete?: complete)
    end

    def self.data_attribute(key, from: nil)
      from ||= key
      property key, required: :complete?, from: :__data__, with: ->(data) do
        data&.attributes&.[](from)
      end
    end

    def self.data_id
      property :id,
               required: :complete?,
               from: :__data__,
               with: lambda { |d| d&.id }
    end

    # First attempt at linking Models together. Delete this at will
    # It is temporarily being preserved for future reference
    #
    # def self.data_link(key, from: nil)
    #   from ||= key
    #   property key,
    #            required: :complete?,
    #            from: :__data__,
    #            coerce: Models.method(:coerce_data).to_proc,
    #            with: ->(data) do
    #              data&.relationships&.send(from)&.data
    #            end
    # end

    property :__data__
    property :complete?, default: false

    def to_h
      super().dup.tap { |h| h.delete(:__data__) }
    end

    def data?
      !!__data__
    end
  end
end

