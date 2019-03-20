# README
## Standalone usage

To use the client in standalone mode:
```
export FLIGHT_SSO_TOKEN=....  # Your SSO token
export FLIGHT_CACHE_HOST=...  # The domain to the app e.g. 'localhost:3000'
bundle install
rake console
```

## Usage

### Creating A Client

The client requires your flight\_sso\_token and the servers host address

```
require 'flight_cache'
client = FlightCache::Client.new(HOST_ADDRESS, FLIGHT_SSO_TOKEN)
```

### Using the "Builders" (sub clients)

The client has been organised into two sub clients: `blobs` and `containers`.
Broadly a call to the `blobs` client manages `FlightCache::Models::Blob`
and similarly `containers` manages `FlightCache::Models::Container`.

For the remainder of this guide, the sub-clients will be referred to as
`Builder`s.

These builders wrap their underling model class but provide the additional
"build" methods. These methods are used to interact with the server and converts
the response to a model.

### Blobs Builder

The blobs builder is returned by:
```
> client.blobs
=> FlightCache::Models::Blob
```

#### Getting Blob

A single blob can be retrieved using the `get` method using its `:id`:

```
> blob = client.blobs.get(id: 1)
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

#### Listing Blobs

Blobs can also be filtered by tag by using the `list(tag:)` method. It will
return all the blobs the user has access to; filtered by tag.

```
> blobs = client.blobs.list(tag: <tag>)
=> [<#FlightCache::Models::Blob:..>, ...]
```

This will list all the blobs in all the users containers of that type. The
`:scope` key can be used to filter the blobs depending on user permissions.

See below for a full discussion on the valid scope
```
> client.blobs.list(tag: <tag>, scope: <scope>)
=> [...] # Only return blobs with the specified tag and scope
```

#### Downloading a blob

The blob can be downloaded by its id using the `download` method. This is
essentially the same as a `get` without first retrieving the metadata model
object.

If the metadata model has already been fetched, then it can be downloaded using
the instance method:

```
> client.blobs.download(1)
=> <#String:..> # Maybe a hashie? This needs to be clarified

# Downloading via a get
# NOTE: This will perform two request
> client.blobs.get(1).download
=> ... # As above
```

### Uploading

There is an `upload` method on the client. See code for details.
