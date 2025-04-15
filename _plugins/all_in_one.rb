require "jekyll"

module Jekyll
  class AmpPage < Page
    def initialize(site:, base:, original:, permalink:, output_dir:)
      @site = site
      @base = base
      @dir  = output_dir
      @name = "index.html"
      process(@name)

      # Copy front matter
      self.data = original.data.dup
      self.data["layout"] ||= original.data["layout"]
      self.data["permalink"] = permalink
      self.data["is_amp"] = true
      self.data["canonical_url"] = original.url

      @relative_path = original.relative_path

      # Use rendered HTML output if available, fallback to rendering it
      self.content = if original.output&.strip&.length&.positive?
                       original.output.to_s
                     else
                       convert_to_html(original, site)
                     end
    end

    private

    def convert_to_html(original, site)
      payload = {
        "page" => original.data,
        "site" => site.site_payload["site"]
      }

      liquid = site.liquid_renderer.file(original.path).parse(original.content)
      rendered_liquid = liquid.render!(payload, registers: { site: site, page: original })
      markdown_converter = site.find_converter_instance(Jekyll::Converters::Markdown)

      markdown_converter.convert(rendered_liquid)
    end
  end

  class AmpGenerator < Generator
    safe true
    priority :lowest

    def generate(site)
      all_docs = site.pages + site.posts.docs
      site.collections.each do |_, collection|
        all_docs.concat(collection.docs)
      end

      all_docs.each do |doc|
        next if skip_amp?(doc)

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

    private

    def skip_amp?(item)
      item.url.include?("/amp/") || item.data["is_amp"] || item.output_ext != ".html"
    end
  end
end
