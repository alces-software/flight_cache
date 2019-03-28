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

require 'flight_cache/client'
require 'flight_cache/models'

class FlightCache
  attr_reader :client

  def initialize(host_url, token)
    @client = Client.new(host_url, token)
  end

  def tags
    client.tags.list
  end

  def blobs(tag: nil, scope: nil)
    client.blobs.list(tag: tag, scope: scope)
  end

  def blob(id)
    client.blobs.get(id: id)
  end

  def delete(id)
    client.blobs.delete(id: id)
  end

  def upload(name, io, tag:, scope: nil)
    client.blobs.uploader(filename: name, io: io).to_tag(tag: tag, scope: scope)
  end

  def download(id)
    client.blobs.download(id: id)
  end
end
