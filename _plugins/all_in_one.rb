require "jekyll"
require "nokogiri"

# Utility module for HTML, CSS, and JS minification
module Jekyll
  module HTMLUtils
    def self.minify_html(html)
      doc = Nokogiri::HTML(html)
      html = doc.to_html

      html.gsub(/>\s+</, '><')       # Remove whitespace between tags
          .gsub(/\n+/, ' ')          # Remove newlines
          .gsub(/\s{2,}/, ' ')       # Collapse multiple spaces
          .gsub(/<!--.*?-->/m, '')   # Remove HTML comments
          .gsub(/;}/, '}')           # Remove unnecessary semicolons
          .gsub(/\/\*.*?\*\//m, '')  # Remove CSS comments
          .gsub(/\s+/, ' ')          # Collapse all whitespace
          .strip
    end

    def self.minify_css(css)
      css.gsub(/\/\*.*?\*\//m, '')
         .gsub(/\s+/, ' ')
         .gsub(/\s*([{:;}])\s*/, '\1')
         .gsub(/;}/, '}')
         .strip
    end

    def self.minify_js(js)
      js.gsub(/\/\/.*$/, '')
         .gsub(/\/\*.*?\*\//m, '')
         .gsub(/\s+/, ' ')
         .strip
    end
  end

  # Custom Page class for AMP pages
  class AmpPage < Page
    def initialize(site:, base:, original:, permalink:, output_dir:)
      @site = site
      @base = base
      @dir  = output_dir
      @name = "index.html"
      process(@name)

      self.data = original.data.dup
      self.data["layout"] = original.data["layout"] # Use same layout as original
      self.data["permalink"] = permalink
      self.data["canonical_url"] = original.url
      self.data["is_amp"] = true

      html = if original.output.to_s.strip != ""
               original.output.to_s
             else
               payload = {
                 "page" => original.data,
                 "site" => site.site_payload["site"]
               }

               template = site.liquid_renderer.file(original.path).parse(original.content.to_s)
               rendered = template.render!(payload, registers: { site: site, page: original })

               markdown_converter = site.find_converter_instance(Jekyll::Converters::Markdown)
               markdown_converter.convert(rendered)
             end

      self.content = convert_to_amp(html)
    end

    private

    def convert_to_amp(html)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)

      doc.css("img").each do |img|
        amp_img = Nokogiri::XML::Node.new("amp-img", doc)
        amp_img["src"] = img["data-src"] || img["src"]
        amp_img["alt"] = img["alt"] if img["alt"]
        amp_img["width"] = img["width"] || "600"
        amp_img["height"] = img["height"] || "400"
        amp_img["layout"] = img["layout"] || "responsive"
        img.replace(amp_img)
      end

      doc.css("iframe").each do |iframe|
        amp_iframe = Nokogiri::XML::Node.new("amp-iframe", doc)
        %w[src width height layout sandbox].each { |attr| amp_iframe[attr] = iframe[attr] if iframe[attr] }
        amp_iframe["width"] ||= "600"
        amp_iframe["height"] ||= "400"
        amp_iframe["layout"] ||= "responsive"
        amp_iframe["sandbox"] ||= "allow-scripts allow-same-origin"
        iframe.replace(amp_iframe)
      end

      doc.css("script").each do |script|
        if script["src"]&.include?("https://cdn.ampproject.org/")
          next
        elsif script.children.any?
          cleaned_js = HTMLUtils.minify_js(script.content)
          script.content = cleaned_js
        else
          script.remove
        end
      end

      doc.css("style").each do |style|
        style.content = HTMLUtils.minify_css(style.content)
      end

      HTMLUtils.minify_html(doc.to_html)
    end
  end

  # Main generator class for AMP pages
  class AmpGenerator < Generator
    safe true
    priority :low

    def generate(site)
      markdown_exts = [".md", ".markdown"]

      site.pages.each do |page|
        next if page.url.include?("/amp/")
        next unless markdown_exts.include?(page.extname)

        amp_permalink = File.join((page.data["permalink"] || page.url).sub(%r!/$!, ""), "amp", "/")
        output_dir = page.url == "/" ? "amp" : amp_permalink.sub(%r!^/!, "").chomp("/")

        site.pages << AmpPage.new(site: site, base: site.source, original: page, permalink: amp_permalink, output_dir: output_dir)
      end

      site.posts.docs.each do |post|
        next if post.url.include?("/amp/")

        amp_permalink = File.join(post.url.sub(%r!/$!, ""), "amp", "/")
        output_dir = amp_permalink.sub(%r!^/!, "").chomp("/")

        site.pages << AmpPage.new(site: site, base: site.source, original: post, permalink: amp_permalink, output_dir: output_dir)
      end

      site.collections.each do |name, collection|
        next if ["posts", "drafts", "pages"].include?(name)

        collection.docs.each do |doc|
          next if doc.url.include?("/amp/")
          amp_permalink = File.join(doc.url.sub(%r!/$!, ""), "amp", "/")
          output_dir = amp_permalink.sub(%r!^/!, "").chomp("/")

          site.pages << AmpPage.new(site: site, base: site.source, original: doc, permalink: amp_permalink, output_dir: output_dir)
        end
      end

      site.categories.each do |category, _|
        url = "/kategori/#{category.downcase}/"
        add_custom_amp_page(site, url)
      end

      site.tags.each do |tag, _|
        url = "/tag/#{tag.downcase}/"
        add_custom_amp_page(site, url)
      end
    end

    def add_custom_amp_page(site, url)
      page = site.pages.find { |p| p.url == url || p.url == "#{url}index.html" }
      return unless page && !page.url.include?("/amp/")

      amp_permalink = File.join(url.sub(%r!/$!, ""), "amp", "/")
      output_dir = amp_permalink.sub(%r!^/!, "").chomp("/")

      site.pages << AmpPage.new(site: site, base: site.source, original: page, permalink: amp_permalink, output_dir: output_dir)
    end
  end

  # Post-render hook: generate AMP for jekyll-archives
  Jekyll::Hooks.register :pages, :post_render do |page|
    next if page.data["is_amp"]
    next unless page.data["jekyll-archives"]
    next if page.url.include?("/amp/")

    amp_permalink = File.join(page.url.sub(%r!/$!, ""), "amp", "/")
    output_dir = amp_permalink.sub(%r!^/!, "").chomp("/")

    amp_page = AmpPage.new(
      site: page.site,
      base: page.site.source,
      original: page,
      permalink: amp_permalink,
      output_dir: output_dir
    )

    # Use rendered HTML output directly
    amp_page.content = amp_page.send(:convert_to_amp, page.output.to_s)
    page.site.pages << amp_page
  end

  # Global hook: minify HTML for all pages and documents
  Jekyll::Hooks.register [:pages, :documents], :post_render do |item|
    next unless item.output_ext == ".html"
    item.output = Jekyll::HTMLUtils.minify_html(item.output)
  end
end
