# encoding: UTF-8
require 'net/http'
require 'uri'

# Solr output plugin for Fluent
class Fluent::SolrOutput < Fluent::BufferedOutput
  Fluent::Plugin.register_output('solr', self)

  config_param :host,              :string,  default: 'localhost'
  config_param :port,              :integer, default: 8983
  config_param :core,              :string,  default: 'collection1'
  config_param :use_core_rotation, :bool,    default: false
  config_param :core_prefix,       :string,  default: 'core'
  config_param :time_field,        :string,  default: 'timestamp'
  config_param :use_utc,           :bool,    default: false

  include Fluent::SetTagKeyMixin
  config_set_default :include_tag_key, false

  def initialize
    super
  end

  def configure(conf)
    super
  end

  def start
    super
  end

  def format(tag, time, record)
    [tag, time, record].to_msgpack
  end

  def shutdown
    super
  end

  def write(chunk)
    bulk_messages = Hash.new { |h, k| h[k] = [] }

    chunk.msgpack_each do |tag, unixtime, record|
      time = Time.at(unixtime)
      time = time.utc if @use_utc
      record.merge!(@time_field => time.strftime('%FT%TZ'))
      record.merge!(@tag_key    => tag) if @include_tag_key
      if @use_core_rotation
        bulk_messages[@core_prefix + '-' + time.strftime('%F')] << record
      else
        bulk_messages[@core] << record
      end
    end

    http = Net::HTTP.new(@host, @port.to_i)
    bulk_messages.each do |corename, messages|
      request = Net::HTTP::Post.new('/solr/' + URI.escape(corename) + '/update', 'content-type' => 'application/json; charset=utf-8')
      request.body = Yajl::Encoder.encode(messages)
      http.request(request).value
    end
  end
end
