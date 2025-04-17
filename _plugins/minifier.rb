Jekyll::Hooks.register [:pages, :documents], :post_render do |item|
    if item.output_ext == '.html' && item.output
      item.output = minify_html(item.output)
    end
  end
  
  def minify_html(html)
    html.gsub(/>\s+</, '><')                     # remove whitespace between tags
        .gsub(/\n+/, '')                         # remove newlines
        .gsub(/\s{2,}/, ' ')                     # reduce multiple spaces
        .gsub(/<!--.*?-->/m, '')                 # remove HTML comments
        .gsub(/;}/, '}')                         # clean CSS blocks
        .gsub(/\/\*.*?\*\//m, '')                # remove CSS/JS comments
        .gsub(/(\[\w+\])\s*=\s*"/, '\1="')       # preserve AMP bindings
        .strip
  end