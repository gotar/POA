# frozen_string_literal: true

require "test_helper"
require "json"

class PiRpcServiceTest < ActiveSupport::TestCase
  setup do
    @service = PiRpcService.new
  end

  teardown do
    @service&.stop
  end

  # Initialization
  test "should initialize with nil pid" do
    assert_nil @service.pid
  end

  test "should not be running initially" do
    assert_not @service.running?
  end

  # Start/Stop (integration test - requires pi installed)
  # These tests are marked as skip if pi is not available
  test "start should spawn pi process" do
    skip "Requires pi to be installed and configured" unless pi_available?

    @service.start

    assert @service.running?
    assert_not_nil @service.pid
    assert @service.pid > 0
  end

  test "stop should terminate the process" do
    skip "Requires pi to be installed and configured" unless pi_available?

    @service.start
    assert @service.running?

    @service.stop

    assert_not @service.running?
    assert_nil @service.pid
  end

  test "should be idempotent on multiple starts" do
    skip "Requires pi to be installed and configured" unless pi_available?

    @service.start
    pid = @service.pid

    @service.start # Second call

    assert_equal pid, @service.pid # Same process
  end

  test "should be idempotent on multiple stops" do
    @service.stop
    @service.stop # Should not raise

    assert_not @service.running?
  end

  # Error handling
  test "should raise ProcessError when sending command without running process" do
    assert_raises(PiRpcService::ProcessError) do
      @service.send(:send_command, { type: "test" })
    end
  end

  # Mock tests for response handling
  test "read_response should parse JSON response" do
    # Mock stdout with a JSON response
    mock_stdout = StringIO.new('{"type":"response","success":true}' + "\n")
    @service.instance_variable_set(:@stdout, mock_stdout)

    result = @service.send(:read_response)

    assert_equal "response", result["type"]
    assert_equal true, result["success"]
  end

  test "read_response should return nil for empty line" do
    mock_stdout = StringIO.new("\n")
    @service.instance_variable_set(:@stdout, mock_stdout)

    result = @service.send(:read_response)

    assert_nil result
  end

  test "read_response should raise TimeoutError on timeout" do
    # Mock stdout that never returns
    mock_stdout = StringIO.new
    mock_stdout.define_singleton_method(:gets) { sleep(10) }
    @service.instance_variable_set(:@stdout, mock_stdout)

    # Temporarily reduce timeout
    PiRpcService.const_set(:RPC_TIMEOUT, 0.1)

    assert_raises(PiRpcService::TimeoutError) do
      @service.send(:read_response)
    end
  ensure
    PiRpcService.const_set(:RPC_TIMEOUT, 300)
  end

  private

  def pi_available?
    system("which pi > /dev/null 2>&1") &&
      ENV["ANTHROPIC_API_KEY"].present? || ENV["OPENAI_API_KEY"].present?
  end
end
