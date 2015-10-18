trawler-client-ruby
=====================

ruby client library for using the Trawler service to throttle one's automated access to NationStates.net

(TODO: make more friendly)

Basic guidance:

```bash
$ gem build trawler.gemspec
$ gem install trawler-client-0.1.1.gem
```

```ruby
TRAWLER_USER_AGENT = PUT SOMETHING HERE
require 'trawler'

require 'nokogiri'

doc = Nokogiri::XML( Trawler.request( 'get', 'cgi-bin/api.cgi', query: "region=taijitu&q=nations&v=7" ).read )
nations = doc.xpath('//NATIONS').first.text.split(':')
nation = nations.sample
nxml = Nokogiri::XML( Trawler.request( 'get', 'cgi-bin/api.cgi', query: "nation=#{nation}&q=name+admirable&v=7" ).read )
name = nxml.xpath("//NAME").first.text
admirable = nxml.xpath("//ADMIRABLE").first.text
puts "The people of #{name} are admirably #{admirable}."
```
