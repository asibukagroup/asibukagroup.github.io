module Jekyll
    class AMPPage < Page
      def initialize(site, base, original, output_html)
        @site = site
        @base = base
  
        # Generate the AMP URL: /post-name/amp/index.html
        url_path = original.url.chomp("/").sub(%r{^/}, "")
        @dir = url_path.empty? ? "amp" : File.join(url_path, "amp")
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
        markdown = site.find_converter_instance(Jekyll::Converters::Markdown)
  
        # AMP for posts
        site.posts.docs.each do |post|
          next if post.data['skip_amp'] == true
  
          amp_html = markdown.convert(post.content)
          site.pages << AMPPage.new(site, site.source, post, amp_html)
          Jekyll.logger.info "AMP:", "Generated AMP for post: #{post.url}"
        end
  
        # AMP for pages (excluding homepage)
        site.pages.clone.each do |page|
          next if page.url.include?('/amp/')
          next if page.data['skip_amp'] == true
          next unless page.path.end_with?('.md', '.markdown')
          next if page.url == "/" # skip homepage
  
          amp_html = markdown.convert(page.content || "")
          site.pages << AMPPage.new(site, site.source, page, amp_html)
          Jekyll.logger.info "AMP:", "Generated AMP for page: #{page.url}"
        end
      end
    end
  end
  