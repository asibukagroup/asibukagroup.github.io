require "jekyll"

module Jekyll
  class AmpPage < Page
    def initialize(site:, base:, original:)
      @site = site
      @base = base

      # Construct output dir: original dir + /amp/
      original_dir = File.dirname(original.url).sub(%r!^/!, "")
      amp_dir = File.join(original_dir, "amp")
      @dir = amp_dir
      @name = "index.html"
      process(@name)

      # Copy front matter
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
      all_docs = site.pages + site.posts.docs

      site.collections.each_value do |collection|
        all_docs.concat(collection.docs)
      end

      all_docs.each do |doc|
        next if skip_amp?(doc)

        site.pages << AmpPage.new(
          site: site,
          base: site.source,
          original: doc
        )
      end
    end

    private

    def skip_amp?(item)
      item.url.include?("/amp/") || item.data["is_amp"] || item.output_ext != ".html"
    end
  end
end
