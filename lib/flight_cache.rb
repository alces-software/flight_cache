# frozen_string_literal: true

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
    client.blobs.upload(filename: name, io: io, tag: tag, scope: scope)
  end

  def download(id)
    client.blobs.download(id: id)
  end
end
