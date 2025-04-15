require "jekyll"

module Jekyll
  class AmpGenerator < Generator
    safe true
    priority :low

    def generate(site)
      all_docs = []

      # Include all relevant collections
      collections_to_include = %w(posts pages products)
      collections_to_include.each do |coll|
        all_docs.concat(site.collections[coll]&.docs || [])
      end

      # Include root .md pages
      all_docs.concat(site.pages.select { |page| page.path.end_with?(".md") })

      # Include archive pages (optional, if they are treated as Pages)
      archive_pages = site.pages.select { |page| page.data["layout"] == "archive" }
      all_docs.concat(archive_pages)

      amp_pages = []

      all_docs.each do |doc|
        next if doc.data["is_amp"] # skip if already AMP

        amp_doc = doc.dup
        amp_doc.data = Jekyll::Utils.deep_merge_hashes(doc.data, {})

        # Derive AMP permalink
        base_url = ensure_slash(doc.url)
        amp_doc.data["permalink"] = File.join(base_url, "amp/")

        # Set AMP-specific values
        amp_doc.data["is_amp"] = true

        # Retain the original layout
        original_layout = doc.data["layout"] || "default"
        amp_doc.data["layout"] = original_layout

        # Set AMP path
        amp_doc.instance_variable_set(:@path, nil) # let Jekyll auto-generate
        amp_pages << amp_doc
      end

      site.pages.concat(amp_pages)
    end

    private

    def ensure_slash(path)
      path.end_with?("/") ? path : "#{path}/"
    end
  end
end