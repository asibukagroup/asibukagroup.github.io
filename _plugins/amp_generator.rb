module Jekyll
    class AMPPage < Page
      def initialize(site, base, original, output_html)
        @site = site
        @base = base
        is_homepage = original.url == "/"
        @dir = is_homepage ? "amp" : File.join(original.url.chomp("/").sub(%r{^/}, ""), "amp")
        @name = 'index.html'
        self.process(@name)
        self.read_yaml(File.join(base, '_layouts'), 'amp.html')
        self.data = original.data.dup
        self.data['layout'] = 'amp'
        self.data['canonical_url'] = original.url
        self.content = output_html
      end
    end
  
    class AMPGenerator < Generator
      safe true
      priority :lowest
  
      def generate(site)
        markdown_converter = site.find_converter_instance(Jekyll::Converters::Markdown)
  
        (site.pages + site.posts.docs).each do |doc|
          next if doc.url.include?('/amp/') || doc.data['skip_amp']
          next unless doc.extname == ".md" || doc.extname == ".markdown"
  
          output = markdown_converter.convert(doc.content || "")
          site.pages << AMPPage.new(site, site.source, doc, output)
        end
      end
    end
  end
  