# README
## Standalone usage

To use the client in standalone mode:

```
bundle install
export FLIGHT_SSO_TOKEN=....  # Your SSO token
export FLIGHT_CACHE_HOST=...  # The domain to the app e.g. 'localhost:3000'
rake console
```

## Usage

### Creating A Client

The client requires your flight\_sso\_token and the servers host address

```
require 'flight_cache'
client = FlightCache::Client.new(HOST_ADDRESS, FLIGHT_SSO_TOKEN)
```

### Details on scoping

Through out this guide, there will be references to a `scope`. This used to
narrow down the number of models depending on how they are owned.

Each model can have exactly one "owner". `Container`s directly have an owner,
where `Blob`s have an owner via its container.

Each `Container` can have exactly one owner which will determine how it is
scoped:
1. A user,            `scope = :user`,
2. A group,           `scope = :group`,
3. The public group,  `scope = :public`\*
4. No scope given,    See defaults below
5. Any other value,   Consider the same as no scope given

\* In theory a user could belong to the public group, making their `:group` and
`:public` scopes equivalent. In practice however, this should never happen.

Because each owner (`user`/`group`/`public group`) maintains its own set of
`Container`s/models, the scope is a easy way to toggle between them.

#### Scoping Behaviour - Get (single model)

*NOTE*: This section mainly refers to getting a `Container`. It is not possible to
get a `Blob` using the scope.

Get requests (that fetch a single model) will default to using the `:user`
scope. The `:user` scope will return the model that belongs to the user.

By setting the scope to `:group`, it will trigger the model that belongs to
the user's group to be returned. The `:public` scope is similar but returns
the model that belongs to the public group.

#### Scoping Behaviour - List (multiple models)

The toggling behaviour of the `scope` is the same when listing multiple models,
with exception of the default.

This means the `:user` scope will still only return models that the user directly
owns. Similarly, the `:group` and `:public` scopes only return models that are
owned by the corresponding group.

However there is no default scope when listing. This allows listing of all
models in all ownership scopes.

### Details on tagging

In addition to a `scope`, each model has a `tag`. Once again, `Container`s have
tags directly where a `Blob` inherits it via its container. The valid tags
depends on the server setup and are thus application specific.

Each owner may only own one `Container` of each `tag`. This means its possible
to resolve individual containers by its `tag` and `owner`. It also limits a
single container to each `tag` and user's ownership scope.

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
> blobs = client.blobs.list(tag:)
=> [<#FlightCache::Models::Blob:..>, ...]
```

This will list all the blobs in all the users containers of that type. The
`:scope` key can be used to filter the blobs depending on user permissions.

```
> client.blobs.list(tag:, scope:)
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

#### Uploading

Uploading a blob is a two step process. Firstly, an `Uploader` struct needs to
be created as an abstraction to the files details. It must be given the
`:filename` and an `:io` containing the file data.

```
> uploader = client.blobs.uploader(filename:, io:)
=> #<struct FlightCache::Models::Blob::Uploader:..>
```

Then the file is uploaded to a container either by `:id` or `:tag`. The `:scope`
is optional when used with a `:tag`.

```
# The following methods upload to:
> uploader.to_container(id:)    # container given by :id
> uploader.to_tag(tag:)         # the users tagged container
> uploader.to_tag(tag: scope:)  # the tagged container given by scope
```

### Container Builder

The container builder can be returned by:
```
> client.containers
=> FlightCache::Models::Container
```

#### Getting a Container

Getting a single container by `:id` is equivalent in syntax to getting a blob:

```
> ctr = client.containers.get(id: 1)
=> {
 :id=>"1",
 :tag=>..,
 :__data__=> ...
}
> ctr.class
=> FlightCache::Models::Container
```

A container can also be fetched by using a `:tag` and optional `:scope`:

```
Gets the container by tag that belongs to:
> client.containers.get(tag:)         # the user
> client.containers.get(tag:, scope:) # the object given by the scope
```

#### Listing Containers

Listing containers can only (currently) be done by `:tag`

```
> client.containers.list(tag:)
```

#### Uploading to a Container

Uploading is primarily handled by the `BlobBuilder` and thus the
`ContainerBuilder` does not have an `upload` method.

However it is possible to upload to a fetched container using the `upload`
instance method. The following method calls are equivalent in end result
but will differ in API requests:

```
# Upload directly using the BlobsBuilder
> client.blobs.uploader(<uploader_args>).to_container(<get_args>)

# First fetch the Container model and then upload to it
# NOTE: This will make two requests
> client.containers.get(<get_args>).upload(<uploader_args>)
```

