TODO:
* https://github.com/Mortinke/logstash-pattern/blob/master/logstash/etc/logstash/patterns/gc
* https://docs.splunk.com/Documentation/Splunk/latest/Forwarding/Routeandfilterdatad#Filter_event_data_and_send_to_queues


```
import json
f = open('/databricks/common/conf/deploy.conf')
j = next(l for l in f.readlines() if 'clusterAllTags' in l).split(' = ')
/dbfs/tmp/${$DB_CLUSTER_ID} json.loads(json.loads(j[1]))

```