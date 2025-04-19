require 'nokogiri'

module Jekyll
  class TocInjector < Jekyll::Generator
    priority :lowest
    safe true

    def generate(site)
      # No-op
    end
  end

  # Hook after rendering
  Hooks.register [:pages, :documents], :post_render do |doc|
    next unless doc.output_ext == '.html'
    next if doc.data['is_amp']

    relative_path = doc.relative_path || doc.path

    # Skip if:
    # 1. It's a Markdown file at the root level (e.g., about.md)
    # 2. It's a Markdown file inside the _static collection
    if relative_path =~ %r{^/?[^/]+\.md$} || relative_path.start_with?('_static/')
      next
    end

    doc.output = insert_toc(doc.output)
  end

  # ToC injection logic
  def self.insert_toc(html)
    doc = Nokogiri::HTML5.fragment(html)
    headings = doc.css('h2, h3, h4, h5, h6')
    return html if headings.empty?

    toc_list = Nokogiri::XML::Node.new('ul', doc)
    toc_list['class'] = 'toc'
    toc_list['itemscope'] = 'itemscope'   # Add itemscope for ItemList microdata
    toc_list['itemtype'] = 'http://schema.org/ItemList' # Define ItemList schema

    headings.each_with_index do |heading, index|
      id = heading['id'] || heading.content.downcase.strip.gsub(/[^\w]+/, '-')
      heading['id'] = id

      li = Nokogiri::XML::Node.new('li', doc)
      li['class'] = "toc-#{heading.name}"
      li['itemprop'] = 'itemListElement'  # Define each list item as an item in ItemList

      a = Nokogiri::XML::Node.new('a', doc)
      a['href'] = "##{id}"
      a['title'] = heading.text
      a.content = heading.text
      a['itemprop'] = 'url'  # Define the URL property for the item

      # Add the <a> element inside the <li>
      li.add_child(a)
      toc_list.add_child(li)
    end

    # Create a <nav> element with class 'toc-container'
    nav = Nokogiri::XML::Node.new('nav', doc)
    nav['class'] = 'toc-container'

    # Create a <details> element to make the ToC collapsible
    details = Nokogiri::XML::Node.new('details', doc)
    details['class'] = 'toc'
    details['open'] = 'open'

    # Create a <summary> as the clickable title for ToC
    summary = Nokogiri::XML::Node.new('summary', doc)
    summary.content = 'Daftar Isi'
    details.add_child(summary)

    # Add the ToC list inside the <details> element
    details.add_child(toc_list)

    # Add the <details> element inside the <nav> container
    nav.add_child(details)

    # Inject ToC into the document
    first_h2 = doc.at_css('h2')
    if first_h2
      first_h2.add_previous_sibling(nav)
    else
      doc.children.first.add_previous_sibling(nav)
    end

    doc.to_html
  end
end
