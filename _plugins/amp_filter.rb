module Jekyll
    module AmpFilter
      def ampify(html)
        # Convert images to AMP format
        html.gsub!(/<img(.*?)>/, '<amp-img\1 layout="responsive"></amp-img>')
  
        # Remove JavaScript (AMP doesn't support it)
        html.gsub!(/<script(.*?)<\/script>/m, '')
  
        # Remove all inline styles
        html.gsub!(/ style="[^"]*"/, '')
  
        html
      end
    end
  end
  
  Liquid::Template.register_filter(Jekyll::AmpFilter)