# _plugins/amp_generator.rb
require 'nokogiri'

module Jekyll
  class AmpGenerator < Generator
    safe true
    priority :lowest

    def generate(site)
      collections = site.config['collections'].keys

      site.pages.select { |page| valid_md_page?(page) && !page.data['is_amp'] }.each do |page|
        site.pages << generate_amp_page(site, page)
      end

      site.collections.each_value do |collection|
        collection.docs.select { |doc| valid_md_doc?(doc, collections) && !doc.data['is_amp'] }.each do |doc|
          site.pages << generate_amp_page(site, doc)
        end
      end

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
      amp_page.content = convert_html_for_amp(original.content)
      amp_page.data = amp_data

      amp_page
    end

    def duplicate_archive_as_amp(site, original)
      amp_data = original.data.dup
      amp_data['is_amp'] = true
      amp_data['permalink'] = original.url.sub(/\/$/, '') + '/amp/'

      amp_page = PageWithoutAFile.new(site, site.source, original.dir, 'index-amp.html')
      amp_page.output = convert_html_for_amp(original.output)
      amp_page.content = original.content
      amp_page.data = amp_data

      amp_page
    end

    def convert_html_for_amp(html)
      html = convert_images_to_amp(html)
      html = convert_iframes_to_amp(html)
      html = convert_videos_to_amp(html)
      html = convert_pictures_to_amp(html)
      html = convert_figures_to_amp(html)
      html = remove_scripts(html)
      html
    end

    def convert_images_to_amp(html)
      doc = Nokogiri::HTML5.fragment(html)
      doc.css('img').each do |img|
        amp_img = Nokogiri::XML::Node.new('amp-img', doc)

        src = img['data-src'] || img['src']
        amp_img['src'] = src.nil? || src.strip.empty? ? '/assets/img/ASIBUKA-Blue.webp' : src
        amp_img['alt'] = img['alt'] || img['title'] || 'image'
        amp_img['title'] = img['alt'] || img['title'] || ''
        amp_img['width'] = img['width'] || '1600'
        amp_img['height'] = img['height'] || '900'
        amp_img['layout'] = img['layout'] || 'responsive'

        img.replace(amp_img)
      end
      doc.to_html
    end

    def convert_iframes_to_amp(html)
      doc = Nokogiri::HTML5.fragment(html)
      doc.css('iframe').each do |iframe|
        amp_iframe = Nokogiri::XML::Node.new('amp-iframe', doc)

        amp_iframe['src'] = iframe['src'] || ''
        amp_iframe['width'] = iframe['width'] || '600'
        amp_iframe['height'] = iframe['height'] || '400'
        amp_iframe['layout'] = 'responsive'
        amp_iframe['sandbox'] = 'allow-scripts allow-same-origin'
        amp_iframe['title'] = iframe['title'] || 'Embedded content'

        iframe.children.each { |child| amp_iframe.add_child(child) }

        fallback = Nokogiri::XML::Node.new('fallback', doc)
        fallback.content = 'This content is not available.'
        amp_iframe.add_child(fallback)

        iframe.replace(amp_iframe)
      end
      doc.to_html
    end

    def convert_videos_to_amp(html)
      doc = Nokogiri::HTML5.fragment(html)
      doc.css('video').each do |video|
        amp_video = Nokogiri::XML::Node.new('amp-video', doc)

        amp_video['src'] = video['src'] if video['src']
        amp_video['poster'] = video['poster'] if video['poster']
        amp_video['width'] = video['width'] || '640'
        amp_video['height'] = video['height'] || '360'
        amp_video['layout'] = 'responsive'
        amp_video['controls'] = 'controls'

        video.children.each { |child| amp_video.add_child(child) }

        fallback = Nokogiri::XML::Node.new('fallback', doc)
        fallback.content = 'This video is not available.'
        amp_video.add_child(fallback)

        video.replace(amp_video)
      end
      doc.to_html
    end

    def convert_pictures_to_amp(html)
      doc = Nokogiri::HTML5.fragment(html)
      doc.css('picture').each do |picture|
        img = picture.at_css('img') || picture.at_css('source')
        src = img['srcset'] || img['src']

        amp_img = Nokogiri::XML::Node.new('amp-img', doc)
        amp_img['src'] = src || '/assets/img/ASIBUKA-Blue.webp'
        amp_img['alt'] = img['alt'] || 'image'
        amp_img['width'] = img['width'] || '1600'
        amp_img['height'] = img['height'] || '900'
        amp_img['layout'] = 'responsive'

        picture.replace(amp_img)
      end
      doc.to_html
    end

    def convert_figures_to_amp(html)
      doc = Nokogiri::HTML5.fragment(html)
      doc.css('figure').each do |figure|
        if (img = figure.at_css('img'))
          amp_img = Nokogiri::XML::Node.new('amp-img', doc)

          src = img['data-src'] || img['src']
          amp_img['src'] = src.nil? || src.strip.empty? ? '/assets/img/ASIBUKA-Blue.webp' : src
          amp_img['alt'] = img['alt'] || 'image'
          amp_img['width'] = img['width'] || '1600'
          amp_img['height'] = img['height'] || '900'
          amp_img['layout'] = 'responsive'

          figcaption = figure.at_css('figcaption')
          new_figure = Nokogiri::XML::Node.new('figure', doc)
          new_figure.add_child(amp_img)
          new_figure.add_child(figcaption) if figcaption

          figure.replace(new_figure)
        else
          figure.remove
        end
      end
      doc.to_html
    end

    def remove_scripts(html)
      doc = Nokogiri::HTML5.fragment(html)
      doc.css('script').each do |script|
        script.remove unless script['type'] == 'application/ld+json'
      end
      doc.to_html
    end
  end
end