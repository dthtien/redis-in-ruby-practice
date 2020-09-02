# frozen_string_literal: true

require 'socket'
require_relative 'server'

class Client
  DEFAULT_HOST = 'localhost'.freeze

  def get(key)
    socket = TCPSocket.new DEFAULT_HOST, Server::DEFAULT_PORT
    socket.puts "GET #{key}"
    result = socket.gets
    socket.close
    result
  end

  def set(key, value)
    socket = TCPSocket.new 'localhost', Server::DEFAULT_PORT
    socket.puts "SET #{key} #{value}"
    result = socket.gets
    socket.close
    result
  end
end
