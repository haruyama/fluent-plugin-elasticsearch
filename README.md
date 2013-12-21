# fluent-plugin-out-solr

Yet another Solr output plugin for fluentd based on [uken/fluent-plugin-elasticsearch](https://github.com/uken/fluent-plugin-elasticsearch).

Notice: no relationship with [btigit/fluent-plugin-solr](https://github.com/btigit/fluent-plugin-solr).

## Installation

    $ gem install fluent-plugin-out-solr

## Usage

### fluent.conf snippet

#### single core

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
  time_field timestamp
  utc # if you do not want to use localtime

  flush_interval 3s
</match>
```

#### time sliced by date

You should create cores in advance.

See: [Time Sliced Plugin Overview - Buffer Plugin Overview | Fluentd](http://docs.fluentd.org/articles/buffer-plugin-overview#time-sliced-plugin-overview)

```
<source>
  type tail
  format apache
  path /tmp/access.log
  tag apache.access
</source>

<match apache.*>
  type solr_time_sliced
  host localhost
  port 8983
  core log-%Y%m%d
  include_tag_key true
  tag_key tag
  time_field timestamp
  utc # if you do not want to use localtime

  flush_interval 3s
</match>
```

### solrconfig.xml snippet

* See: [UniqueKey - Solr Wiki](https://wiki.apache.org/solr/UniqueKey)
* fluent-plugin-out-solr doesn't commit. use autoSoftCommit and autoCommit.


```xml
  <autoCommit>
    <maxTime>${solr.autoCommit.maxTime:15000}</maxTime>
    <openSearcher>false</openSearcher>
  </autoCommit>

  <autoSoftCommit>
    <maxTime>${solr.autoSoftCommit.maxTime:10}</maxTime>
  </autoSoftCommit>

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

   <field name="timestamp" type="tdate"   indexed="true" stored="true"/>
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
