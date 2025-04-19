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
  def initialize(site, base, dir, page)
    @site = site
    @base = base
    @dir  = File.join(dir, 'amp')
    @name = page.name

    self.process(@name)
    self.content = page.content.dup
    self.data = page.data.dup
    self.data['layout'] = 'amp'
    self.data['is_amp'] = true
    self.data['canonical_url'] = page.url
  end
end

class AmpGenerator < Jekyll::Generator
  safe true
  priority :lowest

  def initialize(config)
    super
    @config = config
    @markdown_converter = Jekyll::Converters::Markdown.new(config)
  end

  def generate(site)
    amp_pages = []

    site.pages.each do |page|
      next if skip_amp?(page)

      amp_page = AmpPage.new(site, site.source, page.dir, page)
      amp_page.output = convert_to_amp(amp_page)
      amp_pages << amp_page
    end

    site.posts.docs.each do |post|
      next if skip_amp?(post)

      amp_post = post.dup
      amp_post.data = post.data.dup
      amp_post.data['layout'] = 'amp'
      amp_post.data['is_amp'] = true
      amp_post.data['canonical_url'] = post.url
      amp_post.output = convert_to_amp(amp_post)
      amp_post.url = File.join(post.url, 'amp', '/')
      amp_pages << amp_post
    end

    site.pages.concat(amp_pages.select { |p| p.is_a?(Jekyll::Page) })
    site.posts.docs.concat(amp_pages.select { |p| p.is_a?(Jekyll::Document) })
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

  def skip_amp?(page)
    page.data['is_amp'] || page.data['layout'] == 'amp'
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
