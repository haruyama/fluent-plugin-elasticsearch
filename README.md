# fluent-plugin-out-solr

Yet another Solr output plugin for fluentd based on [uken/fluent-plugin-elasticsearch](https://github.com/uken/fluent-plugin-elasticsearch).

Notice: no relationship with [btigit/fluent-plugin-solr](https://github.com/btigit/fluent-plugin-solr).

## Installation

    $ gem install fluent-plugin-out-solr

## Usage

### fluent.conf snippet

```
<source>
  type tail
  format apache
  path /tmp/access.log
  tag apache.access
</source>

<match apache.*>
  type solr
  host localhost
  port 8983
  core collection1
  include_tag_key true
  tag_key tag
  flush_interval 3s
</match>
```

### solrconfig.xml snippet

See: [UniqueKey - Solr Wiki](https://wiki.apache.org/solr/UniqueKey)

```xml
  <requestHandler name="/update" class="solr.UpdateRequestHandler">
    <lst name="defaults">
      <str name="update.chain">uuid</str>
    </lst>
  </requestHandler>

  <updateRequestProcessorChain name="uuid">
    <processor class="solr.UUIDUpdateProcessorFactory">
      <str name="fieldName">id</str>
    </processor>
    <processor class="solr.RunUpdateProcessorFactory" />
  </updateRequestProcessorChain>
```

### schema.xml snippet

```xml
   <field name="id"      type="uuid"   indexed="true" stored="true" required="true"/>

   <field name="host"    type="string"  indexed="true" stored="true"/>
   <field name="user"    type="string"  indexed="true" stored="true"/>
   <field name="method"  type="string"  indexed="true" stored="true"/>
   <field name="path"    type="string"  indexed="true" stored="true"/>
   <field name="code"    type="string"  indexed="true" stored="true"/>
   <field name="size"    type="string"  indexed="true" stored="true"/>
   <field name="referer" type="string"  indexed="true" stored="true"/>
   <field name="agent"   type="text_ws" indexed="true" stored="true"/>
   <field name="tag"     type="string"  indexed="true" stored="true"/>
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
