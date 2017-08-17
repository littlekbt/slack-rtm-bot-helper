module Slack
  module Rtm
    module Bot
      class Helper
        class NotEnoughArgumentsError < StandardError; end
        SLACK_URL = 'https://slack.com'
        RTM_PATH  = '/api/rtm.start'

        attr_accessor :channel, :message_block, :id, :wss

        def initialize(token, channel, message_block)
          @token         = token
          @channel       = channel
          @message_block = message_block

          @id  = 1
          @wss = nil
        end

        def self.run(token=nil, channel=nil, &message_block)
          raise NotEnoughArgumentsError if token.nil? || message_block.nil?

          s = new(token, channel, message_block)
          s.connect

          loop do
            sleep 5
            unless s.wss.open?
              s.connect
            end
          end 
        end

        def connect
          conn = ::Faraday.new(SLACK_URL) do |faraday|
            faraday.request  :url_encoded
            faraday.adapter  ::Faraday.default_adapter
          end

          res = conn.post RTM_PATH, token: @token
          url = ::JSON.parse(res.body).to_h['url']

          return if url.nil?

          @wss = ::WebSocket::Client::Simple.connect url
          @wss.on :message, &(base_block(self))
        end

        private
          def base_block(helper)
            Proc.new do |msg|
              data = ::JSON.parse(msg.data)
              close if data.empty?

              helper.channel ||= data['channel']
              msg = helper.message_block.call(data) if !data['text'].empty?

              if !msg.nil? && !msg.empty?
                msg_json = {
                   id:      helper.id,
                   type:    'message',
                   channel: helper.channel,
                   text:    msg
                }.to_json

                send(msg_json) && helper.id += 1
              end
            end
          end
      end
    end
  end
end
