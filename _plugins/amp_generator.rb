module Jekyll
  class AmpPage < Page
    def initialize(site:, base:, original:, permalink:, output_dir:)
      @site = site
      @base = base
      @dir  = output_dir
      @name = "index.html"
      process(@name)
    
      self.data = original.data.dup
      self.data["layout"] = "amp"
      self.data["permalink"] = permalink
      self.data["canonical_url"] = original.url
      self.data["is_amp"] = true
      self.data["url"] = File.join("/", output_dir, @name).gsub(%r!/index\.html$!, "/")
    
      markdown_converter = site.find_converter_instance(Jekyll::Converters::Markdown)
    
      payload = {
        "page" => original.data,
        "site" => site.site_payload["site"]
      }
    
      liquid = site.liquid_renderer.file(original.path).parse(original.content)
      rendered_liquid = liquid.render!(payload, registers: { site: site, page: original })
    
      self.content = markdown_converter.convert(rendered_liquid)
    end    
  end

  class AmpGenerator < Generator
    safe true
    priority :low

    def generate(site)
      markdown_exts = [".md", ".markdown"]

      # Pages
      site.pages.each do |page|
        next if page.url.include?("/amp/")
        next unless markdown_exts.include?(page.extname)

        amp_permalink = File.join((page.data["permalink"] || page.url).sub(%r!/$!, ""), "amp", "/")
        output_dir = page.url == "/" ? "amp" : amp_permalink.sub(%r!^/!, "").chomp("/")

        site.pages << AmpPage.new(
          site: site,
          base: site.source,
          original: page,
          permalink: amp_permalink,
          output_dir: output_dir
        )
      end

      # Posts
      site.posts.docs.each do |post|
        next if post.url.include?("/amp/")

        amp_permalink = File.join(post.url.sub(%r!/$!, ""), "amp", "/")
        output_dir = amp_permalink.sub(%r!^/!, "").chomp("/")

        site.pages << AmpPage.new(
          site: site,
          base: site.source,
          original: post,
          permalink: amp_permalink,
          output_dir: output_dir
        )
      end

      # Archives from jekyll-archives
      if site.respond_to?(:archives)
        site.archives.each do |archive|
          next if archive.url.include?("/amp/")

          amp_permalink = File.join(archive.url.sub(%r!/$!, ""), "amp", "/")
          output_dir = amp_permalink.sub(%r!^/!, "").chomp("/")

          site.pages << AmpPage.new(
            site: site,
            base: site.source,
            original: archive,
            permalink: amp_permalink,
            output_dir: output_dir
          )
        end
      end

      # Categories
      site.categories.each do |category, posts|
        page = find_page_by_url(site.pages, "/category/#{category}/")
        next unless page
        next if page.url.include?("/amp/")

        amp_permalink = File.join(page.url.sub(%r!/$!, ""), "amp", "/")
        output_dir = amp_permalink.sub(%r!^/!, "").chomp("/")

        site.pages << AmpPage.new(
          site: site,
          base: site.source,
          original: page,
          permalink: amp_permalink,
          output_dir: output_dir
        )
      end

      # Tags
      site.tags.each do |tag, posts|
        page = find_page_by_url(site.pages, "/tag/#{tag}/")
        next unless page
        next if page.url.include?("/amp/")

        amp_permalink = File.join(page.url.sub(%r!/$!, ""), "amp", "/")
        output_dir = amp_permalink.sub(%r!^/!, "").chomp("/")

        site.pages << AmpPage.new(
          site: site,
          base: site.source,
          original: page,
          permalink: amp_permalink,
          output_dir: output_dir
        )
      end
    end

    def find_page_by_url(pages, url)
      pages.find { |page| page.url == url || page.url == "#{url}index.html" }
    end
  end
end
