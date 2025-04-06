# _plugins/amp_converter.rb
require 'nokogiri'

module Jekyll
  class AMPConverter < Jekyll::Generator
    def generate(site)
      site.pages.each do |page|
        convert_to_amp(page) if amp_page?(page)
      end

      site.posts.docs.each do |post|
        convert_to_amp(post) if amp_page?(post)
      end
    end

    private

    def amp_page?(doc)
      doc.data['layout'] == 'amp'
    end

    def convert_to_amp(doc)
      return unless doc.output && doc.output.include?('<html')

      doc.output = process_amp(doc.output)
    end

    def process_amp(html)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)

      # Replace <img> with <amp-img>
      doc.css('img').each do |img|
        amp_img = Nokogiri::XML::Node.new("amp-img", doc)
        img.attributes.each { |name, attr| amp_img[name] = attr.value }
        amp_img['layout'] ||= 'responsive'
        amp_img['width'] ||= '600'
        amp_img['height'] ||= '400'
        img.replace(amp_img)
      end

      # Replace <iframe> with <amp-iframe>
      doc.css('iframe').each do |iframe|
        amp_iframe = Nokogiri::XML::Node.new("amp-iframe", doc)
        iframe.attributes.each { |name, attr| amp_iframe[name] = attr.value }
        amp_iframe['layout'] ||= 'responsive'
        amp_iframe['sandbox'] ||= 'allow-scripts allow-same-origin'
        amp_iframe['width'] ||= '600'
        amp_iframe['height'] ||= '400'
        iframe.replace(amp_iframe)
      end

      # Remove all <script> except AMP core script
      doc.css('script').each do |script|
        unless script['src'] == 'https://cdn.ampproject.org/v0.js'
          script.remove
        end
      end

      doc.to_html
    end
  end
end
