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

A single blob can be retrieved using the `get` method using the `:id` parameter.
The `id` will always take precedence over following get methods.

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

It is also possible to to retrieve blobs using their `:filename` and `:tag`.
This will implicitly determine the appropriate file using the scoping
mechanism. By default it will retrieve the blob in the non admin
"user" `:scope`. These defaults can be changed using the `:scope` and
`:admin` flags.

```
> client.blobs.get(tag: <tag>, filename: <filename>)
=> # Returns the blob in the non admin user container

> client.blobs.get(tag: <tag>, filename: <filename>, scope: <scope>)
=> # Retreive the blob in the specified scope

# For admin use ONLY
> client.blobs.get(tag: <tag>, filename: <filename>, admin: true)
=> Will retreive the blob from the admin only user container

> client.blobs.get(tag:, filename:, admin:, scope:)
=> Specifiy a different admin only scope to search

# NOTE: Giving an id with other arguments
> client.blobs.get(id:, tag:, filename:, admin:, scope:)
=> Ignores the other flags and returns the blob by id
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

Admins can also index the admin only blobs using the `:admin` flag. This can be
used with all the above filters.

```
> client.blobs.list(scope:, tag:, admin: true)
```

##### Filtering the blobs list by label

Each blob can have an optional `:label`. This label will be an alphanumeric
delimited by forward slash `/`. Their are two different ways to match the
label: exactly and `:wild`. These filters can be used with all the listing
options above.

An "exact" match only returns blobs where the `:label` is a literal match.
An exact match will be done by default or when the `:wild` flag is `false`.

A "wild" match will return the blobs from the exact match AND any labels that
match up to a `/`.

```
# Exact match
> client.blobs.list(label:)

# Wild match
> client.blobs.list(label:, wild: true)

Example:
> client.blobs.list(label: 'a/b', wild: true)
=> # Returns all blobs with label a/b OR a/b/* where * can be anything
   # However it will not return label a OR a/bc etc.
```

#### Downloading a blob

A blob can be download using the `download` method. It takes the same arguments
as `get` but will redirect the request to the service url.

If the metadata model has already been fetched, then it can be downloaded using
the instance method:

```
> client.blobs.download(id:) # Or other arguments as described under get
=> <#IO:...>

> client.blobs.download(id:) { |io| ... }
=> # Result of the block

# Downloading via a get
# NOTE: This will perform two request
> client.blobs.get(id:).download
=> ... # As above
```

#### Uploading a blob

A blob can be uploaded to either directly to a container or implicitly to a
tag. The `:container_id` takes priority and will override the following options.
The container can also be implicitly inferred from the `:tag`, `:scope`, and
`:admin` flags. It works in a similar way to getting a `container` where `:scope`
and `:admin` default to `user` and `false` respectively.

A `:filename` and `:io` are always required. The `:filename` must be unique within
the `container`. The `io` will usually be an open file descriptor for reading but
maybe any `IO` type object.

The `:title` is an optional human readable name that can be sent with any form of
the request. It does not have to be unique. The `:label` is also optional but must
be an alphanumeric string that is delimited by forward slashes `/`.

```
# Direct upload
> client.blobs.upload(filename:, io:, container_id:)
> client.blobs.upload(filename:, title:, label:, io:, container_id:)

# Tagged upload
> client.blobs.upload(filename:, io:, tag:)
> client.blobs.upload(filename:, title:, label:, io:, tag:, scope:, admin:)
```

##### Uploading to a container model

It is also possible to upload to an existing `Container` model. This requires
getting the container first. This method requires the `:filename` and `:io`
but not the container/scope parameters. It still can take the optional
`:title` and `label` fields.

```
# Get the Container (see below)
> container = client.containers.get(...)

# Upload to the Container
> container.upload(filename:, io:)
> container.upload(filename:, io:, label:, title:)
```

#### Updating a blob

A blob's `filename`, `title`, `:label`, and content can be updated using the
`update` method. The blob to be updated can be selected in the following three
ways (in priority order):
1. Directly using its `:id`
2. Indirectly via its `:container_id` and `:filename`
3. Indirectly using the tag/scope system and its `:filename`

Because the `:filename` can be used to select the corresponding file, the
updated filename is given by the `:new_filename` key. The scoping system
uses the standard `:scope`, `:tag`, `admin` keys and defaults.


```
# Optional arguments are denoted with a nil

# Direct update to the blob id
> client.blobs.update(id:, new_filename: nil, title: nil, io: nil)

# Indirect update to a container
> client.blobs.update(
    container_id:, filename:, new_filename: nil, title: nil, io: nil
  )

# Indirect update using a scope
> client.blobs.update(
    tag:, filename:, scope: nil, admin: nil, new_filename: nil, title: nil, io: nil
  )
```

#### Deleting a blob

The `delete` action is similar to a `get` request, but also destroys the blob.

```
> blob = client.blobs.get(id: 1) # Or other arguments as described under get
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

Getting a single container by `:id` is equivalent in syntax to getting a blob.
Containers can also be retrieved by `:tag` in a similarly blobs (without
the `filename`). Once again the `:scope` defaults to "user" and `:admin` to false.
These flags can be overridden in the same manner as a Blob.

```
> ctr = client.containers.get(id: 1)
=> {
 :id=>"1",
 :tag=>..,
 :__data__=> ...
}
> ctr.class
=> FlightCache::Models::Container

> client.containers.get(tag: <tag>)
=> Returns the non admin tagged container in the user scope

> client.containers.get(tag:, scope:, admin:)
=> Returns the corresponding container in the same manner as blobs
```

A container can also be fetched by using a `:tag` and optional `:scope`:

```
Gets the container by tag that belongs to:
> client.containers.get(tag:)         # the user
> client.containers.get(tag:, scope:) # the object given by the scope
```

#### Listing Containers

All the containers the user has access to is returned from `list`. This can
be further filtered using the `:tag` option. The `:admin` option gives weather
the admin or non admin containers should be returned.

```
> client.containers.list
=> [<#FlightCache::Models::Container:..>, ...]

> client.containers.list(tag:)
=> [...] # Filters the Containers by tag

> client.containers.list(admin: true)
=> Returns the admin containers
```

# License
Eclipse Public License 2.0, see LICENSE.txt for details.

Copyright (C) 2019-present Alces Flight Ltd.

This program and the accompanying materials are made available under the terms of the Eclipse Public License 2.0 which is available at https://www.eclipse.org/legal/epl-2.0, or alternative license terms made available by Alces Flight Ltd - please direct inquiries about licensing to licensing@alces-flight.com.

flight_cache is distributed in the hope that it will be useful, but WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more details.

