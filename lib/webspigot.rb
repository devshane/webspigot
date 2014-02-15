require 'mechanize'
require 'open-uri'

class Webspigot
  attr_accessor :search_phrase, :image_url

  def initialize
    @m = Mechanize.new

    @options = {
      safe_mode: "OFF"
    }
  end

  def run(phrase=nil)
    if phrase.nil?
      phrases = []
      @m.get('https://news.google.com/') do |page|
        page.links.each do |link|
          phrases << link.text if link.text.split.length > 4
        end
      end
      clean_phrases(phrases)
      phrase = phrases.sample
    end
    @search_phrase = phrase
    @image_url = get_image_url(phrase)
  end

  private

  def get_image_url(phrase)
    enc = URI::encode(phrase)
    links = []
    @m.cookie_jar.add(HTTP::Cookie.new('SRCHHPGUSR', "ADLT=#{@options[:safe_mode]}",
                                       domain: '.bing.com', path: '/'))
    @m.get("http://www.bing.com/images/search?q=#{enc}&qft=+filterui:imagesize-medium") do |page|
      page.body.scan(%r{,imgurl:&quot;(.*?)&quot;}).each do |thing|
        links << thing[0].gsub(/"/, '')
      end
    end
    links.sample
  end

  def clean_phrases(phrases)
    phrases.each do |p|
      p.gsub!(/\[.*?\]/, '')
      p.gsub!(/\(.*?\)/, '')
      p.gsub!(/\s+/, ' ')
    end
  end
end
