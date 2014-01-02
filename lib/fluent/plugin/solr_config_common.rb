# encoding: UTF-8

require 'fluent/config'

# Solr Config Common
module SolrConfigCommon
  include Fluent::Configurable
  config_param :host,       :string,  default: 'localhost'
  config_param :port,       :integer, default: 8983
  config_param :time_field, :string,  default: 'timestamp'
  config_param :commit,     :bool,    default: false

  include Fluent::SetTagKeyMixin
  config_set_default :include_tag_key, false

  attr_accessor :localtime
end
