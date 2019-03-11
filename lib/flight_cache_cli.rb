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

require 'commander'

require 'flight_cache/client'
require 'pp'

class FlightCacheCli
  extend Commander::UI
  extend Commander::UI::AskForClass
  extend Commander::Delegates

  program :name,        'flight-cache'
  program :version,     '0.0.0'
  program :description, 'TBD'
  program :help_paging, false

  silent_trace!

  def self.run!
    ARGV.push '--help' if ARGV.empty?
    super
  end

  def self.act(command)
    command.action do |args, opts|
      yield(*args, opts.to_h)
    end
  end

  def self.client
    FlightCache::Client.new(ENV['FLIGHT_CACHE_HOST'], ENV['FLIGHT_SSO_TOKEN'])
  end

  command :download do |c|
    c.syntax = 'download ID'
    c.description = 'Download the blob by id'
    act(c) do |id|
      puts client.connection.download_blob_id(id).body
    end
  end

  command :container do |c|
    c.syntax = 'container ID'
    c.description = 'Get the metedata for a particular container'
    act(c) do |id|
      pp client.connection.get_container_id(id).body
    end
  end

  command :blob do |c|
    c.syntax = 'blob ID'
    c.description = 'Get the metadata about a particular blob'
    act(c) do |id|
      pp client.connection.get_blob_id(id).body
    end
  end

  command :'tag:blobs' do |c|
    c.syntax = 'tag:blobs TAG'
    c.description = "Get all the user blobs' meteadata for a particular tag"
    act(c) do |tag|
      pp client.connection.get_tag_blobs(tag).body
    end
  end

  command :upload do |c|
    c.syntax = 'upload CONTAINER_ID FILEPATH'
    c.description = 'Upload the file to the container'
    act(c) do |id, filepath|
      io = File.open(filepath, 'r')
      name = File.basename(filepath)
      pp client.connection.upload_container_id(id, name, io).body
    end
  end
end

