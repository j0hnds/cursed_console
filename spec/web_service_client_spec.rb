require 'spec_helper'

describe CursedConsole::WebServiceClient do

  let(:wsc) { CursedConsole::WebServiceClient.new('localhost:3000', false, 'token1234') }
  let(:ssl_wsc) { CursedConsole::WebServiceClient.new('localhost:3000', true, 'token') }

  context '#get' do

    it 'will invoke the RestClient get' do
      expect(RestClient).to receive(:get).
        with('http://localhost:3000/services',
             {'Authorization' => 'Token token="token1234"'}).
        and_return("[ 1, 2 ]")

      expect(wsc.get('services')).to eq([ 1, 2 ])
    end

  end

  context '#delete' do

    it 'will invoke the RestClient delete' do
      expect(RestClient).to receive(:delete).
        with('http://localhost:3000/services',
             {'Authorization' => 'Token token="token1234"'}).
        and_return("[ 1, 2 ]")

      expect(wsc.delete('services')).to eq([ 1, 2 ])
    end

  end

  context '#post' do

    it 'will invoke the RestClient post' do
      expect(RestClient).to receive(:post).
        with('http://localhost:3000/services',
             { parm1: '1', parm2: '2' },
             {'Authorization' => 'Token token="token1234"'}).
        and_return("[ 1, 2 ]")

      expect(wsc.post('services', { parm1: '1', parm2: '2' })).to eq([ 1, 2 ])
    end

  end

  context '#put' do

    it 'will invoke the RestClient put' do
      expect(RestClient).to receive(:put).
        with('http://localhost:3000/services',
             { parm1: '1', parm2: '2' },
             {'Authorization' => 'Token token="token1234"'}).
        and_return("[ 1, 2 ]")

      expect(wsc.put('services', { parm1: '1', parm2: '2' })).to eq([ 1, 2 ])
    end

  end

  context '#invoke_rest' do

    it "returns parsed json" do
      val = wsc.send(:invoke_rest, true) { '{"val1":"1", "val2":"2"}' }
      expect(val).to eq({ 'val1' => '1', 'val2' => '2' })
    end

    it "returns unparsed body" do
      val = wsc.send(:invoke_rest, false) { '{"val1":"1", "val2":"2"}' }
      expect(val).to eq('{"val1":"1", "val2":"2"}')
    end

    it "raises exception with invalid JSON" do
      expect { wsc.send(:invoke_rest, true) { '{"val1"=>"1", "val2":"2"}' } }.to raise_error(CursedConsole::WebServiceException)
    end

    it "raises SystemExit when exited" do
      expect { wsc.send(:invoke_rest, true) { exit } }.to raise_error(SystemExit)
    end

    it "raises response exception when non-200 response" do
      expect { wsc.send(:invoke_rest, true) { raise RestClient::Exception } }.to raise_error(CursedConsole::WebServiceResponseException)
    end

  end

  context '#build_url' do

    it "should construct an ssl url" do
      expect(ssl_wsc.send(:build_url, 'services')).to eq("https://localhost:3000/services")
    end

    it "should construct a non-ssl url" do
      expect(wsc.send(:build_url, 'services')).to eq("http://localhost:3000/services")
    end

  end

  context '#authentication_headers' do

    it "returns a hash with the authentication token" do

      expect(wsc.send(:authentication_headers)).to eq({'Authorization' => 'Token token="token1234"'})
    end

  end

  context '#parse_json' do
    
    it 'returns the parsed json' do
      expect(wsc.send(:parse_json, '[ "a", 1 ]')).to eq([ 'a', 1 ])
    end

    it 'raises an exception if the json was invalid' do
      expect { wsc.send(:parse_json, '[ "a, 1 ]') }.to raise_error(CursedConsole::WebServiceException)
    end

  end

end
