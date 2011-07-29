require 'uri'

module Kirk
  class Client
    class Group
      attr_reader :client, :host, :options, :responses

      def initialize(client = Client.new, options = {})
        @options = options
        @client  = client
        @queue   = LinkedBlockingQueue.new

        @requests_count = 0
        @responses      = []
        @in_progress    = []

        if @options[:host]
          @host = @options.delete(:host).chomp('/')
          @host = "http://#{@host}" unless @host =~ /^https?:\/\//
        end
      end

      def block?
        options.key?(:block) ? options[:block] : true
      end

      def start
        ret = yield self
        join if block?
        ret
      end

      def join
        get_responses
      end

      def complete(&blk)
        @complete = blk if blk
        @complete
      end

      def request(method = nil, url = nil, handler = nil, body = nil, headers = {})
        request = Request.new(self, method, url, handler, body, headers)

        yield request if block_given?

        request.url URI.join(host, request.url).to_s if host
        request.validate!

        process(request)
        request
      end

      def respond(exchange, response)
        @queue.put([exchange, response])
      end

      %w/get post put delete head/.each do |method|
        class_eval <<-RUBY
          def #{method}(url, handler = nil, body = nil, headers = {})
            request(:#{method.upcase}, url, handler, body, headers)
          end
        RUBY
      end

      def process(request)
        exchange = Exchange.build(request)

        @in_progress << exchange
        @client.process(exchange)

        @requests_count += 1
      end

      def get_responses
        while @requests_count > 0
          exchange, resp = @queue.poll(timeout, TimeUnit::SECONDS)

          if resp
            @responses      << resp
            @requests_count -= 1
          else
            @in_progress.each do |ex|
              ex.cancel
            end

            @in_progress.each do |ex|
              ex.wait_for_done
            end

            raise TimeoutError, "timed out"
          end
        end

        completed
      end

      def completed
        complete.call if complete
      end

      def timeout
        @options[:timeout] || 30
      end
    end
  end
end
