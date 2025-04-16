module Jekyll
  class AmpGenerator < Generator
    safe true
    priority :low

    def generate(site)
      collections = site.config['collections'].keys

      site.collections.each_value do |collection|
        collection.docs.each do |doc|
          next unless valid_md_doc?(doc, collections)
          next if doc.data['is_amp']

          site.pages << generate_amp_page(site, doc)
        end
      end

      site.pages.each do |page|
        next unless valid_md_page?(page)
        next if page.data['is_amp']

        site.pages << generate_amp_page(site, page)
      end
    end

    private

    def valid_md_doc?(doc, collections)
      doc.path.end_with?('.md') && collections.any? { |c| doc.path.include?("_#{c}/") }
    end

    def valid_md_page?(page)
      page.path.end_with?('.md') &&
        (
          File.basename(page.path) == 'index.md' || # ensure homepage is included
          File.dirname(page.path) == '.' || File.dirname(page.path) == ''
        )
    end

    def generate_amp_page(site, original)
      amp_data = original.data.dup
      amp_data['is_amp'] = true
      amp_data['layout'] ||= 'amp'
      amp_data['permalink'] = original.url.sub(/\/$/, '') + '/amp/'

      filename = original.basename_without_ext + '-amp.md'
      dir = File.dirname(original.path.sub(site.source, ''))

      amp_page = PageWithoutAFile.new(site, site.source, dir, filename)
      amp_page.content = original.content
      amp_page.data = amp_data

      amp_page
    end
  end
end
