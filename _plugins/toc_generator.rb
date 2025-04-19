Jekyll::Hooks.register [:pages, :posts], :post_render do |doc|
    next unless doc.output_ext == ".html"
    next unless doc.data['toc'] != false
    next unless doc.respond_to?(:collection) && doc.collection.label == "posts"
  
    # Check for AMP version
    is_amp = doc.path.include?('/amp/')
  
    # Use rendered HTML instead of raw Markdown
    html = Nokogiri::HTML::DocumentFragment.parse(doc.output)
    headings = html.css("h2, h3")
    next if headings.empty?
  
    # Build TOC (use amp-accordion for AMP pages)
    toc_fragment = Nokogiri::HTML::DocumentFragment.parse(
      is_amp ?
        "<amp-accordion class='toc' layout='container'><section><h4>📑 Daftar Isi</h4><ul></ul></section></amp-accordion>" :
        "<details class='toc' open><summary>📑 Daftar Isi</summary><ul></ul></details>"
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
        current_li = Nokogiri::XML::Node.new("li", html)
        current_li.inner_html = link_html
        toc_ul.add_child(current_li)
      elsif level == "h3" && current_li
        sub_ul = current_li.at("ul") || Nokogiri::XML::Node.new("ul", html)
        sub_li = Nokogiri::XML::Node.new("li", html)
        sub_li.inner_html = link_html
        sub_ul.add_child(sub_li)
        current_li.add_child(sub_ul) unless current_li.at("ul")
      end
    end
  
    # Insert TOC above the first <h2>
    first_h2 = html.at("h2")
    first_h2.add_previous_sibling(toc_fragment) if first_h2
  
    doc.output = html.to_html
  end
  