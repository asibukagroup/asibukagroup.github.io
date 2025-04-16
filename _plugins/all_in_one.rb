module Jekyll
  class AmpGenerator < Generator
    safe true

    def generate(site)
      # Fetch collections from the site's configuration file
      collections = site.config['collections'].keys

      # Loop through all pages, posts, and collections to find .md files
      site.pages.each do |page|
        process_page(page, site, collections) if valid_md_page?(page, site, collections)
      end

      site.posts.docs.each do |post|
        process_page(post, site, collections) if valid_md_page?(post, site, collections)
      end

      site.collections.each do |name, collection|
        collection.docs.each do |doc|
          process_page(doc, site, collections) if valid_md_page?(doc, site, collections)
        end
      end
    end

    private

    # Check if the page is a valid .md file in the root directory or a valid collection
    def valid_md_page?(page, site, collections)
      # The file must be a markdown file and either be in the root or a valid collection folder
      page.extname == ".md" && (root_directory?(page, site) || valid_collection?(page, collections, site))
    end

    # Check if the page is in the root directory
    def root_directory?(page, site)
      File.dirname(page.path) == site.source
    end

    # Check if the page is in one of the valid collections
    def valid_collection?(page, collections, site)
      collections.any? { |collection| File.dirname(page.path).include?(collection) }
    end

    def process_page(page, site, collections)
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

      # Get the directory of the page (for posts and documents, use the `path` method)
      page_dir = page.is_a?(Jekyll::Document) ? File.dirname(page.path) : page.dir

      # Determine AMP file path
      amp_file_path = determine_amp_file_path(page, page_dir, site, amp_file_name)

      # Skip file creation if the AMP version already exists
      return if File.exist?(amp_file_path)

      # Ensure the directory exists
      FileUtils.mkdir_p(File.dirname(amp_file_path)) unless File.directory?(File.dirname(amp_file_path))

      # Write the new AMP file with updated front matter and HTML content
      File.open(amp_file_path, 'w') do |file|
        file.puts front_matter(amp_page_data)
        file.puts html_content
      end
    end

    # Determine where the AMP file should be saved (root or subfolder)
    def determine_amp_file_path(page, page_dir, site, amp_file_name)
      if page_dir == '.'
        # If it's in the root, create the AMP file in the root directory
        File.join(site.source, amp_file_name)
      else
        # If it's in a subfolder, keep the subfolder structure
        File.join(site.source, page_dir, amp_file_name)
      end
    end

    # Convert front matter data to YAML
    def front_matter(data)
      yaml_data = data.to_yaml
      "---\n" + yaml_data.gsub(/^---\n/, '').strip + "\n---"
    end
  end
end
