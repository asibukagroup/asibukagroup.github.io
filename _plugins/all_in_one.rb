module Jekyll
  class AmpGenerator < Generator
    safe true
    priority :low

    def generate(site)
      collections = site.config['collections'].keys

      # Process .md files in the root (index.md, blog.md, etc.)
      site.pages.each do |page|
        next unless valid_md_page?(page)
        next if page.data['is_amp']
        site.pages << generate_amp_page(site, page)
      end

      # Process collection documents (e.g., posts)
      site.collections.each_value do |collection|
        collection.docs.each do |doc|
          next unless valid_md_doc?(doc, collections)
          next if doc.data['is_amp']
          site.pages << generate_amp_page(site, doc)
        end
      end

      # Process archive pages from jekyll-archives
      site.pages.each do |page|
        next unless archive_page?(page)
        next if page.data['is_amp']
        site.pages << generate_amp_archive(site, page)
      end
    end

    private

    def valid_md_doc?(doc, collections)
      doc.path.end_with?('.md') && collections.any? { |c| doc.path.include?("_#{c}/") }
    end

    def valid_md_page?(page)
      page.path.end_with?('.md') && File.dirname(page.path) == '.'
    end

    def archive_page?(page)
      # Check if this is a jekyll-archives generated page (based on layout or other criteria)
      page.data['layout'] == 'archive' && !page.data['is_amp']
    end

    def generate_amp_page(site, original)
      amp_data = original.data.dup
      amp_data['is_amp'] = true
      amp_data['permalink'] = original.url.sub(/\/$/, '') + '/amp/'

      basename = File.basename(original.path, File.extname(original.path))
      amp_filename = "#{basename}-amp.md"
      amp_dir = File.dirname(original.path.sub(site.source, ''))

      amp_page = PageWithoutAFile.new(site, site.source, amp_dir, amp_filename)
      amp_page.content = original.content
      amp_page.data = amp_data

      amp_page
    end

    def generate_amp_archive(site, page)
      amp_data = page.data.dup
      amp_data['is_amp'] = true
      amp_data['permalink'] = page.url.sub(/\/$/, '') + '/amp/'

      # Create a new AMP page for the archive
      amp_page = PageWithoutAFile.new(site, site.source, page.dir, 'index-amp.html')
      amp_page.content = generate_archive_content(site, page) # Generate content for the archive
      amp_page.data = amp_data

      amp_page
    end

    def generate_archive_content(site, page)
      # Gather the posts based on the current archive's filter (tags, categories, year, month)
      posts = get_posts_for_archive(site, page)

      # Loop through the posts and render them
      content = ""
      posts.each do |post|
        content += "<article><h2><a href='#{post.url}'>#{post.data['title']}</a></h2></article>"
      end

      content
    end

    def get_posts_for_archive(site, page)
      # Check if the page is a tag archive or category archive
      if page.data['tags']
        # Posts tagged with any of the tags listed in the page's data
        site.posts.docs.select { |post| (post.data['tags'] & page.data['tags']).any? }
      elsif page.data['category']
        # Posts in the specified category
        site.posts.docs.select { |post| post.data['category'] == page.data['category'] }
      elsif page.data['year'] && page.data['month']
        # Posts within the specified year and month
        site.posts.docs.select do |post|
          post.date.year == page.data['year'] && post.date.month == page.data['month']
        end
      else
        site.posts.docs # If no filter is applied, return all posts
      end
    end
  end
end
