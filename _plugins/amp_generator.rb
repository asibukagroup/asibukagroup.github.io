# _plugins/amp_generator.rb

module Jekyll
    class AmpPage < Page
      def initialize(site, original)
        @site = site
        @base = site.source
  
        # Determine target AMP URL path
        original_path = original.url.sub(/^\//, '').sub(/\/$/, '')
        @dir = original_path.empty? ? "amp" : File.join(original_path, "amp")
        @name = "index.html"
  
        self.process(@name)
  
        # Use rendered HTML from original
        self.output = original.output
  
        # Duplicate front matter and override layout
        self.data = original.data.dup
        self.data["layout"] = "amp"
        self.data["canonical_url"] = original.url
      end
  
      # Don't render again — we already have rendered content
      def render_with_liquid?; false; end
      def render(_layouts, _site_payload); end
    end
  
    class AmpGenerator < Generator
      safe true
      priority :lowest
  
      def generate(site)
        site.pages.each do |page|
          # Only for markdown files
          next unless page.extname == ".md" || page.ext == ".md"
  
          # Skip if already an AMP page
          next if page.url.include?("/amp/")
  
          # Create and add AMP version
          site.pages << AmpPage.new(site, page)
        end
      end
    end
  end
  