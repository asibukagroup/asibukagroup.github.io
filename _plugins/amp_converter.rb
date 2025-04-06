require 'nokogiri'

module Jekyll
  class AMPConverter < Jekyll::Generator
    safe true
    priority :low

    def generate(site)
      process_docs(site.pages)
      process_docs(site.posts.docs)
    end

    private

    def process_docs(docs)
      docs.each do |doc|
        next unless amp_page?(doc)
        next unless doc.output

        begin
          doc.output = convert_to_amp(doc.output)
        rescue => e
          Jekyll.logger.warn "AMPConverter Error:", e.message
        end
      end
    end

    def amp_page?(doc)
      doc.data['layout'] == 'amp'
    end

    def convert_to_amp(html)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)

      # Convert <img> to <amp-img>
      doc.css('img').each do |img|
        amp_img = Nokogiri::XML::Node.new("amp-img", doc)
        img.attributes.each { |name, attr| amp_img[name] = attr.value }
        amp_img['layout'] ||= 'responsive'
        amp_img['width'] ||= '600'
        amp_img['height'] ||= '400'
        img.replace(amp_img)
      end

      # Convert <iframe> to <amp-iframe>
      doc.css('iframe').each do |iframe|
        amp_iframe = Nokogiri::XML::Node.new("amp-iframe", doc)
        iframe.attributes.each { |name, attr| amp_iframe[name] = attr.value }
        amp_iframe['layout'] ||= 'responsive'
        amp_iframe['sandbox'] ||= 'allow-scripts allow-same-origin'
        amp_iframe['width'] ||= '600'
        amp_iframe['height'] ||= '400'
        iframe.replace(amp_iframe)
      end

      # Remove <script> tags (except AMP script)
      doc.css('script').each do |script|
        script.remove unless script['src']&.include?('https://cdn.ampproject.org/')
      end

      doc.to_html
    end
  end
end