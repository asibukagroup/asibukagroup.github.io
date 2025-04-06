require "nokogiri"

module Jekyll
  class AmpPage < Page
    def initialize(site:, base:, original:, permalink:, output_dir:)
      @site = site
      @base = base
      @dir  = output_dir
      @name = "index.html"
      process(@name)

      # Copy metadata
      self.data = Jekyll::Utils.deep_merge_hashes(original.data.dup, {
        "layout" => "amp",
        "permalink" => permalink,
        "canonical_url" => original.url
      })

      # Render Markdown to HTML
      markdown_converter = site.find_converter_instance(Jekyll::Converters::Markdown)
      raw_content = original.content
      rendered_html = markdown_converter.convert(raw_content)

      # Apply AMP-specific transformations
      self.content = convert_to_amp(rendered_html)
    end

    private

    def convert_to_amp(html)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)

      # Convert <img> to <amp-img>
      doc.css("img").each do |img|
        amp_img = Nokogiri::XML::Node.new("amp-img", doc)
        img.attributes.each { |name, attr| amp_img[name] = attr.value }
        amp_img["layout"] ||= "responsive"
        amp_img["width"] ||= "600"
        amp_img["height"] ||= "400"
        img.replace(amp_img)
      end

      # Convert <iframe> to <amp-iframe>
      doc.css("iframe").each do |iframe|
        amp_iframe = Nokogiri::XML::Node.new("amp-iframe", doc)
        iframe.attributes.each { |name, attr| amp_iframe[name] = attr.value }
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

      doc.to_html
    end
  end

  class AmpGenerator < Generator
    safe true
    priority :low

    def generate(site)
        # === AMP Pages ===
        site.pages.each do |page|
          next unless page.extname == ".md" || page.ext == ".md"
          next if page.url.include?("/amp/")
      
          amp_permalink = File.join((page.data["permalink"] || page.url).sub(/\/$/, ""), "amp", "/")
          output_dir = page.url == "/" ? "amp" : amp_permalink.sub(/^\//, "").chomp("/")
      
          site.pages << AmpPage.new(
            site: site,
            base: site.source,
            original: page,
            permalink: amp_permalink,
            output_dir: output_dir
          )
        end
      
        # === AMP Posts ===
        site.posts.docs.each do |post|
          next if post.url.include?("/amp/")
      
          amp_permalink = File.join(post.url.sub(/\/$/, ""), "amp", "/")
          output_dir = amp_permalink.sub(/^\//, "").chomp("/")
      
          site.pages << AmpPage.new(
            site: site,
            base: site.source,
            original: post,
            permalink: amp_permalink,
            output_dir: output_dir
          )
        end
      end
  end
end
