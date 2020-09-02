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
    socket = TCPSocket.new DEFAULT_HOST, Server::DEFAULT_PORT
    socket.puts "SET #{key} #{value}"
    result = socket.gets
    socket.close
    result
  end

  def two_full_gets(key)
    t0 = Time.now
    get(key)
    get(key)
    puts "Time elapsed: #{(Time.now - t0) * 1000}ms"
  end

  def two_gets_a_single_connection(key)
    t0 = Time.now
    socket = TCPSocket.new DEFAULT_HOST, Server::DEFAULT_PORT
    socket.puts "GET #{key}"
    socket.puts "GET #{key}"
    result = socket.gets
    socket.close
    puts "Time elapsed: #{(Time.now - t0) * 1000}ms"
    result
  end
end
