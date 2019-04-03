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

require 'hashie'
require 'flight_cache/path_helper'

class FlightCache
  class Model < Hashie::Trash
    include Hashie::Extensions::Dash::Coercion

    class Builder < SimpleDelegator
      def self.api_name(name = nil)
        @api_name ||= name
      end

      def self.api_type(type = nil)
        @api_type ||= type
      end

      attr_reader :client

      def initialize(client)
        @client = client
        super(klass)
      end

      def klass
        raise NotImplementedError
      end

      def join(*parts)
        "/#{self.class.api_name}/#{parts.join('/')}"
      end

      def build
        data_to_model(yield(client.connection))
      end

      def build_enum
        yield(client.connection).map { |d| data_to_model(d) }
      end

      private

      def data_to_model(data)
        unless data.type == self.class.api_type
          raise ModelTypeError, <<~ERROR.chomp
            Was expecting a #{self.class.api_type} but got #{data.type}
          ERROR
        end
        klass.new(__data__: data, __builder__: self)
      end

      def paths
        PathHelper.new
      end
    end

    def self.builder_class(&b)
      @builder_class ||= begin
        model_class = self
        Class.new(Builder) do
          define_method(:klass) { model_class }
          class_eval(&b)
        end
      end
    end

    def self.builder(client)
      builder_class.new(client)
    end

    def self.data_attribute(key, from: nil)
      from ||= key
      property key, required: true, from: :__data__, with: ->(data) do
        data&.[](:attributes)&.[](from)
      end
    end

    def self.data_id
      property :id,
               required: true,
               from: :__data__,
               with: lambda { |d| d&.id }
    end

    # First attempt at linking Models together. Delete this at will
    # It is temporarily being preserved for future reference
    #
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
    property :__builder__

    def to_h
      super().dup.tap do |h|
        h.delete(:__data__)
        h.delete(:__builder__)
      end
    end

    def data?
      !!__data__
    end

    private

    def builder
      return __builder__ if __builder__
      raise MissingBuilderError, <<~ERROR.chomp
        Can not make any additional requests as the 'builder' is missing
      ERROR
    end
  end
end

