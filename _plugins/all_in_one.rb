require "jekyll"
require "nokogiri"
require "fileutils"

module Jekyll
  # Utility module for minifying HTML, CSS, and JavaScript
  module HTMLUtils
    # Minifies the HTML content by removing unnecessary spaces and comments
    def self.minify_html(html)
      doc = Nokogiri::HTML(html)
      html = doc.to_html
      html.gsub(/>\s+</, '><')   # Remove spaces between tags
          .gsub(/\n+/, ' ')      # Remove newlines
          .gsub(/\s{2,}/, ' ')    # Replace multiple spaces with a single space
          .gsub(/<!--.*?-->/m, '')  # Remove comments
          .gsub(/;}/, '}')       # Fix CSS style minification
          .gsub(/\/\*.*?\*\//m, '') # Remove CSS comments
          .gsub(/\s+/, ' ')       # Clean up any remaining spaces
          .strip                 # Remove trailing/leading whitespace
    end

    # Minifies CSS content by removing extra spaces and comments
    def self.minify_css(css)
      css.gsub(/\/\*.*?\*\//m, '')  # Remove CSS comments
         .gsub(/\s+/, ' ')         # Replace multiple spaces with a single space
         .gsub(/\s*([{:;}])\s*/, '\1')  # Remove spaces around CSS symbols
         .gsub(/;}/, '}')           # Remove unnecessary semicolons in CSS
         .strip                    # Remove any trailing spaces
    end

    # Minifies JavaScript content by removing comments and extra spaces
    def self.minify_js(js)
      js.gsub(/\/\/.*$/, '')       # Remove single-line comments
         .gsub(/\/\*.*?\*\//m, '') # Remove multi-line comments
         .gsub(/\s+/, ' ')         # Remove extra spaces
         .strip                    # Clean up any remaining whitespace
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
      self.data["layout"] = original.data["layout"]
      self.data["permalink"] = permalink
      self.data["canonical_url"] = original.url
      self.data["is_amp"] = true

      # Determine the content (either from markdown or existing HTML)
      html = if original.content.strip.empty? || original.output.to_s.strip != ''
               original.output.to_s
             else
               markdown_converter = site.find_converter_instance(Jekyll::Converters::Markdown)
               payload = { "page" => original.data, "site" => site.site_payload["site"] }
               liquid = site.liquid_renderer.file(original.path).parse(original.content)
               rendered_liquid = liquid.render!(payload, registers: { site: site, page: original })
               markdown_converter.convert(rendered_liquid)
             end

      # Convert the content to AMP-friendly format
      self.content = convert_to_amp(html)
    end

    private

    # Converts the HTML to AMP-compatible format (removes or modifies certain tags)
    def convert_to_amp(html)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)

      # Convert <img> tags to <amp-img> tags
      doc.css("img").each do |img|
        amp_img = Nokogiri::XML::Node.new("amp-img", doc)
        amp_img["src"] = img["data-src"] || img["src"]
        amp_img["alt"] = img["alt"] if img["alt"]
        amp_img["width"] = img["width"] || "600"
        amp_img["height"] = img["height"] || "400"
        amp_img["layout"] = img["layout"] || "responsive"
        img.replace(amp_img)
      end

      # Convert <iframe> tags to <amp-iframe> tags
      doc.css("iframe").each do |iframe|
        amp_iframe = Nokogiri::XML::Node.new("amp-iframe", doc)
        %w[src width height layout sandbox].each { |attr| amp_iframe[attr] = iframe[attr] if iframe[attr] }
        amp_iframe["width"] ||= "600"
        amp_iframe["height"] ||= "400"
        amp_iframe["layout"] ||= "responsive"
        amp_iframe["sandbox"] ||= "allow-scripts allow-same-origin"
        iframe.replace(amp_iframe)
      end

      # Minify and remove inline <script> tags
      doc.css("script").each do |script|
        if script["src"]&.include?("https://cdn.ampproject.org/") # Skip AMP library scripts
          next
        elsif script.children.any?
          cleaned_js = HTMLUtils.minify_js(script.content)
          script.content = cleaned_js
        else
          script.remove
        end
      end

      # Minify the inline <style> tags
      doc.css("style").each do |style|
        style.content = HTMLUtils.minify_css(style.content)
      end

      # Return the final minified HTML
      HTMLUtils.minify_html(doc.to_html)
    end
  end

  # Main generator class to generate AMP pages and archives
  class AllInOneGenerator < Generator
    safe true
    priority :low

    # Main method for generating AMP pages and archives
    def generate(site)
      generate_amp(site)       # Generate AMP versions for pages and posts
      generate_archives(site)  # Generate archives for tags, categories, authors, and dates
    end

    # Generate AMP pages for posts, pages, and collections
    def generate_amp(site)
      markdown_exts = [".md", ".markdown"]

      site.pages.each do |page|
        next if page.url.include?("/amp/") # Skip already AMP pages
        next unless markdown_exts.include?(page.extname) # Only process markdown files

        amp_permalink = File.join((page.data["permalink"] || page.url).sub(%r!/$!, ""), "amp", "/")
        output_dir = page.url == "/" ? "amp" : amp_permalink.sub(%r!^/!, "").chomp("/")

        # Create AMP page for each page
        site.pages << AmpPage.new(site: site, base: site.source, original: page, permalink: amp_permalink, output_dir: output_dir)
      end

      site.posts.docs.each do |post|
        next if post.url.include?("/amp/") # Skip already AMP pages
        amp_permalink = File.join(post.url.sub(%r!/$!, ""), "amp", "/")
        output_dir = amp_permalink.sub(%r!^/!, "").chomp("/")

        # Create AMP page for each post
        site.pages << AmpPage.new(site: site, base: site.source, original: post, permalink: amp_permalink, output_dir: output_dir)
      end

      site.collections.each do |name, collection|
        next if ["posts", "drafts", "pages"].include?(name)  # Skip certain collections

        # Create AMP pages for other collections (e.g., products)
        collection.docs.each do |doc|
          next if doc.url.include?("/amp/")  # Skip already AMP pages
          next unless markdown_exts.include?(doc.extname)  # Only process markdown files

          amp_permalink = File.join(doc.url.sub(%r!/$!, ""), "amp", "/")
          output_dir = amp_permalink.sub(%r!^/!, "").chomp("/")

          site.pages << AmpPage.new(site: site, base: site.source, original: doc, permalink: amp_permalink, output_dir: output_dir)
        end
      end
    end

    # Generate archive pages for tags, categories, authors, and date-based archives
    def generate_archives(site)
      archive_dir = "_pages"
      FileUtils.mkdir_p(archive_dir)
      Dir.glob("#{archive_dir}/_auto_*.md").each { |f| File.delete(f) } # Clean up old archives

      posts = site.posts.docs

      # Generate archive pages for tags, categories, and authors
      generate_taxonomy_pages("tag", posts.flat_map(&:tags).uniq, archive_dir)
      generate_taxonomy_pages("category", posts.flat_map(&:categories).uniq, archive_dir)
      generate_taxonomy_pages("author", posts.map { |p| p.data["author"] }.compact.uniq, archive_dir)

      # Generate date-based archives
      generate_date_archives(posts, archive_dir)
    end

    # Generate archive pages for tags, categories, and authors
    def generate_taxonomy_pages(type, values, dir)
      values.each do |val|
        slug = val.downcase.strip.gsub(/\s+/, "-") # Normalize taxonomy names
        filename = "_auto_#{type}_#{slug}.md"
        permalink = case type
                    when "tag" then "/tag/#{slug}/"
                    when "category" then "/kategori/#{slug}/"
                    when "author" then "/penulis/#{slug}/"
                    end

        content = <<~YAML
          ---
          layout: archive
          title: "#{val.capitalize}"
          permalink: "#{permalink}"
          type: #{type}
          #{type}: "#{val}"
          ---  
        YAML

        # Write the generated archive page file
        archive_page = File.join(dir, filename)
        File.write(archive_page, content)

        # Create AMP version of the archive page
        amp_permalink = File.join(permalink, "amp", "/")
        amp_output_dir = File.join(dir, "amp")
        site.pages << AmpPage.new(site: site, base: site.source, original: archive_page, permalink: amp_permalink, output_dir: amp_output_dir)
      end
    end

    # Generate archive pages for year and month-based archives
    def generate_date_archives(posts, dir)
      years = posts.map { |p| p.date.year }.uniq

      years.each do |year|
        filename_year = "_auto_year_#{year}.md"
        permalink_year = "/arsip/#{year}/"
        content_year = <<~YAML
          ---
          layout: archive
          title: "Arsip #{year}"
          permalink: "#{permalink_year}"
          type: year
          year: #{year}
          ---
        YAML
        File.write(File.join(dir, filename_year), content_year)

        # Generate monthly archives for each year
        (1..12).each do |month|
          matching = posts.select { |p| p.data["date"].year == year && p.data["date"].month == month }
          next if matching.empty?

          filename_month = "_auto_month_#{year}_#{month.to_s.rjust(2, "0")}.md"
          permalink_month = "/arsip/#{year}/#{month.to_s.rjust(2, "0")}/"
          content_month = <<~YAML
            ---
            layout: archive
            title: "Arsip #{year}/#{month.to_s.rjust(2, "0")}"
            permalink: "#{permalink_month}"
            type: month
            year: #{year}
            month: #{month}
            ---
          YAML
          File.write(File.join(dir, filename_month), content_month)
        end
      end
    end


    # Generate archive pages for year and month-based archives
    def generate_date_archives(posts, dir)
      years = posts.map { |p| p.date.year }.uniq

      years.each do |year|
        filename_year = "_auto_year_#{year}.md"
        permalink_year = "/arsip/#{year}/"
        content_year = <<~YAML
          ---
          layout: archive
          title: "Arsip #{year}"
          permalink: "#{permalink_year}"
          type: year
          year: #{year}
          ---
        YAML
        File.write(File.join(dir, filename_year), content_year)

        # Generate monthly archives for each year
        (1..12).each do |month|
          matching = posts.select { |p| p.date.year == year && p.date.month == month }
          next if matching.empty?

          filename_month = "_auto_month_#{year}_#{month.to_s.rjust(2, "0")}.md"
          permalink_month = "/arsip/#{year}/#{month.to_s.rjust(2, "0")}/"
          content_month = <<~YAML
            ---
            layout: archive
            title: "Arsip #{year}/#{month.to_s.rjust(2, "0")}"
            permalink: "#{permalink_month}"
            type: month
            year: #{year}
            month: #{month}
            ---
          YAML
          File.write(File.join(dir, filename_month), content_month)
        end
      end
    end
  end

  # Hook to minify the HTML output after rendering
  Jekyll::Hooks.register [:pages, :documents], :post_render do |item|
    next unless item.output_ext == ".html"
    item.output = Jekyll::HTMLUtils.minify_html(item.output)
  end
end
