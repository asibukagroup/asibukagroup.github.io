# _plugins/amp_generator.rb
require 'nokogiri'
require 'fastimage'

module Jekyll
  class AmpGenerator < Generator
    safe true
    priority :lowest

    def generate(site)
      collections = site.config['collections'].keys

      site.pages.select { |page| valid_md_page?(page) && !page.data['is_amp'] }.each do |page|
        page.content = inject_toc(site, page) if page.data['toc'] != false
        site.pages << generate_amp_page(site, page)
      end

      site.collections.each_value do |collection|
        collection.docs.select { |doc| valid_md_doc?(doc, collections) && !doc.data['is_amp'] }.each do |doc|
          doc.content = inject_toc(site, doc) if doc.data['toc'] != false
          site.pages << generate_amp_page(site, doc)
        end
      end

      site.pages.select { |page| archive_page?(page) && !page.data['is_amp'] }.each do |page|
        page.output = inject_toc_output(page) if page.data['toc'] != false
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
      content = site.find_converter_instance(Jekyll::Converters::Markdown).convert(original.content)
      content = inject_toc_html(content) if original.data['toc'] != false
      amp_html = convert_html_for_amp(content, amp_data)

      amp_page.content = amp_html
      amp_page.data = amp_data

      amp_page
    end

    def duplicate_archive_as_amp(site, original)
      amp_data = original.data.dup
      amp_data['is_amp'] = true
      amp_data['permalink'] = original.url.sub(/\/$/, '') + '/amp/'

      amp_page = PageWithoutAFile.new(site, site.source, original.dir, 'index-amp.html')
      html = inject_toc_html(original.output) if original.data['toc'] != false
      amp_html = convert_html_for_amp(html || original.output, amp_data)

      amp_page.output = amp_html
      amp_page.content = original.content
      amp_page.data = amp_data

      amp_page
    end

    def inject_toc(site, doc)
      content = doc.content
      html = site.find_converter_instance(Jekyll::Converters::Markdown).convert(content)
      html = inject_toc_html(html)
      site.find_converter_instance(Jekyll::Converters::Markdown).convert_back(html)
    end

    def inject_toc_output(page)
      inject_toc_html(page.output)
    end

    def inject_toc_html(html)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)
      headings = doc.css("h2, h3")
      return html if headings.empty?

      toc_tag = Nokogiri::HTML::DocumentFragment.parse(
        "<div class='toc'><details open><summary>📑 Daftar Isi</summary><ul></ul></details></div>"
      )
      toc_ul = toc_tag.at("ul")
      current_li = nil

      generate_id = ->(text, index) {
        slug = text.downcase.strip.gsub(/\s+/, "-").gsub(/[^a-z0-9\-]/, "")
        "toc-#{index}-#{slug}"
      }

      headings.each_with_index do |heading, index|
        level = heading.name.downcase
        text = heading.text.strip
        id = heading['id'] || generate_id.call(text, index)
        heading['id'] = id

        link_html = "<a href='##{id}' title='#{text}'>#{text}</a>"

        if level == "h2"
          current_li = Nokogiri::XML::Node.new("li", doc)
          current_li.inner_html = link_html
          toc_ul.add_child(current_li)
        elsif level == "h3" && current_li
          sub_ul = current_li.at("ul") || Nokogiri::XML::Node.new("ul", doc)
          sub_li = Nokogiri::XML::Node.new("li", doc)
          sub_li.inner_html = link_html
          sub_ul.add_child(sub_li)
          current_li.add_child(sub_ul) unless current_li.at("ul")
        end
      end

      first_h2 = doc.at("h2")
      first_h2.add_previous_sibling(toc_tag) if first_h2

      doc.to_html
    end

    def convert_html_for_amp(html, data = {})
      html = convert_images_to_amp(html)
      html = convert_iframes_to_amp(html)
      html = convert_videos_to_amp(html)
      html = convert_pictures_to_amp(html)
      html = convert_figures_to_amp(html)
      html = convert_internal_links_to_amp(html)
      html = remove_scripts(html)
      html = inject_amp_toc(html) if data['toc'] != false
      html
    end

    def inject_amp_toc(html)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)
      headings = doc.css("h2, h3")
      return html if headings.empty?

      toc_fragment = Nokogiri::HTML::DocumentFragment.parse(
        "<amp-accordion class='toc' layout='container'><section><h4>📑 Daftar Isi</h4><ul></ul></section></amp-accordion>"
      )
      toc_ul = toc_fragment.at("ul")
      current_li = nil

      generate_id = ->(text, index) {
        slug = text.downcase.strip.gsub(/\s+/, "-").gsub(/[^a-z0-9\-]/, "")
        "toc-#{index}-#{slug}"
      }

      headings.each_with_index do |heading, index|
        level = heading.name.downcase
        text = heading.text.strip
        id = heading['id'] || generate_id.call(text, index)
        heading['id'] = id

        link_html = "<a href='##{id}' title='#{text}'>#{text}</a>"

        if level == "h2"
          current_li = Nokogiri::XML::Node.new("li", doc)
          current_li.inner_html = link_html
          toc_ul.add_child(current_li)
        elsif level == "h3" && current_li
          sub_ul = current_li.at("ul") || Nokogiri::XML::Node.new("ul", doc)
          sub_li = Nokogiri::XML::Node.new("li", doc)
          sub_li.inner_html = link_html
          sub_ul.add_child(sub_li)
          current_li.add_child(sub_ul) unless current_li.at("ul")
        end
      end

      first_h2 = doc.at("h2")
      first_h2.add_previous_sibling(toc_fragment) if first_h2

      doc.to_html
    end

    def convert_images_to_amp(html)
      doc = Nokogiri::HTML.fragment(html)
      doc.css('img').each do |img|
        next if img['data-amp-skip'] == 'true'

        src = img['src'] || img['data-src']
        next unless src

        width, height = FastImage.size(src, raise_on_failure: false)
        width ||= 600
        height ||= 400

        amp_img = Nokogiri::XML::Node.new('amp-img', doc)
        img.attributes.each { |name, attr| amp_img[name] = attr.value }
        amp_img['src'] = src
        amp_img['width'] = width.to_s
        amp_img['height'] = height.to_s
        amp_img['layout'] = 'responsive'

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

        width, height = img['width'] && img['height'] ? [img['width'], img['height']] : FastImage.size(src) rescue [1600, 900]

        amp_img = Nokogiri::XML::Node.new('amp-img', doc)
        amp_img['src'] = src || '/assets/img/ASIBUKA-Blue.webp'
        amp_img['alt'] = img['alt'] || 'image'
        amp_img['width'] = width.to_s
        amp_img['height'] = height.to_s
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
          src = '/assets/img/ASIBUKA-Blue.webp' if src.nil? || src.strip.empty?

          width, height = img['width'] && img['height'] ? [img['width'], img['height']] : FastImage.size(src) rescue [1600, 900]

          amp_img['src'] = src
          amp_img['alt'] = img['alt'] || 'image'
          amp_img['width'] = width.to_s
          amp_img['height'] = height.to_s
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

    def convert_internal_links_to_amp(html)
      doc = Nokogiri::HTML5.fragment(html)
      doc.css('a[href]').each do |a|
        href = a['href']
        next if href.nil? || href.empty?
        next if href =~ /^https?:\/\// || href.include?('/amp')

        amp_href = href.sub(/\/$/, '') + '/amp/'
        a['href'] = amp_href
      end
      doc.to_html
    end

    def remove_scripts(html)
      doc = Nokogiri::HTML.fragment(html)
      doc.css('script').remove
      doc.to_html
    end
  end
end
