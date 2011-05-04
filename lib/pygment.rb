# encoding: utf-8

require 'nokogiri'

class Pygment < Nanoc3::Filter
  identifier :pygment
  type :text
  
  def highlight(code, language, params={})
    IO.popen("pygmentize -l #{language} -f html -O encoding=utf8", "r+") do |io|
      io.write(code)
      io.close_write
      highlighted_code = io.read
      
      return highlighted_code
    end
  end
  
  def run(content, params={})
    
    # Colorize
    # doc = Nokogiri::HTML.fragment(content)
    doc = Nokogiri::HTML::Document.parse(content)
    doc.css('pre[class*="language-"]').each do |element|
      # Get language
      match = element['class'].match(/(^| )language-([^ ]+)/)
      next if match.nil?
      language = match[2]
      
      highlighted_code = highlight(element.inner_text, language)      
      element.inner_html = highlighted_code
    end
    
    doc.to_s
  end

end

