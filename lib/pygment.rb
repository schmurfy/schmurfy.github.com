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
    end
  end
  
  def run(content, params={})
    doc = Nokogiri::HTML.fragment(content)
    
    doc.css('code').each do |element|
      content = element.inner_text.split("\n")
      if content[0] =~ /:[a-zA-Z]+/
        language = content[0][1..-1]
        
        highlighted_code = highlight(content[1..-1].join("\n"), language)
        element.replace(highlighted_code)
      end
    end
    
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

