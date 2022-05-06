# frozen_string_literal: true

require_relative '../event_source/event_source.rb'
require_relative '../event_source/generator.rb'
require_relative '../client/client.rb'
require 'timeout'


num_clients = 100
num_messages = 50000

clients = (0..num_clients-1).map { |i| Client.new(i) }
clients.each(&:connect)
Timeout::timeout(5) { sleep 0.1 until clients.all?(&:live?) }

generator = Generator.new(num_events: num_messages, num_users: num_clients, mode: :sequential)
event_source = EventSource.new(debug: false, events: generator)

start_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
event_source.start

Timeout::timeout(180) do
  client = clients[0]
  while client.inbox.last != "#{num_messages}|B"
    print '.'
    sleep 0.1
  end
end

end_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
puts "Measured time: #{end_at - start_at}"
