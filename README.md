# README

## Install

This app can be installed via:
```
git clone https://github.com/alces-software/flight-cache-cli
cd flight-cache-cli
bundle install
```

## Configuration

The following needs to be exported to the environment:
```
export FLIGHT_SSO_TOKEN=....  # Your SSO token
export FLIGHT_CACHE_HOST=...  # The domain to the app e.g. 'localhost:3000'
```

## Run

The app can be ran by:
```
bin/flight-cache --help # Gives the main help page
```


# FlightCache Library

## Installation

Built into flight-cache-cli

## Usage

### Creating A Client

The client requires your flight\_sso\_token and the servers host address

```
require 'flight_cache'
client = FlightCache::Client.new(HOST_ADDRESS, FLIGHT_SSO_TOKEN)
```

#### NOTE: Delegation to Blob model

When interrogating the client, it will sometimes return references to the blob
model (see below). This is due to the client being a composite object around the
blob class.

Don't trust these methods as they are all lying. Solution TBA

```
> client = FlightCache::Client.new(host, token)
=> FlightCache::Models::Blob

> client.to_s
=> "FlightCache::Models::Blob"

> client.inspect
=> "FlightCache::Models::Blob"

> client.class
=> FlightCache::Client # Yay! This one is correct

> client.methods
=> ??
```

### Getting, Listing and Downloading Blobs

A single blob can be retrieved using the `get` method. It finds the blob by
its id.

```
> blob = client.get(1)
=> {
 :id=>"1",
 :checksum=>..,
 :filename=>..,
 :size=>..,
 :__data__=> ...
}
> blob.class
=> FlightCache::Models::Blob
```

Blobs can also be filtered by tag by using the `list(tag:)` method. It will
return all the blobs the user has access to; filtered by tag.

```
> blobs = client.list(tag: <tag>)
=> [<#FlightCache::Models::Blob:..>, ...]
```

The blob can be downloaded by its id using the `download` method.
```
> client.download(1)
=> <#String:..> # Maybe a hashie? This needs to be clarified
```

### Uploading

There is an `upload` method on the client. See code for details.
