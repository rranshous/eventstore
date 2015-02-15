EventStore::Client
==================

    client = EventStore.client('http://0.0.0.0:2113')
    client.write_event('stream-name', 'event-type', { 'event' => 'data' })
    events_to_read = 20
    events = client.read_events('stream-name', events_to_read)
    last_event_id = events.last[:id]
    events = client.resume_read('stream-name', last_event_id, events_to_read)
    events[:id]
    events[:type]
    events[:body]
    events[:updated]
