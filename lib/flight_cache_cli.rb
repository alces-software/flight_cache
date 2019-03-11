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

  command :'url:download' do |c|
    c.syntax = 'url:download ID'
    c.description = 'Gives the url to download a blob'
    act(c) do |id|
      puts client.urls.download_blob_url id: id
    end
  end

  command :'url:container' do |c|
    c.syntax = 'url:container ID'
    c.description = 'Gives the url to a particular container'
    act(c) do |id|
      puts client.urls.container_url id: id
    end
  end

  command :'blob' do |c|
    c.syntax = 'blob ID'
    c.description = 'Get the metadata about a particular blob'
    act(c) do |id|
      pp client.connection.get_blob_id(id).body
    end
  end

  command :'url:tag:blobs' do |c|
    c.syntax = 'url:tag:blobs TAG'
    c.description = 'Gives the url to blobs of this tag'
    act(c) do |tag|
      puts client.urls.tag_blobs_url tag: tag
    end
  end

  command :'url:upload' do |c|
    c.syntax = 'url:upload CONTAINER_ID FILENAME'
    c.description = 'Gives the url to upload a file'
    c.summary = 'POST the content of the file to this address'
    act(c) do |id, name|
      puts client.urls.container_url(id: id).sub('?', "/upload/#{name}?")
    end
  end
end

