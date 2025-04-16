require 'yaml'
require 'fileutils'

module Jekyll
  class AmpGenerator < Generator
    safe true
    priority :low

    def generate(site)
      @site = site
      @collections = site.config['collections'].keys

      site.collections.each_value do |collection|
        collection.docs.each do |doc|
          next unless valid_md_doc?(doc)
          next if doc.data['is_amp']

          create_amp_version(doc, collection.label)
        end
      end

      site.pages.each do |page|
        next unless valid_md_page?(page)
        next if page.data['is_amp']

        create_amp_version(page)
      end
    end

    private

    def valid_md_doc?(doc)
      doc.path.end_with?('.md') && in_collection?(doc)
    end

    def valid_md_page?(page)
      page.path.end_with?('.md') && File.dirname(page.path) == @site.source
    end

    def in_collection?(doc)
      @collections.any? { |name| doc.path.include?("_#{name}/") }
    end

    def create_amp_version(item, collection_label = nil)
      amp_data = item.data.dup
      amp_data['is_amp'] = true
      amp_data['permalink'] = item.url.sub(/\/$/, '') + '/amp/'

      # Create new AMP filename (e.g., post-amp.md)
      amp_filename = item.basename_without_ext + '-amp.md'

      # Determine directory
      dir = File.dirname(item.path)
      amp_path = File.join(dir, amp_filename)

      # Write AMP markdown file
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
      File.open(amp_path, 'w') do |f|
        f.puts front_matter(amp_data)
        f.puts item.content
      end

      # Register AMP file as a document so Jekyll renders it
      if item.is_a?(Jekyll::Document)
        collection = collection_label ? @site.collections[collection_label] : nil
        amp_doc = Jekyll::Document.new(amp_path, :site => @site, :collection => collection)
        amp_doc.read
        collection.docs << amp_doc if collection
      else
        amp_page = PageWithoutAFile.new(@site, @site.source, dir, amp_filename)
        amp_page.data = amp_data
        amp_page.content = item.content
        @site.pages << amp_page
      end
    end

    def front_matter(data)
      "---\n" + data.to_yaml.strip + "\n---"
    end
  end
end
