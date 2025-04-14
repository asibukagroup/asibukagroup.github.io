require "jekyll"
require "fileutils"

module Jekyll
  class ArchiveGenerator < Generator
    safe true
    priority :normal

    def generate(site)
      archive_dir = "_pages"
      FileUtils.mkdir_p(archive_dir)

      # Clean up previously generated archive files
      Dir.glob("#{archive_dir}/_auto_*.md").each { |f| File.delete(f) }

      excluded = %w[drafts pages]
      collections = site.collections.keys.reject { |name| excluded.include?(name) }
      posts = collections.flat_map { |name| site.collections[name]&.docs || [] }

      generate_taxonomy_pages("tag", posts.flat_map { |p| p.data["tags"] || [] }.uniq, archive_dir)
      generate_taxonomy_pages("category", posts.flat_map { |p| p.data["categories"] || [] }.uniq, archive_dir)
      generate_taxonomy_pages("author", posts.map { |p| p.data["author"] }.compact.uniq, archive_dir)
      generate_taxonomy_pages("year", posts.map { |p| p.date.year }.uniq, archive_dir)

      generate_date_archives(posts, archive_dir)
    end

    def generate_taxonomy_pages(type, values, dir)
      values.compact.uniq.each do |val|
        next if val.nil? || val.to_s.strip.empty?

        val_str = val.to_s
        slug = val_str.downcase.strip.gsub(/\s+/, "-")
        filename = "_auto_#{type}_#{slug}.md"

        permalink = case type
                    when "tag" then "/tag/#{slug}/"
                    when "category" then "/kategori/#{slug}/"
                    when "author" then "/penulis/#{slug}/"
                    when "year" then "/arsip/#{slug}/"
                    else "/#{type}/#{slug}/"
                    end

        content = <<~YAML
          ---
          layout: archive
          title: "#{val_str.capitalize}"
          permalink: "#{permalink}"
          type: #{type}
          #{type}: "#{val_str}"
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

          month_str = month.to_s.rjust(2, "0")
          filename_month = "_auto_month_#{year}_#{month_str}.md"
          permalink_month = "/arsip/#{year}/#{month_str}/"
          content_month = <<~YAML
            ---
            layout: archive
            title: "Arsip #{year}/#{month_str}"
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
end