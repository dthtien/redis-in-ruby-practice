# frozen_string_literal: true

require 'socket'
require_relative './commands/get'
require_relative './commands/set'
require_relative './commands/ttl'
require_relative './commands/pttl'
# accept: This is how you connect to existing socket
# socket: This is how we created the server in the previous chapter
class Server
  DEFAULT_PORT = 2020
  COMMANDS = {
    'GET' => Commands::Get,
    'SET' => Commands::Set,
    'TTL' => Commands::Ttl,
    'PTTL' => Commands::Pttl,
  }
  MAX_EXPIRE_LOOKUPS_PER_CYCLE = 20
  DEFAULT_FREQUENCY = 10 # How many times server_cron runs per second

  TimeEvent = Struct.new(:process_at, :block)

  def initialize
    @data_store = {}
    @clients = []
    @time_events = []
    @expires = {}
    @server = TCPServer.new DEFAULT_PORT
  end

  def execute
    add_time_event(Time.now.to_f.truncate + 1) { server_cron }
    start_event_loop
    process_time_events
  end

  private

  def nearest_time_event
    nearest = nil
    @time_events.each do |time_event|
      if nearest.nil?
        nearest = time_event
      elsif time_event.process_at < nearest.process_at
        nearest = time_event
      else
        next
      end
    end

    nearest
  end

  def select_timeout
    return 0 unless @time_events.any?

    nearest = nearest_time_event
    now = (Time.now.to_f * 1000).truncate
    return 0 if nearest.process_at < now

    (nearest.process_at - now) / 1000.0
  end

  def start_event_loop
    loop do
      timeout = select_timeout
      result = IO.select(@clients + [@server], [], [], timeout)
      sockets = result.nil? ? [] : result[0]
      sockets.each do |socket|
        next @clients << @server.accept if socket.is_a? TCPServer
        next execute_client(socket) if socket.is_a? TCPSocket

        raise "Unknown socket type: #{socket}"
      rescue Errno::ECONNRESET
        @clients.delete(socket)
      end
    end
  end

  def process_time_events
    @time_events.delete_if do |time_event|
      next if time_event.process_at > Time.now.to_f * 1000

      return_value = time_event.block.call
      if return_value.nil?
        true
      else
        time_event.process_at = (Time.now.to_f * 1000).truncate + return_value
        false
      end
    end
  end

  def add_time_event(process_at, &block)
    @time_events << TimeEvent.new(process_at, block)
  end

  def execute_client(client)
    client_command_with_args = client.read_nonblock(1024, exception: false)

    if client_command_with_args.nil?
      puts 'Found a client at eofm closing and removing'
      @clients.delete(client)
    elsif client_command_with_args == :wait_readable
      # There are nothing to read from the client
    elsif client_command_with_args.strip.empty?
      puts "Empty request received from #{client}"
    else
      commands = client_command_with_args.strip.split("\n")
      commands.each do |command|
        response = handle_client_command(command.strip)
        p client
        client.puts response
      end
    end
  end

  def handle_client_command(client_command_with_args)
    command_parts = client_command_with_args.split
    command = command_parts[0]
    args = command_parts[1..-1]
    execute_command(command, args)
  end

  def execute_command(command, args)
    p command
    p args
    command_class = COMMANDS[command]
    if command_class.to_s.empty?
      formatted_args = args.map { |arg| "`#{ arg }`," }.join(' ')
      "(error) ERR unknown command `#{ command }`, with args beginning with: #{ formatted_args }"
    else
      cmd = command_class.new(@data_store, @expires, args)
      cmd.call
    end
  end

  def server_cron
    keys_fetched = 0

    @expires.each do |key, _|
      if @expires[key] < Time.now.to_f * 1000
        @logger.debug "Evicting #{ key }"
        @expires.delete(key)
        @data_store.delete(key)
      end

      keys_fetched += 1
      break if keys_fetched >= MAX_EXPIRE_LOOKUPS_PER_CYCLE
    end

    1000 / DEFAULT_FREQUENCY
  end
end
