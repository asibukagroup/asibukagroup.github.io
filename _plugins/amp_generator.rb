module Jekyll
    class AMPPage < Page
      def initialize(site, base, post)
        @site = site
        @base = base
        @dir  = File.join(post.url.sub(%r{^/}, ''), 'amp')
        @name = 'index.html'
  
        self.process(@name)
        self.data = post.data.clone
        self.data['layout'] = 'amp'
        self.data['canonical_url'] = post.url
        self.content = post.content
      end
    end
  
    class AMPGenerator < Generator
      priority :lowest
      safe true
  
      def generate(site)
        site.posts.docs.each do |post|
          site.pages << AMPPage.new(site, site.source, post)
        end
      end
    end
  end
  