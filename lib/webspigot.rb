require 'mechanize'
require 'open-uri'
require 'tempfile'
require 'digest'

class Webspigot
  attr_accessor :search_phrase, :image_url

  def initialize(options)
    @recent_urls = []
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

      log "GET #{url}"
      @m.get(url) do |page|
        log "got #{url}"
        page.links.each do |link|
          phrases << link.text unless bad_text?(link.text)
        end
      end
      clean_phrases(phrases)
      @search_phrase = phrases.sample
    else
      @search_phrase = @options[:search_phrases].sample
    end
    @image_url = get_image_url(@search_phrase)
  end

  def save
    if @image_url.nil? || @image_url.empty?
      log "can't save, @image_url is blank"
      return
    end

    log "image_url (#{@image_url.length}): #{@image_url}"
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
    log "fname: #{fname}"
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
    if text.split.length <= 4
      return true
    end
    !! text['Make Google']
  end

  def get_image_url(phrase)
    log "searching '#{phrase}'"
    enc = URI::encode(phrase)
    links = []
    @m.cookie_jar.add(HTTP::Cookie.new('SRCHHPGUSR', "ADLT=#{@options[:safe_mode]}",
                                       domain: '.bing.com', path: '/'))
    @m.get("http://www.bing.com/images/search?q=#{enc}") do |page|
      page.body.scan(%r{,imgurl:&quot;(.*?)&quot;}).each do |thing|
        t = thing[0]
        fn = t[t.rindex('/') + 1..-1]
        links << t.gsub(/"/, '') if fn['.']
      end
    end
    u = links.sample
    if @recent_urls.include?(u)
      log "dupe: #{u}"
      retries = 0
      while retries < @options[:max_retries]
        u = links.sample
        break unless @recent_urls.include?(u)
        log "dupe: #{u}"
        retries += 1
      end
      log "lots of dupes!" if retries == @options[:max_retries]
    end
    u
  end

  def clean_phrases(phrases)
    log "cleaning #{phrases.length} phrases"
    phrases.each do |p|
      p.gsub!(/\[.*?\]/, '')
      p.gsub!(/\(.*?\)/, '')
      p.gsub!(/[»'"\?]/, '')
      #p.gsub!(/ /, '')
      p.gsub!(/\s+/, ' ')
      p.strip!
    end
  end

  def log(what)
    puts "<#{caller_locations(1,1)[0].label}> #{what}"
  end
end
