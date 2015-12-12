# coding: utf-8

describe ZabbixProtocol do
  subject { described_class }

  context "when request" do
    it "should convert string to zabbix request" do
      res = subject.dump("system.cpu.load[all,avg1]")
      expect(res).to eq "ZBXD\x01\x19\x00\x00\x00\x00\x00\x00\x00" +
       "system.cpu.load[all,avg1]"
    end

    it "should convert hash to zabbix request" do
      req_data = {
        "request" => "sender.data",
        "data" => [{
          "host" => "LinuxDB3",
          "key" => "db.connections",
          "value" => "43"
        }]
      }

      res = subject.dump(req_data)
      expect(res).to eq "ZBXD\x01Z\x00\x00\x00\x00\x00\x00\x00" +
        '{"request":"sender.data","data":[{"host":"LinuxDB3","key":"db.connections","value":"43"}]}'
    end

    context "when multibyte character" do
      it "should convert hash to zabbix request" do
        req_data = {
          "request" => "sender.data",
          "data" => [{
            "host" => "LinuxDB3",
            "key" => "multibyte.item",
            "value" => "ййццууккееннггшшщщ"
          }]
        }

        res = subject.dump(req_data)

        expected = "ZBXD\x01|\x00\x00\x00\x00\x00\x00\x00" +
          %!{"request":"sender.data","data":[{"host":"LinuxDB3","key":"multibyte.item","value":"\xD0\xB9\xD0\xB9\xD1\x86\xD1\x86\xD1\x83\xD1\x83\xD0\xBA\xD0\xBA\xD0\xB5\xD0\xB5\xD0\xBD\xD0\xBD\xD0\xB3\xD0\xB3\xD1\x88\xD1\x88\xD1\x89\xD1\x89"}]}!
        expected.force_encoding('ASCII-8BIT')

        expect(res).to eq expected
      end
    end
  end

  context "when response" do
    it "should parse float" do
      res_data = "ZBXD\x01\b\x00\x00\x00\x00\x00\x00\x001.000000"
      data = subject.load(res_data)
      expect(data).to eq 1.0
    end

    it "should parse hash" do
      res_data = "ZBXD\x01$\x00\x00\x00\x00\x00\x00\x00{\n\t\"response\":\"success\",\n\t\"data\":[]}"
      data = subject.load(res_data)
      expect(data).to eq({"response"=>"success", "data"=>[]})
    end

    it "should parse string" do
      res_data = "ZBXD\x01\x0f\x00\x00\x00\x00\x00\x00\x00response-string"
      data = subject.load(res_data)
      expect(data).to eq("response-string")
      expect(data.encoding).to eq Encoding::UTF_8
    end
  end

  context "when error happen" do
    it "raise error when response is not string" do
      expect {
        subject.load(1)
      }.to raise_error "wrong argument type Fixnum (expected String)"
    end

    it "raise error when response is too short string" do
      expect {
        subject.load("x")
      }.to raise_error 'data length is too short (data: "x")'
    end

    it "raise error when unsupported version" do
      expect {
        res_data = "ZBXD\x02\b\x00\x00\x00\x00\x00\x00\x001.000000"
        subject.load(res_data)
      }.to raise_error 'unsupported version: "\x02" (data: "ZBXD\x02\b\x00\x00\x00\x00\x00\x00\x001.000000")'
    end

    it "raise error when invalid payload length" do
      expect {
        res_data = "ZBXD\x01\x00\x00\x00\x00\x00\x00\x00\x001.000000"
        subject.load(res_data)
      }.to raise_error 'invalid payload length: expected=0, actual=8 (data: "ZBXD\x01\x00\x00\x00\x00\x00\x00\x00\x001.000000")'
    end

    it "should parse error message" do
      res_data = "ZBXD\x01*\x00\x00\x00\x00\x00\x00\x00ZBX_NOTSUPPORTED\x00Invalid second parameter."
      data = subject.load(res_data)
      expect(data).to eq "ZBX_NOTSUPPORTED\x00Invalid second parameter."
    end
  end
end
