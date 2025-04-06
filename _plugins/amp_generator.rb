# _plugins/amp_generator.rb

module Jekyll
    class AmpPage < Page
      def initialize(site, original)
        @site = site
        @base = site.source
  
        # Set output path: /:title/amp/index.html
        original_path = original.url.sub(/^\//, '').sub(/\/$/, '')
        @dir = File.join(original_path, "amp")
        @name = "index.html"
  
        self.process(@name)
  
        # Copy final rendered HTML content
        self.output = original.output
  
        # Clone front matter and override layout
        self.data = original.data.dup
        self.data["layout"] = "amp"
        self.data["canonical_url"] = original.url
      end
  
      # Tell Jekyll not to re-render this page again
      def render_with_liquid?; false; end
      def render(layouts, site_payload); end
    end
  
    class AmpGenerator < Generator
      safe true
      priority :lowest
  
      def generate(site)
        site.pages.each do |page|
          next if page.url.include?("/amp/")
          next unless page.extname == ".md" || page.ext == ".md"
  
          site.pages << AmpPage.new(site, page)
  
          # Ensure original page has a layout
          page.data["layout"] ||= "default"
        end
      end
    end
  end
  