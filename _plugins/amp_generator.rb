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
        self.data['title'] = original_page.data['title']
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
  
        # Generate AMP for all posts
        site.posts.docs.each do |post|
          post_output = post.output || markdown_converter.convert(post.content)
          site.pages << AMPPage.new(site, site.source, post, post_output)
        end
  
        # Generate AMP for pages (including homepage)
        site.pages.each do |page|
          next if page.url.include?('/amp/') # skip already AMP pages
          next if page.data['skip_amp'] == true
  
          # Render HTML content if needed
          page_output = if page.output
                          page.output
                        else
                          markdown_converter.convert(page.content || "")
                        end
  
          site.pages << AMPPage.new(site, site.source, page, page_output)
        end
      end
    end
  end