require "nokogiri"

module Jekyll
  module HTMLUtils
    def self.minify_html(html)
      doc = Nokogiri::HTML(html)
      html = doc.to_html

      html.gsub(/>\s+</, '><')       # Remove whitespace between tags
          .gsub(/\n+/, ' ')          # Remove newlines
          .gsub(/\s{2,}/, ' ')       # Collapse multiple spaces
          .gsub(/<!--.*?-->/m, '')   # Remove HTML comments
          .strip
    end

    def self.minify_css(css)
      return "" if css.nil? || css.empty?
    
      css = css.gsub(/\/\*[^*]*\*+([^/*][^*]*\*+)*\//, '') # Remove block comments
               .gsub(/\s*([{}:;,])\s*/, '\1')              # Remove space around symbols
               .gsub(/;}/, '}')                            # Remove trailing semicolons
               .gsub(/\s+/, ' ')                           # Collapse spaces
               .strip
    end

    def self.minify_js(js)
      js.gsub(/\/\/.*$/, '')         # Remove single-line comments
         .gsub(/\/\*.*?\*\//m, '')   # Remove multi-line comments
         .gsub(/\s+/, ' ')           # Collapse whitespace
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
      payload = { "page" => original.data, "site" => site.site_payload["site"] }

      liquid = site.liquid_renderer.file(original.path).parse(original.content)
      rendered_liquid = liquid.render!(payload, registers: { site: site, page: original })

      html = markdown_converter.convert(rendered_liquid)
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
        if script["src"]&.include?("https://cdn.ampproject.org/") # Do not alter AMP CDN scripts
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

  class AmpGenerator < Generator
    safe true
    priority :low

    def generate(site)
      markdown_exts = [".md", ".markdown"]

      # Automatically generate AMP versions for all collections except for posts and pages
      (site.collections.keys - %w[posts pages]).each do |collection_name|
        collection = site.collections[collection_name]
        next unless collection.respond_to?(:docs)

        collection.docs.each do |doc|
          next if doc.url.include?("/amp/") # Skip if already AMP version
          amp_permalink = File.join(doc.url.sub(%r!/$!, ""), "amp", "/")
          output_dir = amp_permalink.sub(%r!^/!, "").chomp("/")
          site.pages << AmpPage.new(site: site, base: site.source, original: doc, permalink: amp_permalink, output_dir: output_dir)
        end
      end

      site.posts.docs.each do |post|
        next if post.url.include?("/amp/") # Skip AMP versions
        amp_permalink = File.join(post.url.sub(%r!/$!, ""), "amp", "/")
        output_dir = amp_permalink.sub(%r!^/!, "").chomp("/")
        site.pages << AmpPage.new(site: site, base: site.source, original: post, permalink: amp_permalink, output_dir: output_dir)
      end

      site.pages.each do |page|
        next if page.url.include?("/amp/") # Skip AMP versions
        next unless markdown_exts.include?(page.extname) # Only process markdown files

        amp_permalink = File.join((page.data["permalink"] || page.url).sub(%r!/$!, ""), "amp", "/")
        output_dir = page.url == "/" ? "amp" : amp_permalink.sub(%r!^/!, "").chomp("/")
        site.pages << AmpPage.new(site: site, base: site.source, original: page, permalink: amp_permalink, output_dir: output_dir)
      end
    end
  end

  # Minify HTML output for all non-AMP pages
  Jekyll::Hooks.register [:documents, :pages], :post_render do |item|
    next unless item.output_ext == ".html"
    next if item.data["is_amp"] # Skip AMP pages
    item.output = Jekyll::HTMLUtils.minify_html(item.output)
  end
end
