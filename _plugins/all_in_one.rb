require "jekyll"
require "nokogiri"

# Utility module for HTML, CSS, and JS minification
module Jekyll
  module HTMLUtils
    # Minify general HTML
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

    # Minify CSS code
    def self.minify_css(css)
      css.gsub(/\/\*.*?\*\//m, '')           # Remove comments
         .gsub(/\s+/, ' ')                   # Collapse whitespace
         .gsub(/\s*([{:;}])\s*/, '\1')       # Remove spaces around symbols
         .gsub(/;}/, '}')                    # Remove semicolons before }
         .strip
    end

    # Minify JavaScript code
    def self.minify_js(js)
      js.gsub(/\/\/.*$/, '')                 # Remove single-line comments
         .gsub(/\/\*.*?\*\//m, '')           # Remove multi-line comments
         .gsub(/\s+/, ' ')                   # Collapse whitespace
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
      process(@name) # Sets filename

      # Clone original page's data
      self.data = original.data.dup
      self.data["layout"] = original.data["layout"]  # Use same layout as original
      self.data["permalink"] = permalink             # Set AMP permalink
      self.data["canonical_url"] = original.url      # Set canonical reference
      self.data["is_amp"] = true                     # Flag this as AMP

      # Determine HTML content source (from output or Markdown + Liquid)
      html = if original.content.strip.empty? || original.output.to_s.strip != ''
               original.output.to_s
             else
               markdown_converter = site.find_converter_instance(Jekyll::Converters::Markdown)
               payload = { "page" => original.data, "site" => site.site_payload["site"] }

               liquid = site.liquid_renderer.file(original.path).parse(original.content)
               rendered_liquid = liquid.render!(payload, registers: { site: site, page: original })

               markdown_converter.convert(rendered_liquid)
             end

      # Transform content into AMP format
      self.content = convert_to_amp(html)
    end

    private

    # Perform AMP-specific HTML transformations
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
        %w[src width height layout sandbox].each { |attr| amp_iframe[attr] = iframe[attr] if iframe[attr] }
        amp_iframe["width"] ||= "600"
        amp_iframe["height"] ||= "400"
        amp_iframe["layout"] ||= "responsive"
        amp_iframe["sandbox"] ||= "allow-scripts allow-same-origin"
        iframe.replace(amp_iframe)
      end

      # Remove or clean up <script> tags
      doc.css("script").each do |script|
        if script["src"]&.include?("https://cdn.ampproject.org/")
          next # Keep AMP scripts
        elsif script.children.any?
          cleaned_js = HTMLUtils.minify_js(script.content)
          script.content = cleaned_js
        else
          script.remove # Remove non-AMP scripts
        end
      end

      # Minify CSS in <style> tags
      doc.css("style").each do |style|
        style.content = HTMLUtils.minify_css(style.content)
      end

      # Return fully minified AMP-compatible HTML
      HTMLUtils.minify_html(doc.to_html)
    end
  end

  # Main generator class that duplicates content as AMP pages
  class AmpGenerator < Generator
    safe true
    priority :low

    def generate(site)
      markdown_exts = [".md", ".markdown"]

      # Process regular pages (e.g., index.md, about.md)
      site.pages.each do |page|
        next if page.url.include?("/amp/")
        next unless markdown_exts.include?(page.extname)

        amp_permalink = File.join((page.data["permalink"] || page.url).sub(%r!/$!, ""), "amp", "/")
        output_dir = page.url == "/" ? "amp" : amp_permalink.sub(%r!^/!, "").chomp("/")

        site.pages << AmpPage.new(site: site, base: site.source, original: page, permalink: amp_permalink, output_dir: output_dir)
      end

      # Process blog posts
      site.posts.docs.each do |post|
        next if post.url.include?("/amp/")
        amp_permalink = File.join(post.url.sub(%r!/$!, ""), "amp", "/")
        output_dir = amp_permalink.sub(%r!^/!, "").chomp("/")

        site.pages << AmpPage.new(site: site, base: site.source, original: post, permalink: amp_permalink, output_dir: output_dir)
      end

      # Process all custom collections except posts, drafts, pages
      site.collections.each do |name, collection|
        next if ["posts", "drafts", "pages"].include?(name)

        collection.docs.each do |doc|
          next if doc.url.include?("/amp/") || !markdown_exts.include?(doc.extname)

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

      # Generate AMP versions for custom category archive pages
      site.categories.each do |category, _|
        url = "/kategori/#{category.downcase}/"
        add_custom_amp_page(site, url)
      end

      # Generate AMP versions for custom tag archive pages
      site.tags.each do |tag, _|
        url = "/tag/#{tag.downcase}/"
        add_custom_amp_page(site, url)
      end
    end

    # Helper to generate AMP page for a category or tag archive
    def add_custom_amp_page(site, url)
      page = site.pages.find { |p| p.url == url || p.url == "#{url}index.html" }
      return unless page && !page.url.include?("/amp/")

      # Render the archive page with posts
      posts_list = "<ul class='amp-post-list'>"
      posts = site.posts.docs.select { |post| post.tags.include?(url.split('/').last) } # Adjust filtering as necessary
      posts.each do |post|
        posts_list += "<li><a href='#{post.url}'>#{post.title}</a></li>"
      end
      posts_list += "</ul>"

      # Create the AMP version of the page
      amp_permalink = File.join(url.sub(%r!/$!, ""), "amp", "/")
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

  # Hook: Run after pages render, create AMP for jekyll-archives pages
  Jekyll::Hooks.register :pages, :post_render do |page|
    next if page.data["is_amp"]
    next unless page.data["jekyll-archives"]
    next if page.url.include?("/amp/")
  
    # Fallback: infer type from URL if not explicitly defined
    archive_type = page.data["type"]
    if archive_type.nil?
      archive_type = if page.url.include?("/tag/")
                       "tag"
                     elsif page.url.include?("/kategori/") || page.url.include?("/category/")
                       "category"
                     elsif page.url =~ %r!/20\d{2}/\d{2}/!
                       "month"
                     elsif page.url =~ %r!/20\d{2}/!
                       "year"
                     end
    end
  
    # Inject inferred type into data for AMP copy
    amp_data = page.data.merge({
      "type" => archive_type,
      "jekyll-archives" => true,
      "is_amp" => true,
      "canonical_url" => page.url
    })
  
    amp_permalink = File.join(page.url.sub(%r!/$!, ""), "amp", "/")
    output_dir = amp_permalink.sub(%r!^/!, "").chomp("/")
  
    amp_page = Jekyll::AmpPage.new(
      site: page.site,
      base: page.site.source,
      original: page,
      permalink: amp_permalink,
      output_dir: output_dir
    )
  
    amp_page.data.merge!(amp_data)  # ✅ Ensure AMP page has `type`, `jekyll-archives`, etc.
    page.site.pages << amp_page
  end
  

  # Hook: Minify final HTML output for all pages and documents (AMP or not)
  Jekyll::Hooks.register [:pages, :documents], :post_render do |item|
    next unless item.output_ext == ".html"
    item.output = Jekyll::HTMLUtils.minify_html(item.output)
  end
end
