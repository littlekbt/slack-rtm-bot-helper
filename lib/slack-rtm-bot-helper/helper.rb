module Slack
  module Rtm
    module Bot
      class Helper
        class NotEnoughArgumentsError < StandardError; end
        SLACK_URL   = 'https://slack.com'
        RTM_PATH    = '/api/rtm.start'
        USERS_PATH  = '/api/users.list'

        attr_accessor :channel, :message_block, :id, :me, :wss

        def initialize(token, channel, name, message_block)
          @token         = token
          @channel       = channel
          @message_block = message_block
          @me            = me_id(token, name) unless name.nil?

          @id  = 1
          @wss = nil
        end

        def self.run(token:nil, channel:nil, name: nil, &message_block)
          raise NotEnoughArgumentsError if token.nil? || message_block.nil?

          s = new(token, channel, name, message_block)
          s.connect

          loop do
            sleep 2
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

        def to_me?(text)
          text.match?(/^<@#{@me}/)
        end

        private

        def me_id(token, name)
          conn = ::Faraday.new(SLACK_URL) do |faraday|
            faraday.request  :url_encoded
            faraday.adapter  ::Faraday.default_adapter
          end

          res = conn.post USERS_PATH, token: @token
          (::JSON.parse(res.body)['members'].select { |m| m['name'] == name }.first)&.fetch('id')
        end

        def base_block(helper)
          Proc.new do |msg|
            data = ::JSON.parse(msg.data)
            close if data.empty?

            msg = if !data['text'].empty?
                    if helper.me.nil?
                      helper.message_block.call(data) 
                    else
                      helper.message_block.call(data) if helper.to_me?(data['text'])
                    end
                  end

            if !(msg.nil? || msg.empty?)
              target_ch = helper.channel || data['channel']
              msg_json = {
                 id:      helper.id,
                 type:    'message',
                 channel: target_ch,
                 text:    msg.to_s
              }.to_json

              send(msg_json) && helper.id += 1
            end
          end
        end
      end
    end
  end
end
