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
        page.content = inject_toc(page) if page.data['toc'] != false
        site.pages << generate_amp_page(site, page)
      end

      site.collections.each_value do |collection|
        collection.docs.select { |doc| valid_md_doc?(doc, collections) && !doc.data['is_amp'] }.each do |doc|
          doc.content = inject_toc(doc) if doc.data['toc'] != false
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

    def inject_toc(doc)
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

    # Your other conversion methods remain unchanged (convert_images_to_amp, convert_iframes_to_amp, etc.)
  end
end
