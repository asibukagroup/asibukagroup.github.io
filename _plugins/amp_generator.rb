# _plugins/amp_generator.rb

module Jekyll
    class AmpFile < Page
      def initialize(site, base, original)
        @site = site
        @base = base
  
        # Get original permalink or URL
        original_permalink = original.data['permalink'] || original.url
  
        # Build AMP permalink
        amp_permalink = File.join(original_permalink.sub(/\/$/, ''), 'amp', '/')
  
        # Determine output dir
        if original.url == '/' || original.relative_path == 'index.md'
          @dir = 'amp'
        else
          @dir = amp_permalink.sub(/^\//, '').sub(/index\.html$/, '')
        end
  
        @name = 'index.html'
        self.process(@name)
  
        # Copy content and front matter
        self.content = original.content
        self.data = original.data.dup
  
        # Set AMP-specific front matter
        self.data['layout'] = 'amp'
        self.data['permalink'] = amp_permalink
        self.data['canonical_url'] = original.url
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
  