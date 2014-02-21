require 'mechanize'
require 'open-uri'
require 'tempfile'
require 'digest'
require 'api_cache'
require 'logger'


class Webspigot
  attr_accessor :search_phrase, :image_url

  def initialize(options)
    @logger = Logger.new(STDOUT)
    @recent_urls = []
    @phrases = {}
    @options = options
    @m = Mechanize.new
  end

  def run
    if @options[:search_phrases].empty?
      phrases = []

      # b  - Business
      # w  - World
      # n  - US
      # tc - Technology
      # e  - Entertainment
      # s  - Sports
      # snc- Science
      # m  - Health
      # ir - Spotlight

      section = ['b', 'w', 'n', 'tc', 'e', 's', 'snc', 'm', 'ir']
      url = "https://news.google.com/news/section/?section=#{section.sample}"

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
      end
      @search_phrase = @phrases[url].sample
    else
      @search_phrase = @options[:search_phrases].sample
    end
    @image_url = get_image_url(@search_phrase)
    log_url(@image_url, @search_phrase)
  end

  def save
    if @image_url.nil? || @image_url.empty?
      log "can't save, @image_url is blank"
      return
    end

    if @image_url['.jpg']
      ext = '.jpg'
    elsif @image_url['.gif']
      ext = '.gif'
    elsif @image_url['.png']
      ext = '.png'
    else
      ext = '.jpg' # leap of faith
    end
    hash = Digest::SHA1.hexdigest(@image_url)
    fname = "/tmp/spigot-#{hash}#{ext}"
    begin
      File.open(fname, 'wb') do |f|
        open(@image_url) do |image|
          f.write(image.read)
        end
      end
    rescue => e
      log "error: #{e}"
      fname = ''
    end
    fname
  end

  private

  def bad_text?(text)
    return true if text.split.length <= 4
    !! text['Make Google']
  end

  def get_image_url(phrase)
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
        log "dupe: #{u} (there are #{links.count} links"
        retries = 0
        while retries < @options[:max_retries]
          u = links.sample
          break unless @recent_urls.include?(u)
          log "dupe: #{u} (retry ##{retries}, there are #{links.count} links"
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
    phrase.gsub!(/\ +/, ' ')
    phrase.strip!
    phrase
  end

  def log(what)
    @logger.debug("<#{caller_locations(1,1)[0].label}> #{what}")
  end

  def log_url(url, search_phrase)
    return if @options[:urlfile].nil?

    File.open(@options[:urlfile], 'a') do |file|
      file.puts("#{Time.now} [#{search_phrase}] #{url}")
    end
  end
end
