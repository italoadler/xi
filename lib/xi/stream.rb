require 'set'

module Xi
  class Stream
    attr_reader :clock, :source, :source_patterns, :state, :event_duration, :gate

    def initialize(clock)
      @mutex = Mutex.new
      @playing = false
      @state = {}
      @new_sound_object_id = 0
      @changed_params = [].to_set
      @playing_sound_objects = {}

      self.clock = clock
    end

    def set(event_duration: nil, gate: nil, **source)
      @mutex.synchronize do
        @source = source
        @gate = gate if gate
        @event_duration = event_duration if event_duration
        update_internal_structures
      end
      play
      self
    end
    alias_method :<<, :set

    def event_duration=(new_value)
      @mutex.synchronize do
        @event_duration = new_value
        update_internal_structures
      end
    end

    def gate=(new_value)
      @mutex.synchronize do
        @gate = new_value
        update_internal_structures
      end
    end

    def clock=(new_clock)
      @clock.unsubscribe(self) if @clock
      new_clock.subscribe(self) if playing?
      @clock = new_clock
    end

    def playing?
      @mutex.synchronize { @playing }
    end

    def stopped?
      !playing?
    end

    def play
      @mutex.synchronize do
        @playing = true
        @clock.subscribe(self)
      end
      self
    end
    alias_method :start, :play

    def stop
      @mutex.synchronize do
        @playing = false
        @state.clear
        @clock.unsubscribe(self)
      end
      self
    end
    alias_method :pause, :play

    def inspect
      "#<#{self.class.name}:#{"0x%014x" % object_id} clock=#{@clock.inspect} #{playing? ? :playing : :stopped}>"
    rescue => err
      logger.error(err)
    end

    def notify(now)
      return unless playing? && @source

      @mutex.synchronize do
        @changed_params.clear

        forward_enums(now) if @must_forward

        gate_on, gate_off = play_enums(now)

        do_gate_off_change(gate_off) unless gate_off.empty?
        do_gate_on_change(gate_on) unless gate_on.empty?
        do_state_change if state_changed?
      end
    end

    private

    def changed_state
      @state.select { |k, _| @changed_params.include?(k) }
    end

    def forward_enums(now)
      @enums.each do |p, (enum, total_dur)|
        cur_pos = now % total_dur
        next_ev = enum.peek

        while distance = (cur_pos - next_ev.start) % total_dur do
          enum.next

          break if distance <= next_ev.duration
          next_ev = enum.peek
        end
      end
      @must_forward = false
    end

    def play_enums(now)
      gate_off = []
      gate_on = []

      @enums.each do |p, (enum, total_dur)|
        start_ts = @base_ts - (@base_ts % total_dur)
        cur_pos = now - start_ts

        next_ev = enum.peek

        # Check if there are any currently playing sound objects that
        # must be gated off
        @playing_sound_objects.dup.each do |end_pos, h|
          if cur_pos >= end_pos - latency_sec
            gate_off << {so_ids: h[:so_ids],
                         at: @clock.at(start_ts + end_pos)}
            @playing_sound_objects.delete(end_pos)
          end
        end

        # Do we need to play next event now? If not, skip this parameter
        if cur_pos >= next_ev.start - latency_sec
          # Update state based on pattern value
          # TODO: Pass as parameter exact time (start_ts + next_ev.start)
          update_state(p, next_ev.value)

          # If this parameter is a gate, mark it as gate on as
          # a new sound object
          if p == @gate
            new_so_ids = Array(next_ev.value).size.times.map do
              so_id = @new_sound_object_id
              @new_sound_object_id += 1
              so_id
            end
            gate_on << {so_ids: new_so_ids,
                        at: @clock.at(start_ts + next_ev.start)}
            @playing_sound_objects[next_ev.end] = {so_ids: new_so_ids,
                                                   duration: total_dur}
          end

          # Because we already processed event, advance enumerator
          enum.next
        end
      end

      [gate_on, gate_off]
    end

    def update_internal_structures
      # Replace absolute offsets for relative offsets because enums are going
      # to be reset.
      @playing_sound_objects = @playing_sound_objects
        .map { |end_pos, h| [end_pos % h[:duration], h] }.to_h

      @base_ts = @clock.now
      @must_forward = true
      @enums = @source.map { |k, v|
        pat = v.p(@event_duration)
        [k, [pat.seq(inf).each_event, pat.total_duration]]
      }.to_h
    end

    def do_gate_on_change(ss)
      logger.info "Gate on change: #{ss}"
    end

    def do_gate_off_change(ss)
      logger.info "Gate off change: #{ss}"
    end

    def do_state_change
      logger.info "State change: #{@state.select { |k, v| @changed_params.include?(k) }.to_h}"
    end

    def update_state(p, v)
      if v != @state[p]
        logger.debug "Update state of :#{p}: #{v}"
        @changed_params << p
        @state[p] = v
      end
    end

    def state_changed?
      !@changed_params.empty?
    end

    def latency_sec
      0.05
    end

    def logger
      # FIXME this should be configurable
      @logger ||= Logger.new("/tmp/xi.log")
    end
  end
end
