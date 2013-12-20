require 'test/unit'

require 'fluent/test'
require 'fluent/plugin/out_solr'

require 'webmock/test_unit'

require 'helper'

$LOAD_PATH.push File.expand_path('../lib', __FILE__)
$LOAD_PATH.push File.dirname(__FILE__)

WebMock.disable_net_connect!

# Solr output test
class SolrOutput < Test::Unit::TestCase
  attr_accessor :index_cmds, :content_type
  attr_accessor :index_cmds2

  def setup
    Fluent::Test.setup
    @driver = nil
  end

  def driver(tag = 'test', conf = '')
    @driver ||= Fluent::Test::BufferedOutputTestDriver.new(Fluent::SolrOutput, tag).configure(conf)
  end

  def sample_record
    { 'age' => 26, 'request_id' => '42' }
  end

  def stub_solr(url = 'http://localhost:8983/solr/collection1/update')
    stub_request(:post, url).with do |req|
      @content_type = req.headers['Content-Type']
      @index_cmds = JSON.parse(req.body)
    end
  end

  def stub_solr2(url = 'http://localhost:8983/solr/collection1/update')
    stub_request(:post, url).with do |req|
      @index_cmds2   = JSON.parse(req.body)
    end
  end

  def stub_solr_unavailable(url = 'http://localhost:8983/solr/collection1/update')
    stub_request(:post, url).to_return(status: [503, 'Service Unavailable'])
  end

  def test_writes_to_default_index
    stub_solr
    driver.emit(sample_record, Time.local(2013, 12, 20, 19, 0, 0).to_i)
    driver.run
    assert_equal(26,                     @index_cmds[0]['age'])
    assert_equal('42',                   @index_cmds[0]['request_id'])
    assert_equal('2013-12-20T19:00:00Z', @index_cmds[0]['timestamp'])
  end

  def test_wrties_with_proper_content_type
    stub_solr
    driver.emit(sample_record)
    driver.run
    assert_equal('application/json; charset=utf-8', @content_type)
  end

  def test_writes_to_speficied_core
    driver.configure("core mycore\n")
    solr_request = stub_solr('http://localhost:8983/solr/mycore/update')
    driver.emit(sample_record)
    driver.run
    assert_requested(solr_request)
  end

  def test_writes_to_speficied_host
    driver.configure("host 192.168.33.50\n")
    solr_request = stub_solr('http://192.168.33.50:8983/solr/collection1/update')
    driver.emit(sample_record)
    driver.run
    assert_requested(solr_request)
  end

  def test_writes_to_speficied_port
    driver.configure("port 9201\n")
    solr_request = stub_solr('http://localhost:9201/solr/collection1/update')
    driver.emit(sample_record)
    driver.run
    assert_requested(solr_request)
  end

  def test_makebulk
    stub_solr
    driver.emit(sample_record)
    driver.emit(sample_record.merge('age' => 27))
    driver.run
    assert_equal(2,  @index_cmds.count)
    assert_equal(26, @index_cmds[0]['age'])
    assert_equal(27, @index_cmds[1]['age'])
  end

  def test_doesnt_add_tag_key_by_default
    stub_solr
    driver.emit(sample_record)
    driver.run
    assert_nil(@index_cmds[0]['tag'])
  end

  def test_adds_tag_key_when_configured
    driver('mytag').configure("include_tag_key true\n")
    stub_solr
    driver.emit(sample_record)
    driver.run
    assert(@index_cmds[0].key?('tag'))
    assert_equal(@index_cmds[0]['tag'], 'mytag')
  end

  def test_use_utc
    driver.configure("use_utc true\n")
    stub_solr
    driver.emit(sample_record, Time.local(2013, 12, 20, 19, 0, 0).to_i)
    driver.run
    assert_equal('2013-12-20T10:00:00Z', @index_cmds[0]['timestamp'])
  end

  def test_use_core_rotation
    driver.configure("use_core_rotation true\n")
    driver.configure("core_prefix log\n")
    stub_solr('http://localhost:8983/solr/log-2013-12-20/update')
    stub_solr2('http://localhost:8983/solr/log-2013-12-21/update')
    driver.emit(sample_record, Time.local(2013, 12, 20, 19, 0, 0).to_i)
    driver.emit(sample_record, Time.local(2013, 12, 21, 19, 0, 0).to_i)
    driver.run
    assert_equal(1,  @index_cmds.count)
    assert_equal(1,  @index_cmds2.count)
  end

  def test_request_error
    stub_solr_unavailable
    driver.emit(sample_record)
    assert_raise(Net::HTTPFatalError) do
      driver.run
    end
  end
end
