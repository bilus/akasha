# Akasha

A budding CQRS library for Ruby.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'akasha'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install akasha

## Usage

There is an example Sinatra app under `examples/sinatra` showing how to use the library in a web application.
This library itself makes no assumptions about any web framework, you can use it in any way you see fit.

## TODO

- [x] Command routing (default and user-defined)
- [x] Synchronous EventHandler
- [x] HTTP Eventstore storage backend
- [x] Event#id for better idempotence (validate this claim)
- [x] Async EventHandlers (storing cursors in Eventstore, configurable durability guarantees)
  - [x] Uniform interface for Client -- use Event.
  - [x] Rewrite Client
  - [x] Refactor Client code
  - [x] Take care of created_at/updated_at (saved_at?)
  - [x] Tests for HttpEventStore
  - [x] Projections
  - [x] Test for AsyncEventRouter using events not aggregate
  - [x] BUG: Projection reorders events (need to use fromAll after all)
  - [x] Simplify AsyncEventRouter init
  - [x] SyncEventRouter => EventRouter
  - [x] Metadata not persisted
- [x] Refactoring & simplification.
  - [x] Hash-based event and command router
  - [x] Assymetry between data and metadata
  - [x] Faster shutdown
- [x] Namespacing for events and aggregates and the projection
- [x] Way to control the number of retries in face of network failures
- [x] Version-based concurrency
- [ ] Intermittently failing rspec ./spec/akasha/async_event_router_spec.rb:34
- [ ] Snapshots
- [ ] Telemetry (configurable backend, default: Dogstatsd)
- [ ] Socket-based Eventstore storage backend


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. See Running tests.

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## Running tests

Some tests require Eventstore to be running and available via `eventstore` host name. You can exclude these specs:

```
rspec --tag ~integration
```

The easiest way to run integration tests:

```
/bin/integration-tests.sh
```

This will use docker-compose to spin up containers containing the dependencies and tests themselves.

Because it's pretty slow, you may want to spin up a docker container containing event store:

```
docker run -e EVENTSTORE_START_STANDARD_PROJECTIONS=true --name akasha-eventstore -it -p 2113:2113 -p 1113:1113 -d eventstore/eventstore
```

and use RSpec run just integration specs like so:

```
rspec --tag integration
```

or run all tests:

```
rspec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bilus/akasha.

1. Create a new PR, setting version in `lib/akasha/version.rb` to a prerelease version,
   example: `"0.4.0.pre"`.
1. Update CHANGELOG.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
