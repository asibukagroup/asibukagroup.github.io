module Jekyll
  class AmpGenerator < Generator
    safe true

    def generate(site)
      collections = site.config['collections'].keys

      site.pages.each do |page|
        process_md_file(page, site) if valid_md_page?(page, site, collections)
      end

      site.posts.docs.each do |post|
        process_md_file(post, site) if valid_md_page?(post, site, collections)
      end

      site.collections.each_value do |collection|
        collection.docs.each do |doc|
          process_md_file(doc, site) if valid_md_page?(doc, site, collections)
        end
      end
    end

    private

    def valid_md_page?(page, site, collections)
      page.extname == ".md" && (root_directory?(page, site) || valid_collection?(page, collections))
    end

    def root_directory?(page, site)
      File.dirname(page.path) == site.source
    end

    def valid_collection?(page, collections)
      collections.any? { |collection| page.path.include?("/#{collection}/") }
    end

    def process_md_file(page, site)
      return if page.data['is_amp']

      original_path = page.path
      dirname = File.dirname(original_path)
      basename = File.basename(original_path, '.md')
      amp_basename = "#{basename}-amp.md"
      amp_path = File.join(dirname, amp_basename)

      return if File.exist?(amp_path)

      # Read original Markdown content
      content = File.read(original_path)
      front_matter, body = split_front_matter(content)

      # Modify front matter
      front_matter["is_amp"] = true
      front_matter["permalink"] = (page.url.sub(/\/$/, '') + '/amp/')

      # Write AMP file
      File.open(amp_path, 'w') do |file|
        file.puts front_matter_to_yaml(front_matter)
        file.puts body
      end
    end

    def split_front_matter(content)
      parts = content.split(/^---\s*$\n?/).reject(&:empty?)
      front_matter = parts[0] ? SafeYAML.load(parts[0]) : {}
      body = parts[1..].join("---\n")
      [front_matter, body]
    end

    def front_matter_to_yaml(data)
      "---\n#{data.to_yaml.strip}\n---"
    end
  end
end
