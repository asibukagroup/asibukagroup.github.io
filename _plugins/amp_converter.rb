module Jekyll
    class AmpConverter < Generator
      safe true
      priority :low
  
      def generate(site)
        site.posts.docs.each do |post|
          post.output = convert_to_amp(post.output)
        end
      end
  
      def convert_to_amp(html)
        return unless html.is_a?(String)
  
        html = html.gsub(/<img(.*?)>/i, '<amp-img\1 layout="responsive"></amp-img>')
        html = html.gsub(/<iframe(.*?)>(.*?)<\/iframe>/im, '<amp-iframe\1 layout="responsive">\2</amp-iframe>')
        html = html.gsub(/<script.*?<\/script>/m, '') # remove all <script> blocks
  
        html
      end
    end
  end
  