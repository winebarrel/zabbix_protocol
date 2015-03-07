require "multi_json"

require "zabbix_protocol/version"

module ZabbixProtocol
  class Error < StandardError; end

  # http://www.zabbix.org/wiki/Docs/protocols/zabbix_agent/1.4
  ZABBIX_HEADER  = "ZBXD"
  ZABBIX_VERSION = "\x01"
  DATA_LEN_BYTES = 8

  MIN_RESPONSE_LEN = ZABBIX_HEADER.length + ZABBIX_VERSION.length + DATA_LEN_BYTES

  def self.dump(data)
    if data.is_a?(Hash)
      data = MultiJson.dump(data)
    else
      data = data.to_s
    end

    [
      ZABBIX_HEADER,
      ZABBIX_VERSION,
      [data.length].pack('Q'),
      data
    ].join
  end

  def self.load(res_data)
    unless res_data.is_a?(String)
      raise TypeError, "wrong argument type #{res_data.class} (expected String)"
    end

    if res_data.length < MIN_RESPONSE_LEN
      raise Error, "response data is too short"
    end

    data = res_data.dup
    header = data.slice!(0, ZABBIX_HEADER.length)

    if header != ZABBIX_HEADER
      raise Error, "invalid header: #{header.inspect}"
    end

    version = data.slice!(0, ZABBIX_VERSION.length)

    if version != ZABBIX_VERSION
      raise Error, "unsupported version: #{version.inspect}"
    end

    data_len = data.slice!(0, DATA_LEN_BYTES)
    data_len = data_len.unpack("Q").first

    if data_len != data.length
      raise Error, "invalid data length: expected=#{data_len}, actual=#{data.length}"
    end

    begin
      MultiJson.load(data)
    rescue MultiJson::ParseError
      data
    end
  end
end
