# Slack::Rtm::Bot::Helper

This gem help develop slack bot using Real Time Message API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'slack-rtm-bot-helper'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install slack-rtm-bot-helper

## Usage

```rb
require 'slack-rtm-bot-helper'

Slack::Rtm::Bot::Helper.run(token: '<your slack token>', channel: '<channel name>', name: '<bot name>') do
  # input your logic that create reply message.
  # return string
end
```
- token and block is required.  
- if set channel , send message only specified channel.  
- if set name, only reaction message starts `@botname`.  

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
