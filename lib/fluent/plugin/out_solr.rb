# encoding: UTF-8

# Solr output plugin for Fluent
class Fluent::SolrOutput < Fluent::BufferedOutput
  Fluent::Plugin.register_output('solr', self)

  require 'fluent/plugin/solr_util'
  include SolrUtil
  require 'fluent/plugin/solr_config_common'
  include SolrConfigCommon

  config_param :core, :string,  default: 'collection1'

  def initialize
    require 'net/http'
    require 'uri'
    require 'time'
    super
    @localtime = true
  end

  def configure(conf)
    if conf['utc']
      @localtime = false
    elsif conf['localtime']
      @localtime = true
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

  def write(chunk)
    update_core(chunk, @core, @commit)
  end
end
