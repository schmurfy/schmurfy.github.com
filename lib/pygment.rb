# encoding: utf-8

require 'nokogiri'
# require 'hpricot'

class Pygment < Nanoc3::Filter
  identifier :pygment
  type :text
  
  def highlight(code, language, params={})
    IO.popen("pygmentize -l #{language} -f html -O encoding=utf8", "r+") do |io|
      # io.write(" \n#{code}")
      io.write(code)
      io.close_write
      highlighted_code = io.read
      
      return highlighted_code
      # doc = Nokogiri::HTML.fragment(highlighted_code)
      # return doc.xpath('./div[@class="highlight"]/pre').inner_html
    end
  end
  
  def run(content, params={})    
    # doc = Hpricot(content)
    # 
    # doc.search("pre[@class*='language-']") do |element|
    #   # Get language
    #   p element['class']
    #   match = element['class'].match(/(^| )language-([^ ]+)/)
    #   next if match.nil?
    #   language = match[2]
    #   
    #   highlighted_code = highlight(element.inner_text, language)
    #   element.inner_html = highlighted_code
    # end
    # 
    # doc.to_s
    
    doc = Nokogiri::HTML.fragment(content)
    doc.css('pre[class*="language-"]').each do |element|
      # Get language
      match = element['class'].match(/(^| )language-([^ ]+)/)
      next if match.nil?
      language = match[2]
      
      highlighted_code = highlight(element.inner_text, language)      
      # element.inner_html = highlighted_code
      element.replace(highlighted_code)
    end
    
    doc.to_html(:encoding => 'UTF-8')
  end

end

