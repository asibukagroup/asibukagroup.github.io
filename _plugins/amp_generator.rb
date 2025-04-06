require "nokogiri"

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

      markdown_converter = site.find_converter_instance(Jekyll::Converters::Markdown)
      rendered_html = markdown_converter.convert(original.content)

      self.content = convert_to_amp(rendered_html)
    end

    private

    def convert_to_amp(html)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)

      doc.css("img").each do |img|
        amp_img = Nokogiri::XML::Node.new("amp-img", doc)
        img.attributes.each { |name, attr| amp_img[name] = attr.value }
        amp_img["layout"] ||= "responsive"
        amp_img["width"] ||= "600"
        amp_img["height"] ||= "400"
        img.replace(amp_img)
      end

      doc.css("iframe").each do |iframe|
        amp_iframe = Nokogiri::XML::Node.new("amp-iframe", doc)
        iframe.attributes.each { |name, attr| amp_iframe[name] = attr.value }
        amp_iframe["layout"] ||= "responsive"
        amp_iframe["sandbox"] ||= "allow-scripts allow-same-origin"
        amp_iframe["width"] ||= "600"
        amp_iframe["height"] ||= "400"
        iframe.replace(amp_iframe)
      end

      doc.css("script").each do |script|
        script.remove unless script["src"]&.include?("https://cdn.ampproject.org/")
      end

      doc.to_html
    end
  end

  class AmpGenerator < Generator
    safe true
    priority :low

    def generate(site)
      markdown_exts = [".md", ".markdown"]

      # --- Regular Pages ---
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

      # --- Posts ---
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

      # --- Archives from jekyll-archives ---
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

      # --- Categories ---
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

      # --- Tags ---
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

    # Helper to find generated archive pages by URL
    def find_page_by_url(pages, url)
      pages.find { |page| page.url == url || page.url == "#{url}index.html" }
    end
  end
end