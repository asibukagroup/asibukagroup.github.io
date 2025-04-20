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
    # 3. It's a Jekyll Archives page (layout: archive)
    if relative_path =~ %r{^/?[^/]+\.md$} ||
       relative_path.start_with?('_static/') ||
       doc.data['layout'] == 'archive'
      next
    end

    doc.output = insert_toc(doc.output)
  end

  # ToC injection logic
  def self.insert_toc(html)
    doc = Nokogiri::HTML5.parse(html)
    body = doc.at('body')
    return html unless body

    headings = body.css('h2, h3, h4, h5, h6')
    return html if headings.empty?

    # Build ToC list
    toc_list = Nokogiri::XML::Node.new('ul', doc)
    toc_list['class'] = 'toc'
    toc_list['itemscope'] = 'itemscope'
    toc_list['itemtype'] = 'http://schema.org/ItemList'

    headings.each_with_index do |heading, index|
      id = heading['id'] || heading.content.downcase.strip.gsub(/[^\w]+/, '-')
      heading['id'] = id

      li = Nokogiri::XML::Node.new('li', doc)
      li['class'] = "toc-#{heading.name}"
      li['itemprop'] = 'itemListElement'

      a = Nokogiri::XML::Node.new('a', doc)
      a['href'] = "##{id}"
      a['title'] = heading.text
      a['itemprop'] = 'url'
      a.content = heading.text

      li.add_child(a)
      toc_list.add_child(li)
    end

    # Wrap in details and nav
    summary = Nokogiri::XML::Node.new('summary', doc)
    summary.content = 'Daftar Isi'

    details = Nokogiri::XML::Node.new('details', doc)
    details['class'] = 'toc'
    details['open'] = 'open'
    details.add_child(summary)
    details.add_child(toc_list)

    nav = Nokogiri::XML::Node.new('nav', doc)
    nav['class'] = 'toc-container'
    nav.add_child(details)

    # Insert before first h2 or at top of body
    first_h2 = body.at_css('h2')
    if first_h2
      first_h2.add_previous_sibling(nav)
    else
      body.children.first.add_previous_sibling(nav)
    end

    doc.to_html
  end
end
