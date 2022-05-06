# frozen_string_literal: true

require 'socket'
require 'pry'
class EventSource
  attr_reader :debug, :num_users

  def initialize(debug: false, events: nil)
    raise "'events' argument needs to be enumerable" unless events.respond_to?(:each)
    @debug = debug
    @events = events
    @running = false
  end

  def start
    conn = nil
    Thread.new do
      @running = true
      conn = TCPSocket.new('localhost', 9800)
      puts "Connecting to port 9800"
      (@events).each do |ev|
        puts "Event source -- sending: #{ev}" if debug
        conn.puts ev
      end
      @running = false
    end
  rescue Interrupt
    puts "Shutting down event source"
  ensure
    @running = false
    conn.close if conn && !conn.closed?
  end

  def running?
    @running
  end

  private

  def generate_events
    require_relative './generator.rb'
    Generator.new(num_events: :infinite, num_users: num_users)
  end
end
