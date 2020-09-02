require_relative '../src/client.rb'

module Helpers
  def connect_to_server
    socket = nil
    # The server might not be ready to listen to accepting connections by the time we try to connect from the main
    # thread, in the parent process. Using timeout here guarantees that we won't wait more than 1s, which should
    # more than enough time for the server to start, and the retry loop inside, will retry to connect every 10ms
    # until it succeeds
    Timeout::timeout(1) do
      loop do
        begin
          socket = TCPSocket.new Client::DEFAULT_HOST, Server::DEFAULT_PORT
          break
        rescue
          sleep 0.01
        end
      end
    end
    socket
  end

  def with_server
    child = Process.fork do
      # We're effectively silencing the server with these two lines
      # stderr would have logged something when it receives SIGINT, with a complete stacktrace
      $stderr = StringIO.new
      # stdout would have logged the "Server started ..." & "New client connected ..." lines
      $stdout = StringIO.new
      Server.new.execute
    end

    yield

  ensure
    if child
      Process.kill('INT', child)
      Process.wait(child)
    end
  end

  def assert_command_results(command_result_pairs)
    with_server do
      command_result_pairs.each do |command, expected_result|
        begin
          socket = connect_to_server
          socket.puts command
          response = socket.gets
          assert_equal response, expected_result + "\n"
        ensure
          socket.close if socket
        end
      end
    end
  end
end
