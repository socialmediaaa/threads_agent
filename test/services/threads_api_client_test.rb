require "test_helper"

class ThreadsApiClientTest < ActiveSupport::TestCase
  class FakeHTTP
    attr_reader :last_request, :responses

    def initialize
      @responses = {}
      @last_request = nil
    end

    def stub(method, path, response)
      @responses[[ method, path ]] = response
    end

    def request(method, path, body: {}, headers: {})
      @last_request = { method: method, path: path, body: body, headers: headers }
      response = @responses[[ method, path ]]
      raise "No stub for #{method} #{path}" unless response

      FakeResponse.new(response[:status], response[:body])
    end

    class FakeResponse
      attr_reader :code, :body

      def initialize(code, body)
        @code = code
        @body = body.is_a?(Hash) ? body.to_json : body
      end

      def code
        @code.to_s
      end
    end
  end

  setup do
    @fake_http = FakeHTTP.new
    @client = ThreadsApi::Client.new(access_token: "test_token", http: @fake_http)
  end

  test "create_text_container returns container_id" do
    @fake_http.stub(:post, "/me/threads", { status: 200, body: { id: "container_123" } })

    result = @client.create_text_container("Hello world")
    assert_equal "container_123", result[:id]
    assert_equal "Hello world", @fake_http.last_request[:body][:text]
    assert_equal "TEXT", @fake_http.last_request[:body][:media_type]
  end

  test "create_image_container returns container_id" do
    @fake_http.stub(:post, "/me/threads", { status: 200, body: { id: "container_456" } })

    result = @client.create_image_container("https://example.com/img.jpg", "Caption")
    assert_equal "container_456", result[:id]
    assert_equal "IMAGE", @fake_http.last_request[:body][:media_type]
    assert_equal "https://example.com/img.jpg", @fake_http.last_request[:body][:image_url]
    assert_equal "Caption", @fake_http.last_request[:body][:caption]
  end

  test "publish_container returns post_id" do
    @fake_http.stub(:post, "/me/threads_publish", { status: 200, body: { id: "post_789" } })

    result = @client.publish_container("container_123")
    assert_equal "post_789", result[:id]
    assert_equal "container_123", @fake_http.last_request[:body][:creation_id]
  end

  test "publish_text_post creates container then publishes" do
    @fake_http.stub(:post, "/me/threads", { status: 200, body: { id: "container_123" } })
    @fake_http.stub(:post, "/me/threads_publish", { status: 200, body: { id: "post_789" } })

    result = @client.publish_text_post("Hello world")
    assert_equal "post_789", result[:id]
  end

  test "handles rate limit error" do
    @fake_http.stub(:post, "/me/threads", { status: 429, body: { error: { message: "Rate limit exceeded" } } })

    assert_raises ThreadsApi::RateLimitError do
      @client.create_text_container("Test")
    end
  end

  test "handles auth error" do
    @fake_http.stub(:post, "/me/threads", { status: 401, body: { error: { message: "Invalid token" } } })

    assert_raises ThreadsApi::AuthError do
      @client.create_text_container("Test")
    end
  end
end
