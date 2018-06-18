# Changelog

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
