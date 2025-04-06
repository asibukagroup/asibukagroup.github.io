# _plugins/amp_generator.rb

module Jekyll
    class AmpPage < Page
        def initialize(site, original)
            @site = site
            @base = site.source
            original_path = original.url.sub(/^\//, '').sub(/\/$/, '')
            @dir = original_path.empty? ? "amp" : File.join(original_path, "amp")
            @name = "index.html"
            self.process(@name)
            self.output = original.output
            self.data = original.data.dup
            self.data["layout"] = "amp"
            self.data["canonical_url"] = original.url
        end
        def render_with_liquid?; false; end
      def render(_layouts, _site_payload); end
    end
    class AmpGenerator < Generator
        safe true
        priority :lowest
        def generate(site)
            site.pages.each do |page|
                next unless page.extname == ".md" || page.ext == ".md"
                next if page.url.include?("/amp/")
                site.pages << AmpPage.new(site, page)
            end
        end
    end
end
  