require "jekyll"
require "nokogiri"

module Jekyll
  module HTMLUtils
    def self.minify_html(html)
      doc = Nokogiri::HTML(html)
      html = doc.to_html
      html.gsub(/>\s+</, '><')
          .gsub(/\n+/, '')
          .gsub(/\s{2,}/, ' ')
          .gsub(/<!--.*?-->/m, '')
          .gsub(/;}/, '}')
          .gsub(/ { /, '{')
          .gsub(/\/\*.*?\*\//m, '')
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

  class AmpPage < Page
    def initialize(site:, base:, original:, permalink:, output_dir:)
      @site = site
      @base = base
      @dir  = output_dir
      @name = "index.html"
      process(@name)

      @relative_path = original.respond_to?(:relative_path) ? original.relative_path : original.path

      self.data = original.data.dup
      self.data["layout"] ||= original.data["layout"]
      self.data["permalink"] = permalink
      self.data["canonical_url"] = original.url
      self.data["is_amp"] = true

      html = original.output.to_s
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
          script.content = HTMLUtils.minify_js(script.content)
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
    safe false
    priority :low

    def generate(site)
      markdown_exts = [".md", ".markdown"]

      all_docs = site.pages + site.posts.docs + site.collections.flat_map { |_, c| c.docs }

      all_docs.each do |doc|
        next if doc.url.include?("/amp/")
        next unless doc.respond_to?(:output) && doc.output
        next unless markdown_exts.include?(File.extname(doc.path)) || doc.data["type"]

        amp_permalink = File.join((doc.data["permalink"] || doc.url).sub(%r!/$!, ""), "amp", "/")
        output_dir = doc.url == "/" ? "amp" : amp_permalink.sub(%r!^/!, "").chomp("/")

        site.pages << AmpPage.new(
          site: site,
          base: site.source,
          original: doc,
          permalink: amp_permalink,
          output_dir: output_dir
        )
      end
    end
  end

  # Hook: Minify regular HTML (non-AMP) after render
  Jekyll::Hooks.register [:pages, :documents], :post_render do |item|
    next unless item.output_ext == ".html"
    next if item.data["is_amp"]
    item.output = Jekyll::HTMLUtils.minify_html(item.output)
  end
end
