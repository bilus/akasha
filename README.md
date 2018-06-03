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

```ruby
require 'akasha'


class User < Akasha::Aggregate
  def sign_up(email:, password:, admin: false, **)
    changeset << Akasha::Event.new(:user_signed_up, email: email, password: password, admin: admin)
  end

  def on_user_signed_up(email:, password:, admin:, **)
    @email = email
    @password = password
    @admin = admin
  end
end

router = Akasha::CommandRouter.new

def initialize
   # Aggregates will load from and save to in-memory storage.
   repository = Akasha::Repository.new(Akasha::Storage::MemoryEventStore.new)
   Akasha::Aggregate.connect!(repository)

   # This is how you link commands to aggregates.
   router.register_default_route(:sign_up, User)

   # Same as above but demonstrating custom command handling
   router.register_route(:sign_up_admin) do |aggregate_id, **data|
     user = User.find_or_create(params[:id])
     user.sign_up(email: params[:email], password: params[:password], admin: true)
     user.save!
   end
end

post '/signup' do
  router.route!(:sign_up, params)
  # ...
end
```

> Currently, only memory-based repository is supported.

## Next steps

- [ ] Command routing (default and user-defined)
- [ ] EventHandler (relying only on Eventstore)
- [ ] HTTP Eventstore storage backend
- [ ] Namespacing for events and aggregates
- [ ] Version-based concurrency
- [ ] Rake task for running EventHandlers
- [ ] Socket-based Eventstore storage backend

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bilus/akasha.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
