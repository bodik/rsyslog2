pa.sh -e 'include elk::esd'
pa.sh -e 'class { "elk::lsl": process_stream_auth=>true, }'
pa.sh -e 'include elk::kbn'
