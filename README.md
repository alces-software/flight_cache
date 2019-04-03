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

### Creating the cache API interface

The interface requires your flight\_sso\_token and the servers host address

```
require 'flight_cache'
cache = FlightCache.new(HOST_ADDRESS, FLIGHT_SSO_TOKEN)
```

### Getting, Downloading, and Deleting a Blob

A file (aka a `Blob`) can be retrieved using the `blob` method. This will
return the metadata `Blob` object. To download the `Blob` please use the
`download` methods. The `download` return an `IO` with the files data\*.
The `delete` action will destroy the blob and then return the metadata,
similarly to `get`.

All the methods take the blob `id` as there input.

```
> cache.blob(<id>)
=> <#FlightCache::Models::Blob:..>

> cache.download(<id>)
=> <#IO:..>

> cache.blob(<id>).download
=> <#IO:..>

> cache.delete(<id>)
=> <#FlightCache::Models::Blob:..> # And deletes the blob
```

\*NOTE: The downloaded `IO` will either be a `StringIO` or `Tempfile`
depending  on the file size

### List All the Tags

The `tags` method will return a list of all the available tags. See below for
further details on tagging.

```
> cache.tags
=> [<#FlightCache::Models::Tag:..>]
```

### Listing Blobs
#### Listing all the blobs
The `blobs` method when called without any arguments will return all the
blob's the user has access to. These blobs will be of different types and
will include the `global` and `group` scopes.

```
> cache.blobs
=> [<#FlightCache::Models::Blob:..>, ..] # List all the blobs
```

#### Filtering by scope
The optional `scope:` key will filter the blobs by their ownership scope. The
returned blobs could still be of any `tag`.

```
> cache.blobs(scope: <scope_value>)
=> [<#FlightCache::Models::Blob:..>, ..] # Limits the blobs to the single scope
```

#### By tag and scope

The `blobs` method will return a list of `Blob`s of a particular tag. The
`tag_name` must be a `String`. Optionally, the list can be further filtered
by `scope`. See below for further explanations on tagging and scoping.

If the `scope` is not supplied, it will retrieve `Blobs` from all the users
scopes.

```
> cache.blobs(tag: <tag_name>)
=> [<#FlightCache::Models::Blob:..>, ..] # List all blobs of a particular tag

> cache.blobs(tag: <tag_name>, scope: <scope_value>)
=> [<#FlightCache::Models::Blob:..>, ..] # Filter the blobs further by scope
```

### Uploading a blob

New blobs can be uploaded from an `IO` using the `upload` method. The upload
needs to be given a `name` and a `tag:` to upload to. By default, the blobs is
uploaded into the `:user` scope. The optional `scope:` key can be used to
change this.

```
> cache.upload(<name>, <io>, tag: <tag_name>)
=> <#FlightCache::Models::Blob:...> # Uploads the blob into the :user scope

> cache.upload(<name>, <io>, tag: <tag_name>, scope: <scope>)
=> <#FlightCache::Models::Blob:...> # Uploads the blob into the specified scope
```

## Explanatory Details

The following is an overview on how the `scoping` and `tagging` features of
FlightCache work.

### Details on scoping

Through out this guide, there will be references to a `scope`. This used to
narrow down the number of models depending on how they are owned.

Each model can have exactly one "owner". `Container`s directly have an owner,
where `Blob`s have an owner via its container.

Each `Container` can have exactly one owner which will determine how it is
scoped:
1. A user,            `scope = :user`,
2. A group,           `scope = :group`,
3. The global group,  `scope = :global`\*
4. No scope given,    See defaults below
5. Any other value,   Consider the same as no scope given

\* In theory a user could belong to the global group, making their `:group` and
`:global` scopes equivalent. In practice however, this should never happen.

Because each owner (`user`/`group`/`global group`) maintains its own set of
`Container`s/models, the scope is a easy way to toggle between them.

#### Scoping Behaviour - Get (single model)

*NOTE*: This section mainly refers to getting a `Container`. It is not possible to
get a `Blob` using the scope.

Get requests (that fetch a single model) will default to using the `:user`
scope. The `:user` scope will return the model that belongs to the user.

By setting the scope to `:group`, it will trigger the model that belongs to
the user's group to be returned. The `:global` scope is similar but returns
the model that belongs to the global group.

#### Scoping Behaviour - List (multiple models)

The toggling behaviour of the `scope` is the same when listing multiple models,
with exception of the default.

This means the `:user` scope will still only return models that the user directly
owns. Similarly, the `:group` and `:global` scopes only return models that are
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

## Advanced Usage - FlightCache::Client

The following is the summary on the underling client that makes the requests.
It provides further features that are not available in the basic syntax above.

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

All the blobs can be returned using the `list` method.

```
> blobs = client.blobs.list
=> [<#FlightCache::Models::Blob:..>, ...]
```

Blobs can also be filtered by tag by using the `list(tag:)` method. It will
return all the blobs the user has access to; filtered by tag.

```
> blobs = client.blobs.list(tag:)
=> [<#FlightCache::Models::Blob:..>, ...]
```

The `:scope` key can be used to filter the blobs depending on user permissions.

```
# NOTE: Volatile
> client.blobs.list(scope:)
=> [...] # Only return blobs with the specified scope
```

The `:scope` and `:tag` filters can be combined to get all the blobs of a
particular tag and scope.

```
> client.blobs.list(scope:, tag:)
=> [...] # Only return blobs with the specified tag and scope
```

#### Downloading a blob

The blob can be downloaded by its id using the `download` method. This is
essentially the same as a `get` without first retrieving the metadata model
object.

If the metadata model has already been fetched, then it can be downloaded using
the instance method:

```
> client.blobs.download(id:)
=> <#IO:...>

> client.blobs.download(id:) { |io| ... }
=> # Result of the block

# Downloading via a get
# NOTE: This will perform two request
> client.blobs.get(id:).download
=> ... # As above
```

#### Uploading a blob

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

#### Deleting a blob

The `delete` action is similar to a `get` request, but also destroys the blob.

```
> blob = client.blobs.get(id: 1)
=> <#FlightCache::Models::Blob:...> # And deletes the blob
```

### Tag Builder

#### Getting a Tag

Tags can only be retrieved individually by `:id`:

```
> client.tags.get(id:)
=> <#FlightCache::Models::Tag:..>
```

#### Listing Tags

To get the complete list of tags, use the `list` method:

```
> client.tags.list
=> [<#FlightCache::Models::Tag:..>, ...]
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

All the containers the user has access to is returned from `list`. This can
be further filtered using the `:tag` option.

```
> client.containers.list
=> [<#FlightCache::Models::Container:..>, ...]

> client.containers.list(tag:)
=> [...] # Filters the Containers by tag
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

