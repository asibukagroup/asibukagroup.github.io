require "jekyll"
require "nokogiri"

module Jekyll
  module HTMLUtils
    # Minify HTML without breaking AMP attributes like [class]
    def self.minify_html(html)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)
      html = doc.to_html

      # Remove comments, but preserve AMP attributes like [class]
      html = html.gsub(/<!--.*?-->/m, '')
                 .gsub(/>\s+</, '><')              # Remove whitespace between tags
                 .gsub(/\n+/, ' ')
                 .gsub(/;}/, '}')
                 .gsub(/\/\*.*?\*\//m, '')         # Remove CSS comments

      # Collapse extra spaces outside quotes and brackets (preserve [class]="...")
      html = html.gsub(/("[^"]*"|'[^']*'|\[[^\]]+\])|(\s{2,})/) do
        $1 ? $1 : ' '
      end

      html.strip
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
      @relative_path = original.relative_path

      self.data = original.data.dup
      self.data["layout"] ||= original.data["layout"]
      self.data["permalink"] = permalink
      self.data["canonical_url"] = original.url
      self.data["is_amp"] = true

      html = if original.output&.strip&.length&.positive?
               original.output.to_s
             else
               markdown_converter = site.find_converter_instance(Jekyll::Converters::Markdown)
               payload = { "page" => original.data, "site" => site.site_payload["site"] }

               liquid = site.liquid_renderer.file(original.path).parse(original.content)
               rendered_liquid = liquid.render!(payload, registers: { site: site, page: original })

               markdown_converter.convert(rendered_liquid)
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
    priority :lowest

    def generate(site)
      markdown_exts = [".md", ".markdown"]

      site.pages.each do |page|
        next if page.url.include?("/amp/")
        is_archive = %w[year month day tag category].include?(page.data["type"])
        next unless markdown_exts.include?(page.extname) || is_archive

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

      site.collections.each do |name, collection|
        next if %w[drafts].include?(name)

        collection.docs.each do |doc|
          next if doc.url.include?("/amp/")
          next unless doc.output_ext == ".html" || doc.respond_to?(:output)

          amp_permalink = File.join(doc.url.sub(%r!/$!, ""), "amp", "/")
          output_dir = amp_permalink.sub(%r!^/!, "").chomp("/")

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
  end

  Jekyll::Hooks.register [:pages, :documents], :post_render do |item|
    next unless item.output_ext == ".html"
    item.output = Jekyll::HTMLUtils.minify_html(item.output)
  end
end
