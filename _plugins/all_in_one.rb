require "nokogiri"

module Jekyll
  module HTMLUtils
    def self.minify_html(html)
      doc = Nokogiri::HTML(html)

      # Minify CSS in <style>
      doc.css("style").each do |style|
        style.content = minify_css(style.content)
      end

      # Minify inline styles
      doc.css("*[style]").each do |el|
        el["style"] = minify_css(el["style"])
      end

      # Minify inline JS (skip external scripts and structured data)
      doc.css("script").each do |script|
        next if script["src"]
        next if script["type"] == "application/ld+json"
        script.content = minify_js(script.content)
      end

      # Remove HTML comments
      doc.xpath('//comment()').each(&:remove)

      # Final minification: safe whitespace cleanup
      doc.to_html
         .gsub(/>\s+</, '><')     # Remove whitespace between tags
         .gsub(/\s+/, ' ')        # Collapse whitespace
         .strip
    end

    def self.minify_css(css)
      css.gsub(/\/\*.*?\*\//m, '')             # Remove comments
         .gsub(/\s*([{}:;,])\s*/, '\1')        # Tighten up
         .gsub(/\s+/, ' ')                     # Collapse whitespace
         .gsub(/;\}/, '}')                     # Remove last semicolon
         .strip
    end

    def self.minify_js(js)
      js.gsub(/\/\/.*$/, '')                   # Line comments
        .gsub(/\/\*.*?\*\//m, '')              # Block comments
        .gsub(/[\n\r\t]+/, ' ')                # Newlines
        .gsub(/\s+/, ' ')                      # Collapse whitespace
        .strip
    end
  end

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

      markdown_converter = site.find_converter_instance(Jekyll::Converters::Markdown)

      payload = {
        "page" => original.data,
        "site" => site.site_payload["site"]
      }

      liquid = site.liquid_renderer.file(original.path).parse(original.content)
      rendered_liquid = liquid.render!(payload, registers: { site: site, page: original })

      html = markdown_converter.convert(rendered_liquid)

      self.content = convert_to_amp(html)
    end

    private

    def convert_to_amp(html)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)

      # Convert <img> to <amp-img>
      doc.css("img").each do |img|
        amp_img = Nokogiri::XML::Node.new("amp-img", doc)
        amp_img["src"] = img["data-src"] || img["src"]
        amp_img["alt"] = img["alt"] if img["alt"]
        amp_img["width"] = img["width"] || "600"
        amp_img["height"] = img["height"] || "400"
        amp_img["layout"] = img["layout"] || "responsive"
        img.replace(amp_img)
      end

      # Convert <iframe> to <amp-iframe>
      doc.css("iframe").each do |iframe|
        amp_iframe = Nokogiri::XML::Node.new("amp-iframe", doc)
        %w[src width height layout sandbox].each do |attr|
          amp_iframe[attr] = iframe[attr] if iframe[attr]
        end
        amp_iframe["layout"] ||= "responsive"
        amp_iframe["sandbox"] ||= "allow-scripts allow-same-origin"
        amp_iframe["width"] ||= "600"
        amp_iframe["height"] ||= "400"
        iframe.replace(amp_iframe)
      end

      # Remove disallowed <script> tags
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

      # Pages
      site.pages.each do |page|
        next if page.url.include?("/amp/")
        next unless markdown_exts.include?(page.extname)
        amp_permalink = File.join((page.data["permalink"] || page.url).sub(%r!/$!, ""), "amp", "/")
        output_dir = page.url == "/" ? "amp" : amp_permalink.sub(%r!^/!, "").chomp("/")
        site.pages << AmpPage.new(site: site, base: site.source, original: page, permalink: amp_permalink, output_dir: output_dir)
      end

      # Posts
      site.posts.docs.each do |post|
        next if post.url.include?("/amp/")
        amp_permalink = File.join(post.url.sub(%r!/$!, ""), "amp", "/")
        output_dir = amp_permalink.sub(%r!^/!, "").chomp("/")
        site.pages << AmpPage.new(site: site, base: site.source, original: post, permalink: amp_permalink, output_dir: output_dir)
      end

      # Archives (jekyll-archives plugin)
      if site.respond_to?(:archives)
        site.archives.each do |archive|
          next if archive.url.include?("/amp/")
          amp_permalink = File.join(archive.url.sub(%r!/$!, ""), "amp", "/")
          output_dir = amp_permalink.sub(%r!^/!, "").chomp("/")
          site.pages << AmpPage.new(site: site, base: site.source, original: archive, permalink: amp_permalink, output_dir: output_dir)
        end
      end

      # Categories
      site.categories.each do |category, _|
        page = find_page_by_url(site.pages, "/category/#{category}/")
        next unless page && !page.url.include?("/amp/")
        amp_permalink = File.join(page.url.sub(%r!/$!, ""), "amp", "/")
        output_dir = amp_permalink.sub(%r!^/!, "").chomp("/")
        site.pages << AmpPage.new(site: site, base: site.source, original: page, permalink: amp_permalink, output_dir: output_dir)
      end

      # Tags
      site.tags.each do |tag, _|
        page = find_page_by_url(site.pages, "/tag/#{tag}/")
        next unless page && !page.url.include?("/amp/")
        amp_permalink = File.join(page.url.sub(%r!/$!, ""), "amp", "/")
        output_dir = amp_permalink.sub(%r!^/!, "").chomp("/")
        site.pages << AmpPage.new(site: site, base: site.source, original: page, permalink: amp_permalink, output_dir: output_dir)
      end
    end

    def find_page_by_url(pages, url)
      pages.find { |p| p.url == url || p.url == "#{url}index.html" }
    end
  end

  # Minify all non-AMP pages after rendering
  Jekyll::Hooks.register [:documents, :pages], :post_render do |item|
    next unless item.output_ext == ".html"
    next if item.data["is_amp"]
    item.output = HTMLUtils.minify_html(item.output)
  end
end
