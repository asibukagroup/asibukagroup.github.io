require 'nokogiri'

module Jekyll
  class TocInjector < Jekyll::Generator
    priority :lowest
    safe true

    def generate(site)
      # Nothing needed here – handled in hooks
    end
  end

  Hooks.register [:pages, :documents], :post_render do |doc|
    next unless doc.output_ext == '.html'
    next if doc.data['is_amp']

    doc.output = insert_toc(doc.output)
  end

  def self.insert_toc(html)
    doc = Nokogiri::HTML5.fragment(html)
    headings = doc.css('h2, h3, h4, h5, h6')
    return html if headings.empty?

    toc_list = Nokogiri::XML::Node.new('ul', doc)
    toc_list['class'] = 'toc'

    headings.each do |heading|
      id = heading['id'] || heading.content.downcase.strip.gsub(/[^\w]+/, '-')
      heading['id'] = id

      li = Nokogiri::XML::Node.new('li', doc)
      li['class'] = "toc-#{heading.name}"

      a = Nokogiri::XML::Node.new('a', doc)
      a['href'] = "##{id}"
      a.content = heading.text

      li.add_child(a)
      toc_list.add_child(li)
    end

    toc_container = Nokogiri::XML::Node.new('nav', doc)
    toc_container['class'] = 'toc-container'
    toc_container.add_child(toc_list)

    first_h2 = doc.at_css('h2')
    if first_h2
      first_h2.add_previous_sibling(toc_container)
    else
      doc.children.first.add_previous_sibling(toc_container)
    end

    doc.to_html
  end
end
