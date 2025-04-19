# _plugins/amp_generator.rb

require 'jekyll'
require 'nokogiri'
require 'fastimage'

module HTMLUtils
  def self.convert_img_to_amp(doc)
    doc.css('img').each do |img|
      src = img['src'] || img['data-src']
      next unless src

      width, height = FastImage.size(src) rescue [600, 400]
      next unless width && height

      amp_img = Nokogiri::XML::Node.new('amp-img', doc)
      img.attributes.each { |name, attr| amp_img[name] = attr.value }
      amp_img['width']  = width.to_s
      amp_img['height'] = height.to_s
      amp_img['layout'] = 'responsive'
      amp_img.name = 'amp-img'

      img.replace(amp_img)
    end
  end

  def self.remove_scripts(doc)
    doc.css('script:not([type="application/ld+json"])').remove
  end

  def self.minify_html(doc)
    doc.to_html.gsub(/>\s+</, '><').strip
  end
end

class AmpPage < Jekyll::Page
  def initialize(site, base, dir, page_or_post, output)
    @site = site
    @base = base
    @dir  = File.join(dir, 'amp')
    @name = 'index.html'

    self.process(@name)
    self.content = page_or_post.content.dup
    self.output = output
    self.data = page_or_post.data.dup
    self.data['layout'] = 'amp'
    self.data['is_amp'] = true
    self.data['canonical_url'] = page_or_post.url
  end
end

class AmpGenerator < Jekyll::Generator
  safe true
  priority :lowest

  def initialize(config)
    super
    @markdown_converter = Jekyll::Converters::Markdown.new(config)
  end

  def generate(site)
    amp_pages = []

    (site.pages + site.posts.docs).each do |item|
      next if item.data['is_amp'] || item.data['layout'] == 'amp'

      output = convert_to_amp(item)
      amp_page = AmpPage.new(site, site.source, item.dir, item, output)
      amp_pages << amp_page
    end

    site.pages.concat(amp_pages)
  end

  def convert_to_amp(page)
    html = @markdown_converter.convert(page.content)
    doc = Nokogiri::HTML::DocumentFragment.parse(html)

    HTMLUtils.convert_img_to_amp(doc)
    HTMLUtils.remove_scripts(doc)

    toc = generate_toc(doc)
    insert_toc(doc, toc)

    HTMLUtils.minify_html(doc)
  end

  def generate_toc(doc)
    toc_items = doc.css('h2').map do |h2|
      id = h2['id'] || h2.content.strip.downcase.gsub(/\s+/, '-').gsub(/[^a-z0-9\-]/, '')
      h2['id'] = id
      "<li><a href='##{id}'>#{h2.content.strip}</a></li>"
    end
    return '' if toc_items.empty?

    <<~HTML
      <div class="toc-container">
        <details open>
          <summary>📑 Daftar Isi</summary>
          <ul class="toc-list">
            #{toc_items.join("\n")}
          </ul>
        </details>
      </div>
    HTML
  end

  def insert_toc(doc, toc_html)
    first_h2 = doc.at_css('h2')
    return doc unless first_h2

    toc_node = Nokogiri::HTML::DocumentFragment.parse(toc_html)
    first_h2.add_previous_sibling(toc_node)
    doc
  end
end