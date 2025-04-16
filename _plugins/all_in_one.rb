# _plugins/amp_generator.rb
module Jekyll
  class AmpGenerator < Generator
    safe true
    priority :low

    def generate(site)
      # Generate AMP for root .md pages
      site.pages.each do |page|
        generate_amp_page(site, page) if root_md_page?(site, page)
      end

      # Generate AMP for posts and other docs
      site.posts.docs.each { |post| generate_amp_doc(site, post) }
      site.collections.each do |name, collection|
        next if name == "posts"
        collection.docs.each { |doc| generate_amp_doc(site, doc) }
      end

      # Generate AMP for archives
      generate_amp_archives(site)
    end

    def root_md_page?(site, page)
      page.extname == ".md" && File.dirname(page.path) == site.source
    end

    def generate_amp_page(site, page)
      return if page.data["is_amp"]

      amp_page = page.dup
      amp_page.data = page.data.dup
      amp_page.data["is_amp"] = true
      amp_page.data["permalink"] = ensure_trailing_slash(page.url) + "amp/"
      site.pages << amp_page
    end

    def generate_amp_doc(site, doc)
      return if doc.data["is_amp"]

      amp_doc = doc.dup
      amp_doc.merge_data!(doc.data) # safely copy data
      amp_doc.data["is_amp"] = true
      amp_doc.data["permalink"] = ensure_trailing_slash(doc.url) + "amp/"
      site.collections[doc.collection.label].docs << amp_doc
    end

    def generate_amp_archives(site)
      site.pages.each do |page|
        next unless archive_layout?(page)
        next if page.data["is_amp"]

        amp_page = page.dup
        amp_page.data = page.data.dup
        amp_page.data["is_amp"] = true
        amp_page.data["permalink"] = ensure_trailing_slash(page.url) + "amp/"
        amp_page.data["posts"] = page.data["posts"]
        amp_page.data["type"] = page.data["type"]
        site.pages << amp_page
      end
    end

    def archive_layout?(page)
      layout = page.data["layout"]
      layout == "archive" || layout == "archives"
    end

    def ensure_trailing_slash(url)
      url.end_with?("/") ? url : "#{url}/"
    end
  end

  class Jekyll::Document
    def merge_data!(new_data)
      new_data.each { |k, v| self.data[k] = v }
    end
  end
end
