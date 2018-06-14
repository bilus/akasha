require 'akasha'
require 'sinatra'

# An example aggregate.
class User < Akasha::Aggregate
  attr_reader :email

  def sign_up(email:, password:, admin: false, **)
    changeset.append(:user_signed_up, email: email, password: password, admin: admin)
  end

  def on_user_signed_up(email:, password:, admin:, **)
    @email = email
    @password = password
    @admin = admin
  end
end

# An example materializer.
class UserListMaterializer < Akasha::EventListener
  def on_user_signed_up(user_id, **)
    # Update database.
  end
end

# An example event listener; will be used asynchronously.
class Notifier < Akasha::EventListener
  def on_user_signed_up(user_id, **)
    notify_about_signup(user_id)
  end

  private

  def notify_about_signup(user_id)
    # Here we could just grab email from the event but let's demonstrate
    # how to load an aggregate from events.
    user = User.find_or_create(user_id)
    email = <<~EMAIL
      User #{user.email} just signed up!
    EMAIL
    # Let's not send any emails... :)
    puts email
  end
end

before do
  @command_router = Akasha::CommandRouter.new

  # Aggregates will load from and save to in-memory storage.
  repository = Akasha::Repository.new(Akasha::Storage::MemoryEventStore.new)
  Akasha::Aggregate.connect!(repository)

  # Set up event listeners.
  event_router = Akasha::EventRouter.new
  event_router.register_event_listener(:user_signed_up, UserListMaterializer)
  event_router.connect!(repository)

  async_event_router = Akasha::AsyncEventRouter.new
  async_event_router.register_event_listener(:user_signed_up, Notifier)
  async_event_router.connect!(repository) # Returns Thread instance.

  # This is how you link commands to aggregates.
  @command_router.register_default_route(:sign_up, User)

  # Nearly identital to the default handling above but we're setting the admin
  # flag to demo custom command handling.
  @command_router.register_route(:sign_up_admin) do |aggregate_id, **data|
    user = User.find_or_create(aggregate_id)
    user.sign_up(email: data[:email], password: data[:password], admin: true)
    user.save!
  end
end

post '/users/:user_id' do # With CQRS client pass unique aggregate ids.
  @command_router.route!(:sign_up,
                         params[:user_id],
                         email: params[:email],
                         password: params[:password])
  'OK'
end
