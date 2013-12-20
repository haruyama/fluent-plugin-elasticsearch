# encoding: UTF-8
require 'net/http'
require 'date'

# Solr output plugin for Fluent
class Fluent::SolrOutput < Fluent::BufferedOutput
  Fluent::Plugin.register_output('out-solr', self)

  config_param :host,       :string,  default: 'localhost'
  config_param :port,       :integer, default: 8983
  config_param :core,       :string,  default: 'collection1'
  config_param :type_name,  :string,  default: 'fluentd'
  config_param :index_name, :string,  default: 'fluentd'

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
      record.merge!(@tag_key => tag) if @include_tag_key

      bulk_message << record
    end

    http = Net::HTTP.new(@host, @port.to_i)
    request = Net::HTTP::Post.new('/solr/' + @core + '/update', 'content-type' => 'application/json; charset=utf-8')
    request.body = Yajl::Encoder.encode(bulk_message)
    http.request(request).value
  end
end
