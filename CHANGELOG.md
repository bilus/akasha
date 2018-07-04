# Changelog

## Version 0.4.0

* Support for optimistic concurrency for commands. Enabled by default, will raise `ConflictError` if the aggregate
  handling a command is modified by another process. Will internally retry the command up to 2 times before giving up.
  See `OptimisticTransactor` for a list of available options you can pass to `CommandRouter#route!`. [#17](https://github.com/bilus/akasha/pull/17)

* Control the maximum number of retries in case of network related failures. [#14](https://github.com/bilus/akasha/pull/14)

  Example:
   ```ruby
   store = Akasha::Storage::HttpEventStore.new(..., max_retries: 10)
   ```

* Optional namespacing for aggregate/projection streams and events allowing for isolation
  between applications. [#12](https://github.com/bilus/akasha/pull/12)

* Fix Unhandled events in stream break aggregate loading. [Issue #5](https://github.com/bilus/akasha/issues/5)

* Fixed issue for passsing Handlers to EventRouter via constructor, when they are not wrapped in array. [#15](https://github.com/bilus/akasha/pull/15)

* Make `AsyncEventRouter` compatible with `MemoryEventStore`. [#18](https://github.com/bilus/akasha/pull/18)


## Version 0.3.0

* Asynchronous event listeners (`AsyncEventRouter`). [#9](https://github.com/bilus/akasha/pull/9)

* Simplified initialization of event- and command routers. [#10](https://github.com/bilus/akasha/pull/10)

* Remove dependency on the `http_event_store` gem.

* `Event#metadata` is no longer OpenStruct. [#10](https://github.com/bilus/akasha/pull/10)


## Version 0.2.0

* Synchronous event listeners (see `examples/sinatra/app.rb`). [#4](https://github.com/bilus/akasha/pull/4)

* HTTP-based Eventstore storage. [#7](https://github.com/bilus/akasha/pull/7)


## Version 0.1.0

* Cleaner syntax for adding events to changesets: `changeset.append(:it_happened, foo: 'bar')`. [#1](https://github.com/bilus/akasha/pull/1)

* Support for command routing (`Akasha::CommandRouter`). [#2](https://github.com/bilus/akasha/pull/2)


## Version 0.0.1

Initial release, basic functionality.
