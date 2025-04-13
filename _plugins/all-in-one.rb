require "nokogiri"
require "brotli"
require "zlib"
require "stringio"
require "fileutils"
require "mini_magick"

module Jekyll
  module HTMLUtils
    def self.minify_html(html)
      html = html.gsub(/<!--.*?-->/m, "")               # Remove HTML comments
      html = html.gsub(/>\s+</, '><')                   # Collapse whitespace

      # Minify inline CSS
      html = html.gsub(/<style\b[^>]*>(.*?)<\/style>/m) do
        content = $1.gsub(/\/\*.*?\*\//m, "")
                    .gsub(/\s+/, " ")
                    .gsub(/\s*([{}:;,])\s*/, '\1')
                    .strip
        "<style>#{content}</style>"
      end

      # Minify inline JS
      html = html.gsub(/<script(?![^>]*\bsrc=)[^>]*>(.*?)<\/script>/m) do
        content = $1.gsub(/\/\/[^\n]*/, "")
                    .gsub(/\/\*.*?\*\//m, "")
                    .gsub(/\s+/, " ")
                    .gsub(/\s*([{}();=:+,\-*\/<>])\s*/, '\1')
                    .strip
        "<script>#{content}</script>"
      end

      html.strip
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

      doc.css("img").each do |img|
        src = img["data-src"] || img["src"]
        webp_src = generate_webp(src)

        amp_img = Nokogiri::XML::Node.new("amp-img", doc)
        amp_img["src"] = webp_src || src
        amp_img["alt"] = img["alt"] if img["alt"]
        amp_img["width"] = img["width"] || "600"
        amp_img["height"] = img["height"] || "400"
        amp_img["layout"] = img["layout"] || "responsive"
        img.replace(amp_img)
      end

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

      doc.css("script").each do |script|
        script.remove unless script["src"]&.include?("https://cdn.ampproject.org/")
      end

      doc.to_html
    end

    def generate_webp(src)
      return unless src && src =~ /\.(jpe?g|png)$/i

      input_path = File.join(@site.dest, src)
      return unless File.exist?(input_path)

      webp_path = src.sub(/\.(jpe?g|png)$/i, ".webp")
      output_path = File.join(@site.dest, webp_path)

      FileUtils.mkdir_p(File.dirname(output_path))

      unless File.exist?(output_path)
        image = MiniMagick::Image.open(input_path)
        image.format("webp")
        image.write(output_path)
      end

      webp_path
    rescue
      nil
    end
  end

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

      if site.respond_to?(:archives)
        site.archives.each do |archive|
          next if archive.url.include?("/amp/")
          amp_permalink = File.join(archive.url.sub(%r!/$!, ""), "amp", "/")
          output_dir = amp_permalink.sub(%r!^/!, "").chomp("/")

          site.pages << AmpPage.new(site: site, base: site.source, original: archive, permalink: amp_permalink, output_dir: output_dir)
        end
      end

      site.categories.each do |category, _|
        page = find_page_by_url(site.pages, "/category/#{category}/")
        next unless page
        next if page.url.include?("/amp/")

        amp_permalink = File.join(page.url.sub(%r!/$!, ""), "amp", "/")
        output_dir = amp_permalink.sub(%r!^/!, "").chomp("/")

        site.pages << AmpPage.new(site: site, base: site.source, original: page, permalink: amp_permalink, output_dir: output_dir)
      end

      site.tags.each do |tag, _|
        page = find_page_by_url(site.pages, "/tag/#{tag}/")
        next unless page
        next if page.url.include?("/amp/")

        amp_permalink = File.join(page.url.sub(%r!/$!, ""), "amp", "/")
        output_dir = amp_permalink.sub(%r!^/!, "").chomp("/")

        site.pages << AmpPage.new(site: site, base: site.source, original: page, permalink: amp_permalink, output_dir: output_dir)
      end
    end

    def find_page_by_url(pages, url)
      pages.find { |page| page.url == url || page.url == "#{url}index.html" }
    end
  end

  # Minify HTML after rendering
  Jekyll::Hooks.register [:documents, :pages], :post_render do |item|
    next unless item.output_ext == ".html"
    item.output = HTMLUtils.minify_html(item.output)
  end

  # Compress output to Brotli and Gzip
  Jekyll::Hooks.register [:documents, :pages], :post_write do |item|
    path = item.destination(item.site.dest)
    ext = File.extname(path)
    next unless File.exist?(path) && %w[.html .css .js].include?(ext)

    raw = File.binread(path)

    # Brotli
    brotli = Brotli.deflate(raw)
    File.write("#{path}.br", brotli, mode: "wb")

    # Gzip
    gz = StringIO.new
    Zlib::GzipWriter.wrap(gz) { |gz_io| gz_io.write(raw) }
    File.write("#{path}.gz", gz.string, mode: "wb")
  end
end