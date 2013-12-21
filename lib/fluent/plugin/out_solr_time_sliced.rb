# encoding: UTF-8

# Solr output plugin for Fluent
class Fluent::SolrTimeSlicedOutput < Fluent::TimeSlicedOutput
  Fluent::Plugin.register_output('solr_time_sliced', self)

  config_set_default :buffer_type,       'memory'
  config_set_default :time_slice_format, '%Y%m%d'

  config_param :host,              :string,  default: 'localhost'
  config_param :port,              :integer, default: 8983
  config_param :core,              :string,  default: 'log-%Y%m%d'
  config_param :time_field,        :string,  default: 'timestamp'

  include Fluent::SetTagKeyMixin
  config_set_default :include_tag_key, false

  attr_accessor :localtime

  def initialize
    require 'net/http'
    require 'uri'
    require 'time'
    super
    @localtime = true
  end

  def configure(conf)
    if conf['core']
      if conf['core'].index('%S')
        conf['time_slice_format'] = '%Y%m%d%H%M%S'
      elsif conf['core'].index('%M')
        conf['time_slice_format'] = '%Y%m%d%H%M'
      elsif conf['core'].index('%H')
        conf['time_slice_format'] = '%Y%m%d%H'
      end
    end
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

  def core_format(chunk_key)
    Time.strptime(chunk_key, @time_slice_format).strftime(@core)
  end

  def write(chunk)
    documents = []

    chunk.msgpack_each do |tag, unixtime, record|
      time = Time.at(unixtime)
      time = time.utc unless @localtime
      record.merge!(@time_field => time.strftime('%FT%TZ'))
      record.merge!(@tag_key    => tag) if @include_tag_key
      documents << record
    end

    http         = Net::HTTP.new(@host, @port.to_i)
    request      = Net::HTTP::Post.new('/solr/' + URI.escape(core_format(chunk.key)) + '/update', 'content-type' => 'application/json; charset=utf-8')
    request.body = Yajl::Encoder.encode(documents)
    http.request(request).value
  end
end
