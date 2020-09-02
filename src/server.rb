# frozen_string_literal: true

require 'socket'
# accept: This is how you connect to existing socket
# socket: This is how we created the server in the previous chapter

class Server
  DEFAULT_PORT = 2020
  COMMANDS = [SET = 'SET', GET = 'GET'].freeze

  def initialize
    @data_store = {}
  end

  def execute
    server = TCPServer.new DEFAULT_PORT
    puts "Server start at #{Time.now}"
    loop do
      client = server.accept
      puts "New client connect at: #{client}"
      client_command_with_args = client.gets

      if client_command_with_args &&
         !client_command_with_args.strip.empty?
        response = handle_client_command(client_command_with_args)
        client.puts response
      else
        puts "Empty request received from #{client}"
      end

      client.close
    end
  end

  private

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
