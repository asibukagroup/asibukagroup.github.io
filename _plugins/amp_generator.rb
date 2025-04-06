module Jekyll
    class AMPPage < Page
      def initialize(site, base, original_page, output_html)
        @site = site
        @base = base
        @dir  = File.join(original_page.url.sub(%r{^/}, ''), 'amp')
        @name = 'index.html'
  
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
  
        # Posts AMP
        site.posts.docs.each do |post|
          output = post.output || markdown_converter.convert(post.content)
          site.pages << AMPPage.new(site, site.source, post, output)
        end
  
        # Pages AMP
        site.pages.clone.each do |page|
          next if page.url.include?('/amp/')
          next if page.data['skip_amp'] == true
          next unless page.path.end_with?('.md', '.markdown') # 💡 only convert markdown
  
          output = page.output || markdown_converter.convert(page.content || "")
          site.pages << AMPPage.new(site, site.source, page, output)
        end
      end
    end
  end  