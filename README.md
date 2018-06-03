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
  def sign_up(email, password)
    changeset << Akasha::Event.new(:user_signed_up, email: email, password: password)
  end

  def on_user_signed_up(email:, password:, **)
    @email = email
    @password = password
  end
end

def initialize
   repository = Akasha::Repository.new(Akasha::Storage::MemoryEventStore.new)
   Akasha::Aggregate.connect!(repository)
end

def handle_sign_up_command(params)
  user = User.find_or_create(params[:id])
  user.sign_up(params[:email], params[:password])
  user.save!
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
