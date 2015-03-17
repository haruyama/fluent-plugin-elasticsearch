# encoding: UTF-8

require 'uri'

# Solr utility
module SolrUtil
  def update_core(chunk, core)
    documents = []

    chunk.msgpack_each do |tag, unixtime, record|
      time = Time.at(unixtime)
      time = time.utc unless @localtime
      record.merge!(@time_field => time.strftime('%FT%TZ'))
      record.merge!(@tag_key    => tag) if @include_tag_key
      documents << record
      if documents.count >= @send_rate
        update_core_request(documents)
        documents = []
      end
    end

    update_core_request(documents) if documents.count > 0
  end

  def update_core_request(documents)
    http = Net::HTTP.new(@host, @port.to_i)
    http.read_timeout = @read_timeout
    url = '/solr/' + URI.escape(core) + '/update'
    url += '?commit=true' if @commit
    request = Net::HTTP::Post.new(url, 'content-type' => 'application/json; charset=utf-8')
    request.body = Yajl::Encoder.encode(documents)
    http.request(request).value
  end
end
