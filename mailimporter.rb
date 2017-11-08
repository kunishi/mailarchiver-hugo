#!/usr/bin/ruby

require 'rubygems'
require 'yaml'
require 'mail'
require 'kconv'
require 'fileutils'
require 'mime/types'

config_yml = File.expand_path(File.dirname(__FILE__)) + '/_config.yml'
yaml = YAML::load(File.open(config_yml))
blogs = yaml['blog']
blogs.each do |blog|
  blog['basedir'] ||= '../../dbjapan-hugo/'
  blog['assets_dir'] ||= blog['basedir'] + 'static/assets/ml_archives'
  #blog['posts_dir'] ||= '_posts'
  blog['posts_dir'] ||= blog['basedir'] + 'content/ml_archives'

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
  subject = Kconv.toutf8(mail.subject.gsub(/"/, '\"')) if mail.subject

  if mail.multipart?
    if mail.text_part
      body = Kconv.toutf8(mail.text_part.decoded)
    elsif mail.html_part
      body = Kconv.toutf8(mail.html_part.decoded)
    end
  else
    body = Kconv.toutf8(mail.body.decoded)
  end

  attachments = {}
  mail.attachments.each do |attach|
    dir = blog['assets_dir'] + '/' + post_id
    basename = Digest::MD5.hexdigest(attach.to_s)
    type = MIME::Types[attach.mime_type].first
    if type
      print attach.filename, "\n"
      if type == 'application/octet-stream' && File.extname(attach.filename).downcase == '.pdf'
        ext = 'pdf'
      else
        ext = type.preferred_extension
      end
      absolute_path = dir + '/' + basename + '.' + ext

      FileUtils.mkdir_p dir
      File.open(absolute_path, "w") do |file|
        file << attach.decoded
      end
      attachments[attach.filename] = basename + '.' + ext
      print absolute_path, "\n"
    end
  end

  FileUtils.mkdir_p blog['posts_dir']
  open(post_filename, "w") do |file|
    file << "---\n"
    file << "title: \"#{subject}\"\n"
    file << "date: #{date.to_s}\n"
    file << "type: ml_archive\n"
    file << "from: '#{mail.from.first}'\n"
    file << "message_id: '#{mail.message_id}'\n"
    file << "post_id: #{post_id}\n"
    file << "attachments:\n" if !attachments.empty?
    attachments.each do |name, filename|
      file << "  - name: '#{name}'\n"
      file << "    filename: '#{filename}'\n"
    end
    file << "---\n"
    file << "<pre>\n"
    file << body
    file << "</pre>\n"
  end
end
