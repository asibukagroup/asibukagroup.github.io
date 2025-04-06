# _plugins/amp_generator.rb

module Jekyll
  class AmpPage < Page
    def initialize(site, base, original, permalink, output_dir)
      @site = site
      @base = base
      @dir  = output_dir
      @name = "index.html"
      self.process(@name)

      # Render original if not already rendered
      original.render({}, site.site_payload)

      # Use rendered HTML as content
      self.content = original.output
      self.data = original.data.dup

      # Set AMP-specific front matter
      self.data["layout"] = "amp"
      self.data["permalink"] = permalink
      self.data["canonical_url"] = original.url
    end
  end

  class AmpGenerator < Generator
    safe true
    priority :lowest  # After site reads files, before write phase

    def generate(site)
      # === PAGES ===
      site.pages.each do |page|
        next unless page.extname == ".md" || page.ext == ".md"
        next if page.url.include?("/amp/")

        amp_permalink = File.join((page.data["permalink"] || page.url).sub(/\/$/, ""), "amp", "/")
        output_dir = page.url == "/" ? "amp" : amp_permalink.sub(/^\//, "").sub(/index\.html$/, "")

        site.pages << AmpPage.new(site, site.source, page, amp_permalink, output_dir)
      end

      # === POSTS ===
      site.posts.docs.each do |post|
        next if post.url.include?("/amp/")

        amp_permalink = File.join(post.url.sub(/\/$/, ""), "amp", "/")
        output_dir = amp_permalink.sub(/^\//, "").sub(/index\.html$/, "")

        site.pages << AmpPage.new(site, site.source, post, amp_permalink, output_dir)
      end
    end
  end
end
