require "jekyll"

module Jekyll
  class AmpPage < Page
    def initialize(site:, base:, original:)
      @site = site
      @base = base

      original_dir = File.dirname(original.url).sub(%r!^/!, "")
      amp_dir = File.join(original_dir, "amp")
      @dir = amp_dir
      @name = "index.html"
      process(@name)

      self.data = original.data.dup
      self.data["layout"] ||= original.data["layout"]
      self.data["permalink"] = File.join(original.url.sub(%r!/$!, ""), "amp", "/")
      self.data["is_amp"] = true
      self.data["canonical_url"] = original.url

      @relative_path = original.relative_path

      self.content = if original.output&.strip&.length&.positive?
                       original.output.to_s
                     else
                       render_html_from_markdown(original, site)
                     end
    end

    private

    def render_html_from_markdown(original, site)
      payload = {
        "page" => original.data,
        "site" => site.site_payload["site"]
      }

      liquid = site.liquid_renderer.file(original.path).parse(original.content)
      rendered = liquid.render!(payload, registers: { site: site, page: original })
      markdown_converter = site.find_converter_instance(Jekyll::Converters::Markdown)
      markdown_converter.convert(rendered)
    end
  end

  class AmpGenerator < Generator
    safe true
    priority :lowest

    def generate(site)
      seen_urls = {}

      # Process standalone pages
      site.pages.each do |page|
        next if skip_amp?(page)
        key = amp_path_key(page.url)
        next if seen_urls[key]
        site.pages << AmpPage.new(site: site, base: site.source, original: page)
        seen_urls[key] = true
      end

      # Process all collections (includes posts)
      site.collections.each_value do |collection|
        collection.docs.each do |doc|
          next if skip_amp?(doc)
          key = amp_path_key(doc.url)
          next if seen_urls[key]
          site.pages << AmpPage.new(site: site, base: site.source, original: doc)
          seen_urls[key] = true
        end
      end
    end

    private

    def skip_amp?(item)
      item.url.include?("/amp/") || item.data["is_amp"] || item.output_ext != ".html"
    end

    def amp_path_key(url)
      File.join(url.sub(%r!/$!, ""), "amp/")
    end
  end
end
