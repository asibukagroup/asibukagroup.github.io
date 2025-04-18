require 'nokogiri'

module Jekyll
  class TOCGenerator < Generator
    safe true
    priority :low

    def generate(site)
      site.pages.each { |page| inject_toc(page) }
      site.posts.docs.each { |post| inject_toc(post) }
    end

    def inject_toc(doc)
      return unless doc.output_ext == ".html"
      return unless doc.output.include?("<h2")
      return if doc.data['toc'] == false

      html = Nokogiri::HTML::DocumentFragment.parse(doc.output)
      headings = html.css("h2, h3")
      return if headings.empty?

      # TOC wrapper with open by default
      toc_html = Nokogiri::HTML::DocumentFragment.parse(
        "<details class='toc' open><summary>📑 Table of Contents</summary><ul></ul></details>"
      )
      toc_ul = toc_html.at("ul")
      current_li = nil

      headings.each_with_index do |heading, index|
        level = heading.name.downcase
        text = heading.text.strip
        id = heading['id'] || generate_id(text, index)
        heading['id'] = id

        # SVG icon for anchor
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

      # Insert TOC before the first <h2>
      first_h2 = html.at("h2")
      first_h2.add_previous_sibling(toc_html)

      doc.output = html.to_html
    end

    def generate_id(text, index)
      slug = text.downcase.strip.gsub(/\s+/, "-").gsub(/[^a-z0-9\-]/, "")
      "toc-#{index}-#{slug}"
    end
  end
end