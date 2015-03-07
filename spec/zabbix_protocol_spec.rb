describe ZabbixProtocol do
  subject { described_class }

  context "when request" do
    it "should convert string to zabbix request" do
      res = subject.dump("system.cpu.load[all,avg1]")
      expect(res).to eq "ZBXD\x01\x1A\x00\x00\x00\x00\x00\x00\x00" +
       "system.cpu.load[all,avg1]\n"
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
      }.to raise_error "response data is too short"
    end

    it "raise error when unsupported version" do
      expect {
        res_data = "ZBXD\x02\b\x00\x00\x00\x00\x00\x00\x001.000000"
        subject.load(res_data)
      }.to raise_error 'unsupported version: "\\u0002"'
    end

    it "raise error when invalid data length" do
      expect {
        res_data = "ZBXD\x01\x00\x00\x00\x00\x00\x00\x00\x001.000000"
        subject.load(res_data)
      }.to raise_error "invalid data length: expected=0, actual=8"
    end
  end
end
