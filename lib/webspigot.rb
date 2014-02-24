require 'mechanize'
require 'open-uri'
require 'tempfile'
require 'digest'
require 'api_cache'

require 'webspigot/ws_logger'

class Webspigot
  attr_accessor :search_phrase, :image_url

  def initialize(options)
    @logger = WsLogger.new
    @recent_urls = []
    @phrases = {}
    @options = options
    @m = Mechanize.new
  end

  def run
    if @options[:search_phrases].empty?
      phrases = []
      url = get_news_url
      APICache.get(url,
                   :cache => @options[:cache_period],
                   :timeout => @options[:cache_timeout]) do
        log "caching #{url} for #{@options[:cache_period]} seconds"
        @phrases[url] ||= []
        @m.get(url) do |page|
          page.links.each do |link|
            @phrases[url] << clean_phrase(link.text) unless bad_text?(link.text)
          end
        end
        log "found #{@phrases.count} phrases"
      end
      @search_phrase = @phrases[url].sample
    else
      @search_phrase = @options[:search_phrases].sample
    end
    @image_url = get_image_url(@search_phrase)
    log_url(@image_url, @search_phrase)
  end

  def save(fname=nil)
    start = Time.now
    unless Dir.exist?('/tmp/webspigot')
      Dir.mkdir('/tmp/webspigot')
    end
    if fname.nil?
      if @image_url.nil? || @image_url.empty?
        log "can't save, @image_url is blank"
        return
      end
      log "@image_url #{@image_url}"
      fname = @image_url.split('/').last
      fname = fname[0..fname.index('?') - 1] if fname['?']
      fname = fname[0..fname.index('&') - 1] if fname['&']
      fname.gsub!(/[()!$,~]/, '')
    end
    fname = "/tmp/webspigot/#{fname}"
    log "final #{fname}"
    File.open(fname, 'wb') do |f|
      begin
        open(@image_url) do |image|
          stuff = image.read
          f.write(stuff)
        end
      rescue OpenURI::HTTPError => e
        log "error: #{e}"
      end
    end
    log "image saved in #{Time.now - start}s"
    fname
  end

  private

  def bad_text?(text)
    return true if text.split.length <= 3
    !! text['Make Google']
  end

  def get_news_url
    # Google categories
    # b  - Business
    # w  - World
    # n  - US
    # tc - Technology
    # e  - Entertainment
    # s  - Sports
    # snc- Science
    # m  - Health
    # ir - Spotlight
    news_sites = [{ name: 'Google News',
                    section: ['b', 'w', 'n', 'tc', 'e', 's', 'snc', 'm', 'ir'],
                    base_url: 'https://news.google.com/news/section/?section=' },
                  { name: 'Bing News',
                    section: ['us+news', 'world+news', 'local', 'entertainment+news',
                              'science+technology+news', 'business+news', 'political+news',
                              'sports+news', 'health+news'],
                    base_url: 'http://www.bing.com/news?q=' },
                  { name: 'Yahoo News',
                    section: ['us', 'world', 'politics', 'tech', 'science', 'health',
                              'odd-news', 'opinion', 'local', 'dear-abby', 'abc-news',
                              'originals', 'photos'],
                    base_url: 'http://news.yahoo.com/' }]
    site = news_sites.sample
    log "using #{site[:name]}"
    "#{site[:base_url]}#{site[:section].sample}"
  end

  def get_image_url(phrase)
    return nil if phrase.nil? || phrase.empty?

    log "searching '#{phrase}'"
    enc = URI::encode(phrase)
    links = []
    @m.cookie_jar.add(HTTP::Cookie.new('SRCHHPGUSR', "ADLT=#{@options[:safe_mode]}",
                                       domain: '.bing.com', path: '/'))
    img_size = '' #"&qft=+filterui:imagesize-medium"
    @m.get("http://www.bing.com/images/search?q=#{enc}#{img_size}") do |page|
      page.body.scan(%r{,imgurl:&quot;(.*?)&quot;}).each do |thing|
        t = thing[0]
        fn = t[t.rindex('/') + 1..-1]
        links << t.gsub(/"/, '') if fn['.']
      end
    end
    u = links.sample
    unless u.nil? || u.empty?
      if @recent_urls.include?(u)
        log "dupe: #{u} (there are #{links.count} links)"
        retries = 0
        while retries < @options[:max_retries]
          u = links.sample
          break unless @recent_urls.include?(u)
          log "dupe: #{u} (retry ##{retries}, there are #{links.count} links)"
          retries += 1
        end
        log "lots of dupes!" if retries == @options[:max_retries]
      end

      @recent_urls << u
      @recent_urls.shift if @recent_urls.length > @options[:max_recent_urls]
    end
    u
  end

  def clean_phrase(phrase)
    phrase.gsub!(/.*?:/, '')
    phrase.gsub!(/\[.*?\]/, '')
    phrase.gsub!(/\(.*?\)/, '')
    phrase.gsub!(/[»'"\?]/, '')
    phrase.gsub!(/…/, '')
    phrase.gsub!(/\r/, '')
    phrase.gsub!(/\n/, '')

    phrase.gsub!(/\ +/, ' ')
    phrase.strip!
    phrase
  end

  def log(what)
    loc = caller_locations(1,1)[0].to_s.match(/`(.*?)'/)[1]
    @logger.debug("<#{loc}> #{what}")
  end

  def log_url(url, search_phrase)
    return if @options[:urlfile].nil?

    File.open(@options[:urlfile], 'a') do |file|
      file.puts("#{Time.now} [#{search_phrase}] #{url}")
    end
  end
end
