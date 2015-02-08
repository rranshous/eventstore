require 'httparty'
require 'json'
require 'cql'
require 'feedjira'
require 'persistent_httparty'

class Client
  def initialize conn_string
    @conn_string = conn_string
    @uuid_gen = Cql::TimeUuid::Generator.new
  end

  def write_event stream, event_type, event_body
    uuid = new_uuid
    json_body = event_body.to_json
    response = self.class.post url_for(stream), {
      body: json_body,
      headers: {
        'Content-Type' => 'application/json',
        'ES-EventId' => uuid,
        'ES-EventType' => event_type,
        'ES-ResolveLinkTo' => 'true'
      },
      no_follow: true
    }
    [uuid, response]
  end

  def read_events stream, read_count=20
    stream = Stream.new url_for stream
    stream.events.take(read_count)
  end

  private
  def url_for stream
    URI.join(@conn_string,'/streams/',stream)
  end
  def new_uuid
    @uuid_gen.next.to_s
  end
end

class Stream
  include HTTParty
  persistent_connection_adapter

  def initialize url
    @page_url = url
  end
  def events
    Enumerator.new do |yielder|
      while @page_url
        feed = Feedjira::Feed.parse feed_data
        feed.entries.each do |entry|
          yielder << { body: fetch_event_body(entry.url),
            type: entry.summary,
            updated: entry.updated
          }
        end
        @page_url = feed.next_href
      end
      puts "STOPPING"
    end
  end
  private
  def feed_data
    self.class.get(@page_url).body
  end
  def fetch_event_body url
    JSON.load(
      self.class.get(url, {
        headers: { 'Accept' => 'application/json' }}
      ).body
    )
  end
end


module Feedjira
  module Parser
    class Atom
      element :"link", as: :next_href, value: :href, with: { rel: 'next' }
      element :"link", as: :first_href, value: :href, with: { rel: 'first' }
      element :"link", as: :last_href, value: :href, with: { rel: 'last' }
    end
  end
end
