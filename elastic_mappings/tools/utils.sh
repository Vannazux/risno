set -o pipefail

function init_scroll() {
  local index=$1
  curl -fs -XGET "localhost:9200/${index}/_search?search_type=scan&pretty&size=1000&scroll=10m" -d '
  {
   "fields": ["_parent", "_source"],
   "query": {"match_all" : {}}
  }' \
  | jq -r "._scroll_id,.hits.total"
}

function scroll() {
  local scroll_id=$1
  curl -fs -XGET 'localhost:9200/_search/scroll?scroll=10m' -d ${scroll_id} \
  | jq ".hits.hits | .[]"
}

function object2bulk() {
  local to_index=$1
  jq -c "if .fields then
          {index:({_index: \"${to_index}\",_type,_id} + .fields)}
         else
          {index:{_index: \"${to_index}\",_type,_id}}
         end,
         if .__extra then ._source + .__extra else ._source end"
}

function bulk_insert() {
  curl -fs -XPOST localhost:9200/_bulk --data-binary @-
}

function index_size() {
  local index=$1
  curl -fs -XGET "localhost:9200/${index}/_search?search_type=scan&pretty&scroll=1" -d '
  {
   "query": {"match_all" : {}}
  }' \
  | jq -r ".hits.total"
}

