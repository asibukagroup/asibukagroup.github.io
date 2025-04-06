module Jekyll
    class AmpPage < Page
      def initialize(site, base, page, rendered_content)
        @site = site
        @base = base
  
        # Target: /:title/amp/index.html
        original_path = page.url.sub(/^\//, '').sub(/\/$/, '')
        @dir = File.join(original_path, "amp")
        @name = "index.html"
  
        self.process(@name)
  
        # Duplicate data and rendered HTML
        self.content = rendered_content
        self.data = page.data.dup
  
        # Override layout to use AMP
        self.data["layout"] = "amp"
        self.data["canonical_url"] = page.url
      end
    end
  
    class AmpGenerator < Generator
      safe true
      priority :low
  
      def generate(site)
        pages = site.pages.select { |p| p.extname == ".md" || p.ext == ".md" }
  
        pages.each do |page|
          next if page.url.include?("/amp/")
  
          # Render the original page using its layout
          layout = site.layouts[page.data["layout"] || "default"]
          payload = site.site_payload.merge({ "page" => page.data, "content" => page.content })
          rendered_content = layout.render(payload, site.site_payload)
  
          # Generate AMP version with the rendered content
          amp_page = AmpPage.new(site, site.source, page, rendered_content)
          site.pages << amp_page
  
          # Make sure original has a default layout if none set
          page.data["layout"] ||= "default"
        end
      end
    end
  end