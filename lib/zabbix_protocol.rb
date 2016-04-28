require "multi_json"
require "zabbix_protocol/version"

module ZabbixProtocol
  class Error < StandardError; end

  # http://www.zabbix.org/wiki/Docs/protocols/zabbix_agent/1.4
  ZABBIX_HEADER  = "ZBXD"
  ZABBIX_VERSION = "\x01"
  PAYLOAD_LEN_BYTES = 8

  MIN_DATA_LEN = ZABBIX_HEADER.bytesize + ZABBIX_VERSION.bytesize + PAYLOAD_LEN_BYTES

  def self.dump(payload)
    if payload.is_a?(Hash)
      payload = MultiJson.dump(payload)
    else
      payload = payload.to_s
    end

    payload.force_encoding('ASCII-8BIT')

    [
      ZABBIX_HEADER,
      ZABBIX_VERSION,
      [payload.bytesize].pack('Q<'),
      payload
    ].join
  end

  def self.load(data)
    unless data.is_a?(String)
      raise TypeError, "wrong argument type #{data.class} (expected String)"
    end

    original_encoding = data.encoding
    data = data.dup
    data.force_encoding('ASCII-8BIT')

    if data.bytesize < MIN_DATA_LEN
      raise Error, "data length is too short (data: #{data.inspect})"
    end

    sliced = data.dup
    header = sliced.slice!(0, ZABBIX_HEADER.bytesize)

    if header != ZABBIX_HEADER
      raise Error, "invalid header: #{header.inspect} (data: #{data.inspect})"
    end

    version = sliced.slice!(0, ZABBIX_VERSION.bytesize)

    if version != ZABBIX_VERSION
      raise Error, "unsupported version: #{version.inspect} (data: #{data.inspect})"
    end

    payload_len = sliced.slice!(0, PAYLOAD_LEN_BYTES)
    payload_len = payload_len.unpack('Q<').first

    if payload_len != sliced.bytesize
      raise Error, "invalid payload length: expected=#{payload_len}, actual=#{sliced.bytesize} (data: #{data.inspect})"
    end

    duplicated = sliced.dup

    begin
      duplicated.force_encoding(original_encoding)
      sliced = duplicated
    rescue
      # XXX: nothing to do
    end

    begin
      MultiJson.load(sliced)
    rescue MultiJson::ParseError
      sliced
    end
  end
end
