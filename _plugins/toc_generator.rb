Jekyll::Hooks.register [:pages, :posts], :post_render do |doc|
    # Skip non-collection pages like 404.html or root-level files
    next unless doc.respond_to?(:collection) && doc.collection # Ensure it belongs to a collection
    next if doc.path.include?('/_posts/') || doc.path.include?('/_collection/') # Customize based on your collections
    
    # Skip if the TOC is explicitly disabled
    next unless doc.data['toc'] != false
    
    # Check if this is an AMP version
    is_amp = doc.path.include?('/amp/') # Adjust this based on your AMP URL structure
  
    # Use only content from the Markdown file, converted to HTML
    site = doc.site
    converter = site.find_converter_instance(Jekyll::Converters::Markdown)
    raw_html = converter.convert(doc.content)
    
    html = Nokogiri::HTML::DocumentFragment.parse(raw_html)
    headings = html.css("h2, h3")
    next if headings.empty?
    
    toc_html = Nokogiri::HTML::DocumentFragment.parse(
      "<details class='toc' open><summary>📑 Daftar Isi</summary><ul></ul></details>"
    )
    toc_ul = toc_html.at("ul")
    current_li = nil
    
    # Define generate_id locally
    generate_id = ->(text, index) do
      slug = text.downcase.strip.gsub(/\s+/, "-").gsub(/[^a-z0-9\-]/, "")
      "toc-#{index}-#{slug}"
    end
    
    headings.each_with_index do |heading, index|
      level = heading.name.downcase
      text = heading.text.strip
      id = heading['id'] || generate_id.call(text, index)
      heading['id'] = id
    
      anchor_icon = <<~SVG.strip
        <svg class="toc-icon" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 13a5 5 0 0 0 7.07 0l1.41-1.41a5 5 0 0 0-7.07-7.07l-1.41 1.41"></path><path d="M14 11a5 5 0 0 0-7.07 0l-1.41 1.41a5 5 0 0 0 7.07 7.07l1.41-1.41"></path></svg>
      SVG
    
      link_html = "#{anchor_icon}<a href='##{id}' title='#{text}'>#{text}</a>"
    
      if level == "h2"
        current_li = Nokogiri::XML::Node.new("li", html)
        current_li.inner_html = link_html
        toc_ul.add_child(current_li)
      elsif level == "h3"
        if current_li
          sub_ul = current_li.at("ul") || Nokogiri::XML::Node.new("ul", html)
          sub_li = Nokogiri::XML::Node.new("li", html)
          sub_li.inner_html = link_html
          sub_ul.add_child(sub_li)
          current_li.add_child(sub_ul) unless current_li.at("ul")
        end
      end
    end
    
    # Insert TOC into the final output just before the first <h2>
    final_html = Nokogiri::HTML::DocumentFragment.parse(doc.output)
    first_h2 = final_html.at("h2")
    first_h2.add_previous_sibling(toc_html) if first_h2
    
    # Only include the TOC in AMP if it's an AMP page
    if is_amp
      # Ensure that the TOC is AMP-compliant (for example, remove any non-AMP elements)
      toc_html.css('details').each do |details|
        details['amp'] = 'true'  # Make sure the details element is AMP-compliant if necessary
      end
    end
  
    doc.output = final_html.to_html
  end
  