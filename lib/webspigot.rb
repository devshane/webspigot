require 'mechanize'
require 'open-uri'
require 'tempfile'

class Webspigot
  attr_accessor :search_phrase, :image_url

  def initialize(options)
    @options = options
    @m = Mechanize.new
  end

  def run(phrase=nil)
    if phrase.nil?
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
          if link.text.split.length > 4
            phrases << link.text
          end
        end
      end
      clean_phrases(phrases)
      phrase = phrases.sample
    end
    @search_phrase = phrase
    @image_url = nil
    while @image_url.nil?
      @image_url = get_image_url(phrase)
    end
  end

  def save
    log "image_url: #{@image_url}"
    iu = @image_url['?'] ? @image_url[0..@image_url.index('?') - 1] : @image_url
    #puts "iu: #{iu}"
    ext = iu[iu.rindex('.')..-1]
    rnd = (100000 + (99999 * rand)).to_i
    fname = "/tmp/spigot-#{rnd}#{ext}"
    #puts "fname: #{fname}"
    File.open(fname, 'wb') do |f|
      open(@image_url) do |image|
        f.write(image.read)
      end
    end
    fname
  end

  private

  def get_image_url(phrase)
    log "searching '#{phrase}'"
    enc = URI::encode(phrase)
    links = []
    @m.cookie_jar.add(HTTP::Cookie.new('SRCHHPGUSR', "ADLT=#{@options[:safe_mode]}",
                                       domain: '.bing.com', path: '/'))
    @m.get("http://www.bing.com/images/search?q=#{enc}") do |page|
      page.body.scan(%r{,imgurl:&quot;(.*?)&quot;}).each do |thing|
        t = thing[0]
        if t['.']
          links << thing[0].gsub(/"/, '')
        end
      end
    end
    links.sample
  end

  def clean_phrases(phrases)
    log "cleaning #{phrases.length} phrases"
    phrases.each do |p|
      p.gsub!(/\[.*?\]/, '')
      p.gsub!(/\(.*?\)/, '')
      p.gsub!(/\s+/, ' ')
    end
  end

  def log(what)
    puts "<#{caller_locations(1,1)[0].label}> #{what}"
  end
end
