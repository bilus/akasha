require 'uri'

def http_es_config
  defaults = {
    host: 'localhost',
    port: 2113,
    username: 'admin',
    password: 'changeit'
  }
  url = ENV['EVENTSTORE_URL']
  return defaults if url.nil?
  url = URI.parse(url)
  {
    host: url.host,
    port: url.port || defaults[:port],
    username: url.user,
    password: url.password
  }
end

def http_event_store_client
  Akasha::Storage::HttpEventStore::Client.new(http_es_config)
end
