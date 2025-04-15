require 'jekyll'
require 'fileutils'

module Jekyll
  class AmpGenerator < Generator
    safe true
    priority :normal

    def generate(site)
      # Generate AMP pages for posts, pages, and archives
      generate_amp_pages_for_posts(site)
      generate_amp_pages_for_pages(site)
      generate_amp_pages_for_archives(site)
    end

    def generate_amp_pages_for_posts(site)
      site.posts.docs.each do |post|
        generate_amp_page(site, post)
      end
    end

    def generate_amp_pages_for_pages(site)
      site.pages.each do |page|
        # Create AMP version for normal pages (not in posts)
        generate_amp_page(site, page) unless page.url.include?("amp")
      end
    end

    def generate_amp_pages_for_archives(site)
      # Handle archive pages (tag, category, year, month)
      site.pages.each do |page|
        # Skip non-archive pages
        next unless page.data["layout"] == "archive"
        
        # Create AMP version for archive pages
        generate_amp_page(site, page)
      end
    end

    def generate_amp_page(site, item)
      # Create a new AMP page by duplicating the original
      amp_page = Jekyll::Page.new(site, site.source, "_pages", "#{item.url}amp/")

      # Copy original front matter and add 'is_amp' flag
      amp_page.data = item.data.clone
      amp_page.data["is_amp"] = true
      amp_page.data["layout"] = item.data["layout"]  # Use original layout
      
      # Set AMP permalink
      amp_page.data["permalink"] = "#{item.url}amp/"

      # Render the content (HTML output)
      rendered_content = site.layouts[item.data["layout"]].render(item.site_payload.merge("content" => item.content))

      # Copy the rendered HTML content
      amp_page.content = rendered_content

      # Write the AMP page
      site.pages << amp_page
    end
  end
end
