# _plugins/amp_generator.rb

module Jekyll
    class AmpFile < Page
      def initialize(site, base, original, permalink, output_dir)
        @site = site
        @base = base
        @dir = output_dir
        @name = "index.html"
        self.process(@name)
  
        self.content = original.content
        self.data = original.data.dup
  
        self.data["layout"] = "amp"
        self.data["permalink"] = permalink
        self.data["canonical_url"] = original.url
      end
    end
  
    class AmpPost < Document
      def initialize(site, original, permalink, output_dir)
        super(original.path, { site: site, collection: site.posts })
        self.content = original.content
        self.data = original.data.dup
  
        self.data["layout"] = "amp"
        self.data["permalink"] = permalink
        self.data["canonical_url"] = original.url
        @output = nil
  
        # Force output path
        @relative_path = File.join(output_dir, "index.html")
      end
    end
  
    class AmpGenerator < Generator
      safe true
      priority :low
  
      def generate(site)
        # === PAGES ===
        site.pages.each do |page|
          next unless page.extname == ".md" || page.ext == ".md"
          next if page.url.include?("/amp/")
  
          amp_permalink = File.join((page.data["permalink"] || page.url).sub(/\/$/, ""), "amp", "/")
          output_dir = page.url == "/" ? "amp" : amp_permalink.sub(/^\//, "").sub(/index\.html$/, "")
  
          site.pages << AmpFile.new(site, site.source, page, amp_permalink, output_dir)
        end
  
        # === POSTS ===
        site.posts.docs.each do |post|
          next if post.url.include?("/amp/")
  
          amp_permalink = File.join(post.url.sub(/\/$/, ""), "amp", "/")
          output_dir = amp_permalink.sub(/^\//, "").sub(/index\.html$/, "")
  
          amp_post = post.dup
          amp_post.data = post.data.dup
          amp_post.content = post.content
          amp_post.data["layout"] = "amp"
          amp_post.data["permalink"] = amp_permalink
          amp_post.data["canonical_url"] = post.url
  
          site.posts.docs << amp_post
        end
      end
    end
  end
  