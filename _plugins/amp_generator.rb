module Jekyll
    class AMPPage < Page
      def initialize(site, base, post)
        @site = site
        @base = base
        @dir  = File.join(post.url.sub(%r{^/}, ''), 'amp')
        @name = 'index.html'
  
        self.process(@name)
        self.read_yaml(File.join(base, '_layouts'), 'amp.html')
        self.data['title'] = post.data['title']
        self.data['canonical_url'] = post.url
        self.data['layout'] = 'amp'
        self.content = post.output
      end
    end
    class AMPGenerator < Generator
      safe true
      priority :lowest
  
      def generate(site)
        site.posts.docs.each(&:render)
        site.posts.docs.each do |post|
          site.pages << AMPPage.new(site, site.source, post)
        end
      end
    end
  end  