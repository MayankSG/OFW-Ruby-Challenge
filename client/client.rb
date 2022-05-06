# frozen_string_literal: true

require 'socket'
require 'pry'

class Client
  attr_reader :debug, :inbox, :user_id

  def initialize(user_id = nil, events = nil, debug: false)
    raise ArgumentError, "invalid user_id #{user_id}. It needs to be a non-negative integer" if user_id.to_i < 0
    @user_id = user_id.to_i || rand(100)
    @inbox = []
    @live = false
    @events = events
    @debug = debug
    @status = []
    @inbox = rule_to_calculate
  end

  def connect
    @thread = Thread.new do
      user_server = TCPSocket.new('localhost', 9801)
      user_server.puts(user_id)
      @live = true
      user_server.puts "Enter input===="
  
      # @inbox=["1|F|1|0", "2|B", "5|S|2", "8|B", "11|B", "12|P|1|0"]

      # while (msg = user_server.gets)
      #   puts "##{user_id}: received #{msg.inspect}" if debug
      #   @inbox << msg.chomp if msg
      # end
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

  def rule_to_calculate
    inbox = []
    indx = nil
    (1..@events.size).each do |seq|
      @events.each do |event|
        if (event.split("|").first.to_i == seq)
          inbox<< event if (event.split("|")[1] =="F" || event.split("|")[1] == "P") && user_id == event.split("|").last.to_i
          inbox<< event if (event.split("|")[1] =="B")
          if (event.split("|")[1] =="S")
            get_update_status(event)
            inbox<< event if check_update_status(inbox)
          end
        end
      end
    end
    
    inbox.each_with_index do |inbx, index|
      if (inbx.split("|")[1] =="S")
        indx = index
        inbox[index] = @status.values_at(user_id).first
      end
    end

    inbox.compact
  end

  
  
  def get_update_status(event)
    @status<< event
  end

  def check_update_status(inbox_status)
    status = true
    inbox_status.each do |inbx|
      if inbx.include?("S")
        status = false
      end
    end
    status
  end

end
