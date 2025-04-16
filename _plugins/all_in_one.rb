module Jekyll
  class AmpGenerator < Generator
    safe true

    def generate(site)
      # Loop through all pages, posts, and collections to find .md files
      site.pages.each do |page|
        process_page(page, site) if page_is_markdown?(page)
      end

      site.posts.docs.each do |post|
        process_page(post, site) if page_is_markdown?(post)
      end

      site.collections.each do |name, collection|
        collection.docs.each do |doc|
          process_page(doc, site) if page_is_markdown?(doc)
        end
      end
    end

    private

    def page_is_markdown?(page)
      page.extname == ".md"
    end

    def process_page(page, site)
      # Skip if the page is already an AMP version
      return if page.data['is_amp']

      # Duplicate front matter and content from the original page
      amp_page_data = page.data.dup
      amp_page_data['is_amp'] = true
      amp_page_data['permalink'] = page.url.sub(/\/$/, '') + '/amp/'

      # Process the HTML content from the original page
      html_content = page.output

      # Create a new AMP version file name (e.g., "post.md" becomes "post-amp.md")
      amp_file_name = page.basename + '-amp' + page.extname

      # Check if the page is in the root directory (no subfolder)
      if page.dir == '.'
        # If it's in the root, create the AMP file in the root directory
        amp_file_path = File.join(site.source, amp_file_name)
      else
        # If it's in a subfolder, keep the subfolder structure
        amp_file_path = File.join(site.source, page.dir, amp_file_name)
      end

      # Write the new AMP file with updated front matter and HTML content
      File.open(amp_file_path, 'w') do |file|
        file.puts front_matter(amp_page_data)
        file.puts html_content
      end
    end

    def front_matter(data)
      # Convert front matter data to YAML
      yaml_data = data.to_yaml
      # Ensure that the front matter is formatted properly
      "---\n" + yaml_data.gsub(/^---\n/, '').strip + "\n---"
    end
  end
end
