require 'middleman-blog/uri_templates'
require 'middleman-search'

###
# Compass
###

# Change Compass configuration
# compass_config do |config|
#   config.output_style = :compact
# end

###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
# page "/path/to/file.html", :layout => false
#
# With alternative layout
# page "/path/to/file.html", :layout => :otherlayout
#
# A path which all have the same layout
# with_layout :admin do
#   page "/admin/*"
# end

# Proxy pages (https://middlemanapp.com/advanced/dynamic_pages/)
# proxy "/this-page-has-no-template.html", "/template-file.html", :locals => {
#  :which_fake_page => "Rendering a fake page with a local variable" }

###
# Helpers
###

# Automatic image dimensions on image_tag helper
# activate :automatic_image_sizes

# Reload the browser automatically whenever files change
# configure :development do
#   activate :livereload
# end

# Methods defined in the helpers block are available in templates
# helpers do
#   def some_helper
#     "Helping"
#   end
# end

require "lib/video_helpers"
require "lib/speaker_helpers"
require "lib/tag_helpers"
helpers VideoHelpers
helpers SpeakerHelpers
helpers TagHelpers
include VideoHelpers
include SpeakerHelpers
include TagHelpers

config[:github_repo_url] = 'https://github.com/chriseidhof/pomotv'

# Used in atom feeds that need a full URL, avoid using otherwise 
config[:site_url] = 'http://www.pomo.tv/'
config[:site_name] = 'www.pomo.tv'



config[:css_dir] = 'stylesheets'

config[:js_dir] = 'javascripts'

config[:images_dir] = 'images'

data.editions.each do |metadata|
  name = "#{metadata[:event]} #{metadata[:edition]}"
  event = data.events[metadata[:event]]
  safe_edition = safe_parameterize metadata[:edition]
  slug = "#{event[:slug]}/#{safe_edition}"
  metadata[:slug] = slug
  base_url = edition_url(metadata)
  html = "#{base_url}/index.html"
  feed = "#{base_url}/feed.xml"

  proxy html, "edition.html", :locals => { :name => name, :metadata => metadata, :videos => data.videos[name], :atom_feed => feed}, :ignore => true, :search_title => "Event: #{name}"
  proxy feed, "feed.xml", :locals => { :name => name, :videos => data.videos[name], :html_page => base_url}, :ignore => true
end

data.speakers.each do |name, metadata|
  base_url = speaker_page(name)
  html = "#{base_url}/index.html"
  feed = "#{base_url}/feed.xml"

  videos = data.videos.map { |k,v| [k,v.select { |video| video.speakers.include? name }] }.select { |k, v| v.count > 0 }

  proxy html, "speaker.html", :locals => { :name => name, :speaker => metadata , :videos => videos, :atom_feed => feed}, :ignore => true, :search_title => "Speaker: #{name}"
  proxy feed, "feed.xml", :locals => { :name => name, :videos => videos.map { |c| c[1] }.flatten, :html_page => base_url}, :ignore => true
end

all_tags.each do |tag|
  base_url = "/tags/#{slug_for_tag(tag)}"
  html = "#{base_url}/index.html"
  feed = "#{base_url}/feed.xml"

  videos = videos_for_tag(tag)

  proxy html, "tag.html", :locals => { :tag => tag, :videos => videos, :atom_feed => feed}, :ignore => true, :search_title => "Tag: #{tag}"
  proxy feed, "feed.xml", :locals => { :name => tag, :videos => videos.map { |c| c[1] }.flatten, :html_page => base_url}, :ignore => true
end

data.videos.map do |edition,videos|
  videos.map do |video|
    video["edition"] = edition
    page_url = "/events/#{video_id(video)}.html"
    proxy page_url, "video.html", :locals => { :video => video }, :ignore => true, :search_title => "Video: #{video.title}"
  end
end

activate :search do |search|
  search.resources = ['events/', 'tags/', 'speakers/']
  search.index_path = "search/index.json"
  search.fields = {
      search_title: {boost: 100, store: true, required: true},
      content: {boost: 50},
      url: {index: false, store: true}
  }
  # cache the index during development
  search.cache = true
end

# Build-specific configuration
configure :build do
  # For example, change the Compass output style for deployment
  # activate :minify_css

  # Minify Javascript on build
  # activate :minify_javascript

  # Enable cache buster
  # activate :asset_hash

  # Use relative URLs
  # activate :relative_assets

  # Or use a different image path
  # set :http_prefix, "/Content/images/"
end
