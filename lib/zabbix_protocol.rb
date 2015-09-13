require "multi_json"

require "zabbix_protocol/version"

module ZabbixProtocol
  class Error < StandardError; end

  # http://www.zabbix.org/wiki/Docs/protocols/zabbix_agent/1.4
  ZABBIX_HEADER  = "ZBXD"
  ZABBIX_VERSION = "\x01"
  PAYLOAD_LEN_BYTES = 8

  MIN_DATA_LEN = ZABBIX_HEADER.length + ZABBIX_VERSION.length + PAYLOAD_LEN_BYTES

  def self.dump(payload)
    if payload.is_a?(Hash)
      payload = MultiJson.dump(payload)
    else
      payload = payload.to_s
    end

    [
      ZABBIX_HEADER,
      ZABBIX_VERSION,
      [payload.length].pack('Q'),
      payload
    ].join
  end

  def self.load(data)
    unless data.is_a?(String)
      raise TypeError, "wrong argument type #{data.class} (expected String)"
    end

    if data.length < MIN_DATA_LEN
      raise Error, "data length is too short (data: #{data.inspect})"
    end

    sliced = data.dup
    header = sliced.slice!(0, ZABBIX_HEADER.length)

    if header != ZABBIX_HEADER
      raise Error, "invalid header: #{header.inspect} (data: #{data.inspect})"
    end

    version = sliced.slice!(0, ZABBIX_VERSION.length)

    if version != ZABBIX_VERSION
      raise Error, "unsupported version: #{version.inspect} (data: #{data.inspect})"
    end

    payload_len = sliced.slice!(0, PAYLOAD_LEN_BYTES)
    payload_len = payload_len.unpack("Q").first

    if payload_len != sliced.length
      raise Error, "invalid payload length: expected=#{payload_len}, actual=#{sliced.length} (data: #{data.inspect})"
    end

    begin
      MultiJson.load(sliced)
    rescue MultiJson::ParseError
      sliced
    end
  end
end
