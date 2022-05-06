# frozen_string_literal: true

require 'socket'
require 'pry'

class Client
  attr_reader :debug, :inbox, :user_id

  def initialize(user_id = nil, debug: false)
    raise ArgumentError, "invalid user_id #{user_id}. It needs to be a non-negative integer" if user_id.to_i < 0
    @user_id = user_id.to_i || rand(100)
    @inbox = []
    @live = false
    @debug = debug
  end

  def connect
    @thread = Thread.new do
      user_server = TCPSocket.new('localhost', 9801)
      user_server.puts(user_id)
      @live = true
      
      while (msg = user_server.gets)
        puts "##{user_id}: received #{msg.inspect}" if debug
        @inbox << msg.chomp if msg
      end
    rescue Interrupt
      @live = false
      user_server.close if user_server && !user_server.closed?
    end
  end

  def live?
    @live
  end

  def shutdown
    @thread.raise Interrupt
    @thread.join
  end
end
