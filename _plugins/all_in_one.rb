require "jekyll"
require "nokogiri"
require "fileutils"

module Jekyll
  module HTMLUtils
    def self.minify_html(html)
      doc = Nokogiri::HTML(html)
      html = doc.to_html
      html.gsub(/>\s+</, '><')
          .gsub(/\n+/, ' ')
          .gsub(/\s{2,}/, ' ')
          .gsub(/<!--.*?-->/m, '')
          .gsub(/;}/, '}')
          .gsub(/\/\*.*?\*\//m, '')
          .gsub(/\s+/, ' ')
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

      self.data = original.data.dup
      self.data["layout"] = original.data["layout"]
      self.data["permalink"] = permalink
      self.data["canonical_url"] = original.url
      self.data["is_amp"] = true

      html = if original.content.strip.empty? || original.output.to_s.strip != ''
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

  class AllInOneGenerator < Generator
    safe true
    priority :low

    def generate(site)
      generate_amp(site)
      generate_archives(site)
    end

    def generate_amp(site)
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
          next unless markdown_exts.include?(doc.extname)

          amp_permalink = File.join(doc.url.sub(%r!/$!, ""), "amp", "/")
          output_dir = amp_permalink.sub(%r!^/!, "").chomp("/")

          site.pages << AmpPage.new(site: site, base: site.source, original: doc, permalink: amp_permalink, output_dir: output_dir)
        end
      end
    end

    def generate_archives(site)
      archive_dir = "_pages"
      FileUtils.mkdir_p(archive_dir)
      Dir.glob("#{archive_dir}/_auto_*.md").each { |f| File.delete(f) }

      posts = site.posts.docs

      generate_taxonomy_pages("tag", posts.flat_map(&:tags).uniq, archive_dir)
      generate_taxonomy_pages("category", posts.flat_map(&:categories).uniq, archive_dir)
      generate_taxonomy_pages("author", posts.map { |p| p.data["author"] }.compact.uniq, archive_dir)
      generate_date_archives(posts, archive_dir)
    end

    def generate_taxonomy_pages(type, values, dir)
      values.each do |val|
        slug = val.downcase.strip.gsub(/\s+/, "-")
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

        File.write(File.join(dir, filename), content)
      end
    end

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

  Jekyll::Hooks.register [:pages, :documents], :post_render do |item|
    next unless item.output_ext == ".html"
    item.output = Jekyll::HTMLUtils.minify_html(item.output)
  end
end
