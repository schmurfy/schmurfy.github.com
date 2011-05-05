module Nanoc3::Filters
  class Redcarpet < Nanoc3::Filter

    def run(content, params={})
      require 'redcarpet'

      extensions = params[:extensions] || []
      
      ::Redcarpet.new(content).to_html
    end

  end
end

Nanoc3::Filter.register '::Nanoc3::Filters::Redcarpet',       :redcarpet
