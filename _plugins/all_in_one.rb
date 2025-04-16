module Jekyll
  class AmpGenerator < Generator
    safe true

    def generate(site)
      # Fetch collections from the site's configuration file
      collections = site.config['collections'].keys

      # Loop through all pages, posts, and collections to find .md files
      site.pages.each do |page|
        process_page(page, site, collections) if page_is_markdown?(page) && in_valid_collection?(page, collections)
      end

      site.posts.docs.each do |post|
        process_page(post, site, collections) if page_is_markdown?(post) && in_valid_collection?(post, collections)
      end

      site.collections.each do |name, collection|
        collection.docs.each do |doc|
          process_page(doc, site, collections) if page_is_markdown?(doc) && in_valid_collection?(doc, collections)
        end
      end
    end

    private

    def page_is_markdown?(page)
      # Only process .md files
      page.extname == ".md"
    end

    def in_valid_collection?(page, collections)
      # Check if the page is in the root directory or in one of the specified collections
      root_directory?(page) || valid_collection?(page, collections)
    end

    def root_directory?(page)
      # Check if the page is in the root directory
      File.dirname(page.path) == site.source
    end

    def valid_collection?(page, collections)
      # Check if the page is in one of the valid collections based on the config
      collections.any? { |collection| File.dirname(page.path).include?(collection) }
    end

    def process_page(page, site, collections)
      # Skip if the page is already an AMP version or not a markdown file
      return if page.data['is_amp'] || !page_is_markdown?(page)

      # Duplicate front matter and content from the original page
      amp_page_data = page.data.dup
      amp_page_data['is_amp'] = true
      amp_page_data['permalink'] = page.url.sub(/\/$/, '') + '/amp/'

      # Process the HTML content from the original page
      html_content = page.output

      # Create a new AMP version file name (e.g., "post.md" becomes "post-amp.md")
      amp_file_name = page.basename + '-amp' + page.extname

      # Get the directory of the page (for posts and documents, use the `path` method)
      page_dir = page.is_a?(Jekyll::Document) ? File.dirname(page.path) : page.dir

      # Check if the page is in the root directory (no subfolder)
      if page_dir == '.'
        # If it's in the root, create the AMP file in the root directory
        amp_file_path = File.join(site.source, amp_file_name)
      else
        # If it's in a subfolder, keep the subfolder structure
        amp_file_path = File.join(site.source, page_dir, amp_file_name)

        # Ensure the directory exists
        FileUtils.mkdir_p(File.dirname(amp_file_path)) unless File.directory?(File.dirname(amp_file_path))
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