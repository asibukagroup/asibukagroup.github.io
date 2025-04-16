# _plugins/amp_generator.rb
require 'nokogiri'

module Jekyll
  class AmpGenerator < Generator
    safe true
    priority :lowest # Ensure it runs after all other generators like jekyll-archives

    def generate(site)
      collections = site.config['collections'].keys

      # Process normal pages (.md in root)
      site.pages.select { |page| valid_md_page?(page) && !page.data['is_amp'] }.each do |page|
        site.pages << generate_amp_page(site, page)
      end

      # Process documents (e.g., posts)
      site.collections.each_value do |collection|
        collection.docs.select { |doc| valid_md_doc?(doc, collections) && !doc.data['is_amp'] }.each do |doc|
          site.pages << generate_amp_page(site, doc)
        end
      end

      # Duplicate jekyll-archives generated pages
      site.pages.select { |page| archive_page?(page) && !page.data['is_amp'] }.each do |page|
        site.pages << duplicate_archive_as_amp(site, page)
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
      page.data['layout'] == 'archive'
    end

    def generate_amp_page(site, original)
      amp_data = original.data.dup
      amp_data['is_amp'] = true
      amp_data['permalink'] = original.url.sub(/\/$/, '') + '/amp/'

      basename = File.basename(original.path, File.extname(original.path))
      amp_filename = "#{basename}-amp.md"
      amp_dir = File.dirname(original.path.sub(site.source, ''))

      amp_page = PageWithoutAFile.new(site, site.source, amp_dir, amp_filename)
      amp_page.content = convert_images_to_amp(original.content)
      amp_page.data = amp_data

      amp_page
    end

    def duplicate_archive_as_amp(site, original)
      amp_data = original.data.dup
      amp_data['is_amp'] = true
      amp_data['permalink'] = original.url.sub(/\/$/, '') + '/amp/'

      amp_page = PageWithoutAFile.new(site, site.source, original.dir, 'index-amp.html')
      amp_page.output = convert_images_to_amp(original.output)
      amp_page.content = original.content
      amp_page.data = amp_data

      amp_page
    end

    def convert_images_to_amp(html)
      doc = Nokogiri::HTML.fragment(html)
      doc.css('img').each do |img|
        amp_img = Nokogiri::XML::Node.new('amp-img', doc)

        amp_img['src'] = img['data-src'] || img['src'] || '/assets/img/ASIBUKA-Blue.webp'
        amp_img['alt'] = img['alt'] || img['title'] || 'image'
        amp_img['title'] = img['alt'] || img['title'] || ''
        amp_img['width'] = img['width'] || '1600'
        amp_img['height'] = img['height'] || '900'
        amp_img['layout'] = img['layout'] || 'responsive'

        img.replace(amp_img)
      end
      doc.to_html
    end
  end
end