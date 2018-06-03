# Akasha

A budding CQRS library for Ruby.

## Quick start

```ruby
require 'akasha'


class User < Akasha::Aggregate
  def sign_up(email, password)
    changeset << Akasha::Event.new(:user_signed_up, email: email, password: password)
  end

  def on_user_signed_up(email:, password:, **_)
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
  user.email = params[:email]
  user.password = params[:password]
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
