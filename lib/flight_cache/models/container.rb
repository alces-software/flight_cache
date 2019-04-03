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

        def list(tag: nil)
          build_enum do |con|
            if tag
              con.get(paths.tagged(tag)).body.data
            else
              con.get(join).body.data
            end
          end
        end
      end

      data_id
      data_attribute :tag_name
      data_attribute :scope
      data_attribute :restricted

      def upload(*a)
        builder.client.blobs.uploader(*a).to_container(id: self.id)
      end
    end
  end
end
