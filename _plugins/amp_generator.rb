module Jekyll
    class AMPPage < Page
      def initialize(site, base, original_page, output_html)
        @site = site
        @base = base
        url_path = original_page.url.chomp("/").sub(%r{^/}, "")
        @dir = url_path.empty? ? "amp" : File.join(url_path, "amp")
        @name = 'index.html'
        puts "Generating AMP for #{original_page.url} → #{File.join(@dir, @name)}"
  
        self.process(@name)
        self.read_yaml(File.join(base, '_layouts'), 'amp.html')
        self.data = original_page.data.clone
        self.data['layout'] = 'amp'
        self.data['canonical_url'] = original_page.url
        self.content = output_html
      end
    end
  
    class AMPGenerator < Generator
      safe true
      priority :lowest
  
      def generate(site)
        markdown_converter = site.find_converter_instance(Jekyll::Converters::Markdown)
        site.posts.docs.each do |post|
          output = post.output || markdown_converter.convert(post.content)
          site.pages << AMPPage.new(site, site.source, post, output)
        end
        site.pages.clone.each do |page|
          next if page.url.include?('/amp/')
          next if page.data['skip_amp'] == true
          next unless page.path.end_with?('.md', '.markdown')
  
          output = page.output || markdown_converter.convert(page.content || "")
          site.pages << AMPPage.new(site, site.source, page, output)
        end
      end
    end
  end  