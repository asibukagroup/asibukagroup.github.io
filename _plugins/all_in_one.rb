# _plugins/amp_generator.rb
module Jekyll
  class AmpGenerator < Generator
    safe true
    priority :low

    def generate(site)
      site.pages.each { |page| generate_amp_page(site, page) if valid_root_md?(site, page) }
      site.posts.docs.each { |post| generate_amp_page(site, post) }
      site.collections.each do |name, collection|
        next if name == "posts" # already handled
        collection.docs.each { |doc| generate_amp_page(site, doc) }
      end

      generate_amp_archives(site)
    end

    private

    def valid_root_md?(site, page)
      page.extname == ".md" && File.dirname(page.path) == site.source
    end

    def generate_amp_page(site, page)
      return if page.data["is_amp"]

      amp_page = page.dup
      amp_page.data = page.data.dup
      amp_page.data["is_amp"] = true
      amp_page.data["permalink"] = ensure_trailing_slash(page.url) + "amp/"
      amp_page.output = page.output # Copy output so archive list still renders

      site.pages << amp_page unless amp_page.is_a?(Jekyll::Document)
      site.collections[page.collection.label].docs << amp_page if page.is_a?(Jekyll::Document)
    end

    def generate_amp_archives(site)
      archive_pages = site.pages.select do |page|
        archive_layout?(page)
      end

      archive_pages.each do |page|
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
end
