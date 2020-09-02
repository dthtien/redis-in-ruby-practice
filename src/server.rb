# frozen_string_literal: true

require 'socket'
# accept: This is how you connect to existing socket
# socket: This is how we created the server in the previous chapter
class Server
  DEFAULT_PORT = 2020
  COMMANDS = [SET = 'SET', GET = 'GET'].freeze

  def initialize
    @data_store = {}
    @clients = []
  end

  def execute
    server = TCPServer.new DEFAULT_PORT
    puts "Server start at #{Time.now}"
    loop do
      result = IO.select(@clients + [server])
      result[0].each do |socket|
        next @clients << server.accept if socket.is_a? TCPServer
        next execute_client(socket) if socket.is_a? TCPSocket

        raise "Unknown socket type: #{socket}"
      end
    end
  end

  private

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
      response = handle_client_command(client_command_with_args)
      client.puts response
    end
  end

  def handle_client_command(client_command_with_args)
    command_parts = client_command_with_args.split
    command = command_parts[0]
    args = command_parts[1..-1]
    execute_command(command, args)
  end

  def execute_command(command, args)
    case command
    when GET
      process_get(args)
    when SET
      process_set(args)
    else
      formatted_args = args.map { |arg| "`#{arg}`," }.join(' ')
      "(error) ERR unknown command `#{command}`, with args beginning with: #{formatted_args}"
    end
  end

  def process_get(args)
    if args.length != 1
      "(error) ERR wrong number of arguments for '#{command}' command"
    else
      @data_store.fetch(args[0], '(nil)')
    end
  end

  def process_set(args)
    if args.length != 2
      "(error) ERR wrong number of arguments for '#{command}' command"
    else
      @data_store[args[0]] = args[1]
      'OK'
    end
  end
end
