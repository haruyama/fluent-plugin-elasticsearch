# encoding: UTF-8

# Solr output plugin for Fluent
class Fluent::SolrTimeSlicedOutput < Fluent::TimeSlicedOutput
  Fluent::Plugin.register_output('solr_time_sliced', self)

  require 'fluent/plugin/solr_util'
  include SolrUtil

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
    update_core(chunk, core_format(chunk.key))
  end
end
