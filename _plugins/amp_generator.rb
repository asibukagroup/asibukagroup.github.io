module Jekyll
    class AMPPage < Page
      def initialize(site, base, original_page, output_html)
        @site = site
        @base = base
        url_path = original_page.url.chomp("/").sub(%r{^/}, "")
        @dir = url_path.empty? ? "amp" : File.join(url_path, "amp")
        @name = 'index.html'
        self.process(@name)
        self.read_yaml(File.join(base, '_layouts'), 'amp.html')
        self.data = original_page.data.dup
        self.data['layout'] = 'amp'
        self.data['canonical_url'] = original_page.url
        self.content = output_html
      end
    end
    class AMPGenerator < Generator
      safe true
      priority :lowest
      def generate(site)
        puts "🚀 AMP Generator is running..."
        markdown_converter = site.find_converter_instance(Jekyll::Converters::Markdown)
        site.posts.docs.each do |post|
          puts "✅ AMP for post: #{post.url}"
          amp_html = markdown_converter.convert(post.content)
          site.pages << AMPPage.new(site, site.source, post, amp_html)
        end
        site.pages.clone.each do |page|
          next if page.url.include?('/amp/')
          next if page.data['skip_amp'] == true
          homepage_paths = ['index.md', 'index.markdown', 'index.html']
          next if page.url == '/' || homepage_paths.include?(page.path)
          next unless page.path.end_with?('.md', '.markdown', '.html')
          puts "✅ AMP for page: #{page.url}"
          amp_html = markdown_converter.convert(page.content || "")
          site.pages << AMPPage.new(site, site.source, page, amp_html)
        end
      end
    end
  end
  