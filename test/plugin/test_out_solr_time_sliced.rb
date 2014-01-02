require 'test/unit'

require 'fluent/test'
require 'fluent/plugin/out_solr_time_sliced'

require 'webmock/test_unit'

require 'helper'

$LOAD_PATH.push File.expand_path('../lib', __FILE__)
$LOAD_PATH.push File.dirname(__FILE__)

WebMock.disable_net_connect!

# SolrTimeSlicedOutput test
class SolrTimeSlicedOutputTest < Test::Unit::TestCase
  attr_accessor :index_cmds, :content_type
  attr_accessor :index_cmds2

  def setup
    Fluent::Test.setup
    @driver = nil
  end

  def driver(tag = 'test', conf = '')
    @driver ||= Fluent::Test::TimeSlicedOutputTestDriver.new(Fluent::SolrTimeSlicedOutput, tag).configure(conf)
  end

  def sample_record
    { 'age' => 26, 'request_id' => '42' }
  end

  def time
    Time.local(2013, 12, 21, 17, 30, 0).to_i
  end

  def time2
    Time.local(2013, 12, 22, 17, 30, 0).to_i
  end

  def stub_solr(url = 'http://localhost:8983/solr/log-20131221/update')
    stub_request(:post, url).with do |req|
      @content_type = req.headers['Content-Type']
      @index_cmds   = JSON.parse(req.body)
    end
  end

  def stub_solr2(url = 'http://localhost:8983/solr/log-20131222/update')
    stub_request(:post, url).with do |req|
      @content_type2 = req.headers['Content-Type']
      @index_cmds2   = JSON.parse(req.body)
    end
  end

  def stub_solr_unavailable(url = 'http://localhost:8983/solr/log-20131221/update')
    stub_request(:post, url).to_return(status: [503, 'Service Unavailable'])
  end

  def test_writes_to_default_index
    stub_solr
    driver.emit(sample_record, time)
    driver.run
    assert_equal(26,                     @index_cmds[0]['age'])
    assert_equal('42',                   @index_cmds[0]['request_id'])
    assert_equal('2013-12-21T17:30:00Z', @index_cmds[0]['timestamp'])
  end

  def test_wrties_with_proper_content_type
    stub_solr
    driver.emit(sample_record, time)
    driver.run
    assert_equal('application/json; charset=utf-8', @content_type)
  end

  def test_writes_to_speficied_core
    driver.configure("core log-%Y%m%d%H\n")
    solr_request = stub_solr('http://localhost:8983/solr/log-2013122117/update')
    driver.emit(sample_record, time)
    driver.run
    assert_requested(solr_request)
  end

  def test_writes_to_speficied_core2
    driver.configure("core log2-%Y%m%d%H%M\n")
    solr_request = stub_solr('http://localhost:8983/solr/log2-201312211730/update')
    driver.emit(sample_record, time)
    driver.run
    assert_requested(solr_request)
  end

  def test_writes_to_speficied_core3
    driver.configure("core log3-%Y%m%d%H%M%S\n")
    solr_request = stub_solr('http://localhost:8983/solr/log3-20131221173000/update')
    driver.emit(sample_record, time)
    driver.run
    assert_requested(solr_request)
  end

  def test_writes_to_speficied_host
    driver.configure("host 192.168.33.50\n")
    solr_request = stub_solr('http://192.168.33.50:8983/solr/log-20131221/update')
    driver.emit(sample_record, time)
    driver.run
    assert_requested(solr_request)
  end

  def test_writes_to_speficied_port
    driver.configure("port 9201\n")
    solr_request = stub_solr('http://localhost:9201/solr/log-20131221/update')
    driver.emit(sample_record, time)
    driver.run
    assert_requested(solr_request)
  end

  def test_emit_multi_records
    stub_solr
    driver.emit(sample_record, time)
    driver.emit(sample_record.merge('age' => 27), time)
    driver.run
    assert_equal(2,  @index_cmds.count)
    assert_equal(26, @index_cmds[0]['age'])
    assert_equal(27, @index_cmds[1]['age'])
  end

  def test_doesnt_add_tag_key_by_default
    stub_solr
    driver.emit(sample_record, time)
    driver.run
    assert_nil(@index_cmds[0]['tag'])
  end

  def test_adds_tag_key_when_configured
    driver('mytag').configure("include_tag_key true\n")
    stub_solr
    driver.emit(sample_record, time)
    driver.run
    assert(@index_cmds[0].key?('tag'))
    assert_equal(@index_cmds[0]['tag'], 'mytag')
  end

  def test_utc
    driver.configure("utc\n")
    stub_solr
    ENV['TZ'] = 'Japan'
    driver.emit(sample_record, Time.local(2013, 12, 22, 7, 30, 0).to_i)
    ENV['TZ'] = nil
    driver.run
    assert_equal('2013-12-21T22:30:00Z', @index_cmds[0]['timestamp'])
  end

  def test_emit_records_on_different_days
    stub_solr
    stub_solr2
    driver.emit(sample_record, time)
    driver.emit(sample_record, time2)
    driver.run
    assert_equal(1,  @index_cmds.count)
    assert_equal(1,  @index_cmds2.count)
  end

  def test_request_error
    stub_solr_unavailable
    driver.emit(sample_record, time)
    assert_raise(Net::HTTPFatalError) do
      driver.run
    end
  end
end
