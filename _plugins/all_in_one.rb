module Jekyll
  class AmpGenerator < Generator
    safe true
    priority :low

    def generate(site)
      collections = site.config['collections'].keys

      # Process collection documents (e.g., posts)
      site.collections.each_value do |collection|
        collection.docs.each do |doc|
          next unless valid_md_doc?(doc, collections)
          next if doc.data['is_amp']
          site.pages << generate_amp_page(site, doc)
        end
      end

      # Process .md files in the root
      site.pages.each do |page|
        next unless valid_md_page?(page)
        next if page.data['is_amp']
        site.pages << generate_amp_page(site, page)
      end

      # Process archive pages from jekyll-archives
      site.pages.each do |page|
        next unless archive_page?(page)
        site.pages << generate_amp_archive(site, page)
      end
    end

    private

    def valid_md_doc?(doc, collections)
      doc.path.end_with?('.md') && collections.any? { |c| doc.path.include?("_#{c}/") }
    end

    def valid_md_page?(page)
      page.path.end_with?('.md') && File.dirname(page.path) == '.'
    end

    def archive_page?(page)
      page.data['layout'] == 'archive' && !page.data['is_amp']
    end

    def generate_amp_page(site, original)
      amp_data = original.data.dup
      amp_data['is_amp'] = true
      amp_data['permalink'] = original.url.sub(/\/$/, '') + '/amp/'

      basename = File.basename(original.path, File.extname(original.path))
      amp_filename = "#{basename}-amp.md"
      amp_dir = File.dirname(original.path.sub(site.source, ''))

      amp_page = PageWithoutAFile.new(site, site.source, amp_dir, amp_filename)
      amp_page.content = original.content
      amp_page.data = amp_data

      amp_page
    end

    def generate_amp_archive(site, page)
      amp_data = page.data.dup
      amp_data['is_amp'] = true
      amp_data['permalink'] = page.url.sub(/\/$/, '') + '/amp/'

      amp_page = PageWithoutAFile.new(site, site.source, page.dir, 'index-amp.html')
      amp_page.content = page.content
      amp_page.data = amp_data

      amp_page
    end
  end
end
