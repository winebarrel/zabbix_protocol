# ZabbixProtocol

Zabbix protocols builder/parser.

see http://www.zabbix.org/wiki/Docs/protocols

[![Gem Version](https://badge.fury.io/rb/zabbix_protocol.svg)](http://badge.fury.io/rb/zabbix_protocol)
[![Build Status](https://travis-ci.org/winebarrel/zabbix_protocol.svg?branch=master)](https://travis-ci.org/winebarrel/zabbix_protocol)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'zabbix_protocol'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install zabbix_protocol

## Usage

### Zabbix 1.4 Passive checks

http://www.zabbix.org/wiki/Docs/protocols/zabbix_agent/1.4

```ruby
require 'socket'
require 'zabbix_protocol'

AGENT_PORT = 10050

TCPSocket.open("127.0.0.1", AGENT_PORT) do |sock|
  data = "system.cpu.load[all,avg1]"

  sock.print ZabbixProtocol.dump(data)
  p ZabbixProtocol.load(sock.read) #=> 0.04
end
```

### Zabbix 1.6 Active agents

http://www.zabbix.org/wiki/Docs/protocols/zabbix_agent/1.6

```ruby
require 'socket'
require 'zabbix_protocol'

SERVER_PORT = 10051

TCPSocket.open("127.0.0.1", SERVER_PORT) do |sock|
  data = {"request" => "active checks", "host" => "my server"}

  sock.print ZabbixProtocol.dump(data)
  p ZabbixProtocol.load(sock.read)
  #=> {"response"=>"success", "data"=>[]}
end
```

### Zabbix sender 1.8 protocol

http://www.zabbix.org/wiki/Docs/protocols/zabbix_sender/1.8

```ruby
require 'socket'
require 'zabbix_protocol'

SERVER_PORT = 10051

TCPSocket.open("127.0.0.1", SERVER_PORT) do |sock|
  data = {
    "request" => "sender data",
    "data" => [{
      "host" => "my server",
      "key" => "my.key",
      "value" => "1"
    }]
  }

  sock.print ZabbixProtocol.dump(data)
  p ZabbixProtocol.load(sock.read)
  #=> {"response"=>"success", "info"=>"Processed 0 Failed 1 Total 1 Seconds spent 0.000018"}
end
```
