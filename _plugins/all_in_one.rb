require "nokogiri"

module Jekyll
  module HTMLUtils
    def self.minify_html(html)
      # Remove HTML comments
      html = remove_html_comments(html)

      # Parse the HTML with Nokogiri to ensure we handle it correctly.
      doc = Nokogiri::HTML(html)

      # Minify the HTML by removing unnecessary whitespace between tags
      html = doc.to_html

      # Remove spaces and newlines between HTML tags and trim leading/trailing spaces
      html.gsub(/>\s+</, '><')    # Remove whitespace between tags
          .gsub(/\n+/, ' ')       # Remove newlines
          .gsub(/\s{2,}/, ' ')     # Collapse multiple spaces
          .strip                  # Remove leading/trailing spaces
    end

    def self.minify_css(css)
      # Minify the CSS by removing unnecessary spaces, newlines, and comments
      css = remove_css_comments(css)
      css.gsub(/\s+/, ' ')         # Replace multiple spaces with a single space
          .gsub(/\s?([{:};,])\s?/, '\1')  # Remove spaces around CSS punctuation
          .strip
    end

    def self.remove_html_comments(html)
      # Remove all HTML comments using a regular expression
      html.gsub(/<!--.*?-->/m, '')
    end

    def self.remove_css_comments(css)
      # Remove all CSS comments using a regular expression
      css.gsub(/\/\*.*?\*\//m, '')
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

      # Prepare Liquid payload
      payload = {
        "page" => original.data,
        "site" => site.site_payload["site"]
      }

      # Render Liquid
      liquid = site.liquid_renderer.file(original.path).parse(original.content)
      rendered_liquid = liquid.render!(payload, registers: { site: site, page: original })

      # Convert Markdown to HTML
      html = markdown_converter.convert(rendered_liquid)

      # Convert to AMP and apply minification
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
        amp_img["width"] = img["width"] if img["width"]
        amp_img["height"] = img["height"] if img["height"]
        amp_img["layout"] = img["layout"] if img["layout"]

        amp_img["layout"] ||= "responsive"
        amp_img["width"] ||= "600"
        amp_img["height"] ||= "400"

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

      # Remove non-AMP <script> tags
      doc.css("script").each do |script|
        script.remove unless script["src"]&.include?("https://cdn.ampproject.org/")
      end

      # Minify the CSS inside <style> tags
      doc.css("style").each do |style|
        minified_css = HTMLUtils.minify_css(style.content)
        style.content = minified_css
      end

      # Minify HTML content
      minified_html = HTMLUtils.minify_html(doc.to_html)

      # Return the minified HTML (AMP version)
      minified_html
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

  # Minify only non-AMP HTML pages/documents
  Jekyll::Hooks.register [:documents, :pages], :post_render do |item|
    next unless item.output_ext == ".html"
    item.output = HTMLUtils.minify_html(item.output)
  end
end
