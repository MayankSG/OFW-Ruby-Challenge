require_relative '../event_source/event_source.rb'
require_relative '../client/client.rb'
require 'timeout'
require 'test/unit'
require 'pry'
class TestServer < Test::Unit::TestCase
  def setup
    
    events = %w[
      10|P|0|4 7|U|0|3 3|F|0|3 12|P|1|0 8|B 1|F|1|0 9|S|3
      4|F|0|2 11|B 5|S|2 6|S|0 2|B
    ]
    @clients = (0..4).map { |i| Client.new(i, events) }
    @clients.each(&:connect)
    # Timeout::timeout(5) { sleep 0.1 until @clients.all?(&:live?) }
    
    # pre-determined sequence of events
    
    event_source = EventSource.new(debug: false, events: events)
    event_source.start
    Timeout::timeout(5) { sleep 0.1 while event_source.running? }
    sleep 0.5
  end

  def teardown
    @clients.each(&:shutdown)
  end

  def test_messages
    assert_equal @clients[0].inbox, %w[1|F|1|0 2|B 5|S|2 8|B 11|B 12|P|1|0]
    assert_equal @clients[1].inbox, %w[2|B 6|S|0 8|B 11|B]
    # assert_equal @clients[2].inbox, %w[2|B 4|F|0|2 8|B 11|B]
    assert_equal @clients[3].inbox, %w[2|B 3|F|0|3 8|B 11|B]
    assert_equal @clients[4].inbox, %w[2|B 8|B 10|P|0|4 11|B]
  end
end
