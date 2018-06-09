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

The code below uses Sinatra to demonstrate how to use the library in a web application.
This library makes no assumptions about any web framework, you can use it in any way you see fit.

```ruby
require 'akasha'
require 'sinatra'

class User < Akasha::Aggregate
  def sign_up(email:, password:, admin: false, **)
    changeset.append(:user_signed_up, email: email, password: password, admin: admin)
  end

  def on_user_signed_up(email:, password:, admin:, **)
    @email = email
    @password = password
    @admin = admin
  end
end


before do
  @router = Akasha::CommandRouter.new

  # Aggregates will load from and save to in-memory storage.
  repository = Akasha::Repository.new(Akasha::Storage::MemoryEventStore.new)
  Akasha::Aggregate.connect!(repository)

  # This is how you link commands to aggregates.
  @router.register_default_route(:sign_up, User)

  # Nearly identital to the default handling above but we're setting the admin
  # flag to demo custom command handling.
  @router.register_route(:sign_up_admin) do |aggregate_id, **data|
    user = User.find_or_create(aggregate_id)
    user.sign_up(email: data[:email], password: data[:password], admin: true)
    user.save!
  end
end

post '/users/:user_id' do # With CQRS client pass unique aggregate ids.
  @router.route!(:sign_up,
                 params[:user_id],
                 email: params[:email],
                 password: params[:password])
  'OK'
end
```

> Currently, only memory-based repository is supported.

## Next steps

- [x] Command routing (default and user-defined)
- [x] Synchronous EventHandler
- [x] HTTP Eventstore storage backend
- [ ] Namespacing for events and aggregates
- [ ] Event#id for better idempotence (validate this claim)
- [ ] Version-based concurrency
- [ ] Async EventHandlers (storing cursors in Eventstore, configurable durability guarantees)
  - [ ] Uniform intetrface for Client -- use Event.
- [ ] Telemetry (Dogstatsd)
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
docker run --name akasha-eventstore -it -p 2113:2113 -p 1113:1113 -d eventstore/eventstore
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

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
