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

class FlightCache
  # Generic FlightCache Error
  class Error < StandardError; end

  # VerbotenError
  # Use: Archetype class for permission denied errors
  # Code: 40* (ish)
  class VerbotenError < Error
    MESSAGE = <<~ERROR.chomp
      You do not have permission to view this content
    ERROR

    def initialize(raw = MESSAGE)
      super
    end
  end

  # UnauthorizedError
  # Use: Accessed denied due to failing authentication
  # Code: 401
  class UnauthorizedError < VerbotenError; end

  # ForbiddenError
  # Use: Accessed denied due to lack of permissions
  # Code: 403
  class ForbiddenError < VerbotenError; end

  # NotFoundError
  # Use: The resource could not be located
  # Code: 404
  class NotFoundError < Error
    MESSAGE = 'Resource not found'

    def initialize(msg = MESSAGE)
      super
    end
  end

  # ModelTypeError
  # Use: The server response does not match the model type
  class ModelTypeError < Error; end

  # BadRequestError
  # Use: The client could not make the request for some reason
  class BadRequestError < Error; end

  # MissingBuilderError
  # Use: A model can not make an additional request as it is mising its builder
  class MissingBuilderError < Error; end
end
