require "nokogiri"
require "yaml"
require "fileutils"

module Jekyll
  class AmpGenerator < Generator
    safe true
    priority :low

    def generate(site)
      collections = site.config['collections'].keys

      # Go through all markdown files from root, pages, posts, and collections
      candidates = site.pages + site.posts.docs + collections.flat_map { |key| site.collections[key].docs }

      candidates.each do |page|
        next unless valid_md_page?(page, site, collections)
        next if page.data['is_amp']

        generate_amp_page(site, page)
      end
    end

    private

    def valid_md_page?(page, site, collections)
      page.extname == ".md" &&
        (in_root_directory?(page, site) || in_valid_collection?(page, collections, site))
    end

    def in_root_directory?(page, site)
      path = page.respond_to?(:path) ? page.path : page.relative_path
      File.dirname(File.expand_path(path, site.source)) == site.source
    end

    def in_valid_collection?(page, collections, site)
      path = page.respond_to?(:path) ? page.path : page.relative_path
      collections.any? { |c| File.expand_path(path, site.source).include?("/_#{c}/") }
    end

    def generate_amp_page(site, original)
      amp_data = original.data.dup
      amp_data['is_amp'] = true
      amp_data['permalink'] = original.url.sub(%r{/$}, "") + "/amp/"

      # Handle archives (tags, categories, year, month)
      if amp_data['layout'] == 'archive' && amp_data['type']
        amp_data['posts'] = fetch_archive_posts(amp_data, site)
      end

      amp_content = original.output
      amp_filename = amp_filename_for(original)

      amp_path = File.join(site.source, amp_filename)
      FileUtils.mkdir_p(File.dirname(amp_path))

      File.open(amp_path, 'w') do |f|
        f.puts front_matter(amp_data)
        f.puts amp_content
      end
    end

    def fetch_archive_posts(data, site)
      type = data['type']
      title = data['title']
      url_parts = data['permalink'] ? data['permalink'].split("/") : []

      case type
      when 'tag'
        site.posts.docs.select { |p| p.data['tags']&.include?(title) }
      when 'category'
        site.posts.docs.select { |p| p.data['categories']&.include?(title) }
      when 'year'
        year = url_parts[1].to_i
        site.posts.docs.select { |p| p.date.year == year }
      when 'month'
        year = url_parts[1].to_i
        month = url_parts[2].to_i
        site.posts.docs.select { |p| p.date.year == year && p.date.month == month }
      else
        []
      end
    end

    def amp_filename_for(page)
      dir = if page.respond_to?(:path)
              File.dirname(page.path)
            else
              page.dir
            end

      name = if page.respond_to?(:basename_without_ext)
               page.basename_without_ext
             else
               File.basename(page.name, File.extname(page.name))
             end

      ext = page.extname || File.extname(page.name)
      amp_name = "#{name}-amp#{ext}"

      dir == '.' ? amp_name : File.join(dir, amp_name)
    end

    def front_matter(data)
      "---\n" + data.to_yaml.sub(/\A---\s*\n/, '') + "---"
    end
  end
end
