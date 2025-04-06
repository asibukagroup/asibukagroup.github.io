module Jekyll
    class AMPPage < Page
        def initialize(site, base, original, output_html)
          @site = site
          @base = base
          url_path = original.url.chomp("/").sub(%r{^/}, "")
          # Place all AMP versions under /amp/
          @dir = File.join("amp", url_path)
          @name = "index.html"
          self.process(@name)
          self.read_yaml(File.join(base, "_layouts"), "amp.html")
          self.data = original.data.dup
          self.data["layout"] = "amp"
          self.data["canonical_url"] = original.url
          self.content = page.output
        end
    end
    class AMPGenerator < Generator
        safe false
        priority :lowest
        def generate(site)
            markdown = site.find_converter_instance(Jekyll::Converters::Markdown)
            site.posts.docs.each do |post|
            next if post.data['skip_amp'] == true
                amp_html = markdown.convert(post.content)
                site.pages << AMPPage.new(site, site.source, post, amp_html)
                Jekyll.logger.info "AMP:", "Generated AMP for post: #{post.url}"
            end
            site.pages.clone.each do |page|
            next if page.url.include?('/amp/')
            next if page.data['skip_amp'] == true
            next unless page.path.end_with?('.md', '.markdown', ".html")
                amp_html = page.output || markdown.convert(page.content || "")
                site.pages << AMPPage.new(site, site.source, page, amp_html)
                Jekyll.logger.info "AMP:", "Generated AMP for page: #{page.url}"
            end
        end
    end
end
  