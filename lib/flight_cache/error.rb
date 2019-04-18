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
  # Use: The client could not make the request because of insufficient
  # arguments or another reason
  class BadRequestError < Error
    MESSAGE = 'Insufficient arguments. See documentation for further detail'

    def initialize(msg = MESSAGE)
      super
    end
  end

  # MissingBuilderError
  # Use: A model can not make an additional request as it is mising its builder
  class MissingBuilderError < Error; end
end
