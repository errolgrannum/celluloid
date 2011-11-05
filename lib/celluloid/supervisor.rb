module Celluloid
  # Supervisors are actors that watch over other actors and restart them if
  # they crash
  class Supervisor
    include Celluloid
    trap_exit :restart_actor

    # Retrieve the actor this supervisor is supervising
    attr_reader :actor

    def self.supervise(klass, *args, &block)
      new(nil, klass, *args, &block)
    end

    def self.supervise_as(name, klass, *args, &block)
      new(name, klass, *args, &block)
    end

    def initialize(name, klass, *args, &block)
      @name, @klass, @args, @block = name, klass, args, block
      start_actor
    end

    def start_actor(start_attempts = 2, sleep_interval = 30)
      failures = 0

      begin
        @actor = @klass.new_link(*@args, &@block)
      rescue
        failures += 1
        if failures >= start_attempts
          failures = 0
          Celluloid.logger.warn "#{@klass} is crashing on initialize repeatedly, sleeping for #{sleep_interval} seconds"
          sleep sleep_interval
        end
        retry
      end

      Celluloid::Actor[@name] = @actor if @name
    end

    # When actors die, regardless of the reason, restart them
    def restart_actor(actor, reason)
      start_actor
    end

    def inspect
      str = "#<Celluloid::Supervisor(#{@klass}):0x#{object_id.to_s(16)}"
      str << " " << @args.map { |arg| arg.inspect }.join(' ') unless @args.empty?
      str << ">"
    end
  end
end
