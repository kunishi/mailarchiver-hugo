#!/usr/bin/ruby

require 'rubygems'
require 'yaml'
require 'mail'
require 'kconv'

config_yml = File.expand_path(File.dirname(__FILE__)) + '/_config.yml'
yaml = YAML::load(File.open(config_yml))
blogs = yaml['blog']
blogs.each do |blog|
  blog['assets_dir'] ||= 'assets/dbjapan'
  #blog['posts_dir'] ||= '_posts'
  blog['posts_dir'] ||= '../../dbjapan-hugo/content/ml_archives'

  if ARGV[0]
    filename = ARGV[0]
    handle = File.open filename
  else
    handle = STDIN
  end

  mail = Mail.read handle
  handle.close

  message_id = mail.message_id
  date = mail.date
  post_id = nil
  if message_id
    post_id = "#{Digest::MD5.hexdigest(message_id)}"
  else
    post_id = "#{Digest::MD5.hexdigest(mail.body.to_s)}"
  end
  post_ext = ".md"
  post_filename = blog['posts_dir'] + "/" + post_id + post_ext
  body = nil
  subject = Kconv.toutf8(mail.subject.gsub(/"/, '\"'))

  if mail.multipart?
    if mail.text_part
      body = Kconv.toutf8(mail.text_part.decoded)
    elsif mail.html_part
      body = Kconv.toutf8(mail.html_part.decoded)
    end
  else
    body = Kconv.toutf8(mail.body.decoded)
  end

  open(post_filename, "w") do |file|
    file << "---\n"
    file << "title: \"#{subject}\"\n"
    file << "date: #{date.to_s}\n"
    file << "type: ml_archive\n"
    file << "---\n"
    file << "<pre>\n"
    file << body
    file << "</pre>\n"
  end
end
