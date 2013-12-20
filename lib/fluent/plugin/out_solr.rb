# encoding: UTF-8
require 'net/http'
require 'uri'

# Solr output plugin for Fluent
class Fluent::SolrOutput < Fluent::BufferedOutput
  Fluent::Plugin.register_output('solr', self)

  config_param :host,       :string,  default: 'localhost'
  config_param :port,       :integer, default: 8983
  config_param :core,       :string,  default: 'collection1'
  config_param :time_field, :string,  default: 'timestamp'
  config_param :use_utc,    :bool,    default: false

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
    bulk_message = []

    chunk.msgpack_each do |tag, time, record|

      time_string =
        if @use_utc
          Time.at(time).utc.strftime('%FT%TZ')
        else
          Time.at(time).strftime('%FT%TZ')
        end

      record.merge!(@time_field => time_string)
      record.merge!(@tag_key    => tag) if @include_tag_key
      bulk_message << record
    end

    http = Net::HTTP.new(@host, @port.to_i)
    request = Net::HTTP::Post.new('/solr/' + URI.escape(@core) + '/update', 'content-type' => 'application/json; charset=utf-8')
    request.body = Yajl::Encoder.encode(bulk_message)
    http.request(request).value
  end
end
