require "net/http"
require "json"
require "uri"

module ThreadsApi
  class Error < StandardError; end
  class AuthError < Error; end
  class RateLimitError < Error; end
  class ServerError < Error; end
  class NotFoundError < Error; end

  class Client
    BASE_URL = "https://graph.threads.net/v1.0".freeze

    attr_reader :access_token, :http

    def initialize(access_token:, http: nil)
      @access_token = access_token
      @http = http || RealHTTP.new
    end

    def create_text_container(text)
      create_container(media_type: "TEXT", text: text)
    end

    def create_image_container(image_url, caption = nil)
      params = { media_type: "IMAGE", image_url: image_url }
      params[:caption] = caption if caption.present?
      create_container(**params)
    end

    def publish_container(creation_id)
      request(:post, "/me/threads_publish", creation_id: creation_id)
    end

    def publish_text_post(text)
      container = create_text_container(text)
      publish_container(container[:id])
    end

    private

    def create_container(media_type:, **params)
      body = { media_type: media_type }.merge(params)
      request(:post, "/me/threads", body)
    end

    def request(method, path, body = {})
      uri = URI.join(BASE_URL, path)
      req = build_request(uri, method, body)
      response = @http.request(method, path, body: body, headers: req.to_hash)
      handle_response(response)
    end

    def build_request(uri, method, body)
      req = Net::HTTP.const_get(method.to_s.capitalize).new(uri)
      req["Authorization"] = "Bearer #{access_token}"
      req["Content-Type"] = "application/json"
      req.body = body.to_json
      req
    end

    def handle_response(response)
      case response.code.to_i
      when 200, 201
        JSON.parse(response.body, symbolize_names: true)
      when 401
        raise AuthError, parse_error(response)
      when 429
        raise RateLimitError, parse_error(response)
      when 404
        raise NotFoundError, parse_error(response)
      when 500..599
        raise ServerError, parse_error(response)
      else
        raise Error, parse_error(response)
      end
    end

    def parse_error(response)
      JSON.parse(response.body, symbolize_names: true).dig(:error, :message) || response.body
    rescue JSON::ParserError
      response.body
    end

    class RealHTTP
      def request(method, path, body:, headers:)
        uri = URI.join(BASE_URL, path)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request_klass = Net::HTTP.const_get(method.to_s.capitalize)
        req = request_klass.new(uri)
        headers.each { |k, v| req[k] = v }
        req.body = body.to_json if body.is_a?(Hash)

        response = http.request(req)
        RealResponse.new(response)
      end

      class RealResponse
        attr_reader :code, :body

        def initialize(net_response)
          @code = net_response.code
          @body = net_response.body
        end
      end
    end
  end
end
