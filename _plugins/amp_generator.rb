module Jekyll
    class AMPPageGenerator < Generator
      safe true
      priority :low
  
      def generate(site)
        site.posts.docs.each do |post|
          amp_post = post.dup
          amp_post.data['layout'] = 'amp'
          amp_post.data['amp'] = true
          amp_post.data['permalink'] = post.url.chomp('/') + "/amp/"
          site.pages << amp_post
        end
      end
    end
  end