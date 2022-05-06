# frozen_string_literal: true

class Generator
  EV_TYPES = %i[FOLLOW UNFOLLOW BROADCAST PRIV_MSG STATUS_UPDATE].freeze

  include Enumerable

  attr_reader :user_ids

  def initialize(num_events:, num_users:, mode: :batched, batch_size: 1000)
    validate_input(num_events, num_users)
    @num_events = num_events == :infinite ? Float::INFINITY : num_events.to_i
    @user_ids = (1..num_users).to_a
    @mode = mode
    @sequence =
    case mode
    when :batched
      (1..num_events).step(batch_size).lazy.flat_map do |x|
        (x..x+batch_size-1).to_a.shuffle
      end
    when :sequential
      (1..num_events).lazy
    when :inverted
      raise ArgumentError, "num_events: :infinite not allowed in :inverted mode" if num_events == :infinite
      num_events.downto(1).lazy
    end
  end

  def each(&block)
    while ev = next_value
      yield ev
    end

    # end with a broadcast so we're able to know from client side when it's done
    if @mode == :inverted
      yield '0|B'
    elsif @num_events != Float::INFINITY
      yield "#{@num_events}|B"
    end
  end

  def next_value
    begin
      seq = @sequence.next
    rescue StopIteration
      return nil
    end
    ev_type = EV_TYPES.sample
    case ev_type
    when :BROADCAST
      "#{seq}|B"
    when :FOLLOW
      follower_id, followed_id = user_ids.sample(2)
      "#{seq}|F|#{follower_id}|#{followed_id}"
    when :UNFOLLOW
      follower_id, followed_id = user_ids.sample(2)
      "#{seq}|U|#{follower_id}|#{followed_id}"
    when :PRIV_MSG
      sender_id, recipient_id = user_ids.sample(2)
      "#{seq}|P|#{sender_id}|#{recipient_id}"
    when :STATUS_UPDATE
      user_id = user_ids.sample
      "#{seq}|S|#{user_id}"
    else
      raise "Invalid event type #{ev_type}"
    end
  end

  private

  def validate_input(num_events, num_users)
    raise "Number of users needs to be positive integers" unless num_users.to_i > 1
    raise "Number of events needs to be either a positive integers or the symbol :infinite" if num_events != :infinite && num_events.to_i <= 0
  end
end
