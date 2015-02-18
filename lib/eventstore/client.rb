require 'httparty'
require 'json'
require 'cql'
require 'feedjira'
require 'persistent_httparty'

module EventStore
  class Client
    include HTTParty
    persistent_connection_adapter

    def initialize conn_string
      @conn_string = conn_string
      @uuid_gen = Cql::TimeUuid::Generator.new
    end

    def write_event stream, event_type, event_body, uuid=nil
      uuid ||= new_uuid
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
      resume_read stream, 0, read_count
    end

    def resume_read stream, last_event_id, read_count=20
      stream = Stream.new url_for stream
      stream.events_from(last_event_id).take(read_count)
    end

    private
    def url_for stream
      URI.join(@conn_string,'/streams/',stream)
    end
    def new_uuid
      @uuid_gen.next.to_s
    end
  end

  class Util
    def self.poll eventstore, stream, start_at=0, set_size=100, sleep_time=10
      Enumerator.new do |yielder|
        start_at = 0
        last_start_at = nil
        begin
          loop do
            if last_start_at == start_at
              sleep sleep_time
            end
            last_start_at = start_at
            events = eventstore.resume_read(stream, start_at, set_size)
            events.each do |event|
              yielder << event
              start_at = event[:id]
            end
          end
        end
      end
    end
  end

  class Stream
    include HTTParty
    persistent_connection_adapter

    def initialize url
      @page_url = url
      @id_pointer = url
    end
    def events
      event_from 0
    end
    def events_from event_id, direction=:newer
      if event_id.is_a?(Fixnum)
        event_id = "#{@page_url}/#{event_id}"
      end
      if direction == :newer
        @id_pointer = "#{event_id}/forward/20"
      else
        @id_pointer = "#{event_id}/backward/20"
      end
      Enumerator.new do |yielder|
        while @id_pointer
          feed = Feedjira::Feed.parse feed_data_from_pointer
          entries = feed.entries
          if direction == :newer
            entries = entries.reverse
          end
          entries.each do |entry|
            yielder << { body: fetch_event_body(entry.url),
              type: entry.summary,
              updated: entry.updated,
              id: entry.id
            }
          end
          @id_pointer = entries.length == 0 ? nil : feed.send(direction)
        end
      end
    end
    private
    def feed_data
      self.class.get(@page_url).body
    end
    def feed_data_from_pointer
      self.class.get(@id_pointer).body
    end
    def fetch_event_body url
      JSON.load(
        self.class.get(url, {
          headers: { 'Accept' => 'application/json' }}
        ).body
      )
    end
  end
end

module Feedjira
  module Parser
    class Atom
      element :"link", as: :first, value: :href, with: { rel: 'first' }
      element :"link", as: :last, value: :href, with: { rel: 'last' }

      element :"link", as: :newer, value: :href, with: { rel: 'previous' }
      element :"link", as: :older, value: :href, with: { rel: 'next' }
    end
  end
end
