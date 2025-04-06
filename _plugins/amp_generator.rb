# _plugins/amp_generator.rb

module Jekyll
    class AmpFile < Page
      def initialize(site, base, original)
        @site = site
        @base = base
  
        # Get the file name without extension (e.g., 'about')
        title = File.basename(original.path, File.extname(original.path))
  
        # Output dir: same as original + /amp/
        @dir = File.join(File.dirname(original.path.sub(site.source, '')), title, 'amp')
        @name = 'index.html'
  
        self.process(@name)
  
        # Copy content and front matter from the original
        self.content = original.content
        self.data = original.data.dup
  
        # Override layout and permalink
        self.data['layout'] = 'amp'
        self.data['permalink'] = "/#{title}/amp/"
      end
    end
  
    class AmpGenerator < Generator
      safe true
      priority :low
  
      def generate(site)
        site.pages.each do |page|
          next unless page.extname == '.md' || page.ext == '.md'
          next if page.url.include?('/amp/')
  
          site.pages << AmpFile.new(site, site.source, page)
        end
      end
    end
  end
  