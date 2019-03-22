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

require 'flight_cache/error'

class FlightCache
  module Models
    class Container < Model
      builder_class do
        api_name 'containers'
        api_type 'container'

        def get(id: nil, tag: nil, scope: nil)
          build do |c|
            if id
              c.get(join(id))
            elsif tag
              c.get(paths.tagged(tag, 'container'), scope: scope)
            else
              raise BadRequestError, <<~ERROR.chomp
                Please specify either the container :id or :tag
              ERROR
            end.body.data
          end
        end

        def list(tag:)
          build_enum do |con|
            con.get(paths.tagged(tag)).body.data
          end
        end
      end

      data_id
      data_attribute :tag_name
      data_attribute :scope

      def upload(*a)
        builder.client.blobs.uploader(*a).to_container(id: self.id)
      end
    end
  end
end
