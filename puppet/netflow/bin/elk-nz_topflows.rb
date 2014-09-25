#!/usr/bin/ruby

require 'elasticsearch'

client = Elasticsearch::Client.new log: true

q = {
        query: { query_string: { query: "_type:\"nz\"" } },
        size: 0,
        aggregations: {
                group_by_sa: {
                        terms: { 
                                field: 'sa',
                                order: { sum_ibyt: 'desc' }
                        },
                        aggregations: { 
                                sum_ibyt: { sum: { field: 'ibyt' } }
                        }
                }
        }
}

#client.search index: 'myindex', body: { query: { match: { title: 'test' } } }
# => {"took"=>2, ..., "hits"=>{"total":5, ...}}
