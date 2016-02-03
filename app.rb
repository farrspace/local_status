require "sinatra"
require "sinatra/reloader"
require "tilt/haml"
require "tilt/sass"

helpers do
  def changed_files
    gs = `cd /Users/farr/dev/working; git status -s`

    files = {}

    gs.to_s.lines do |line|
      file = line[2..-1].strip

      staging_status, dest = case line[0..1]
      when " M"
        [:unstaged, :modified]
      when "M "
        [:staged, :modified]
      when "??"
        [:unstaged, :untracked]
      when "A "
        [:staged, :added]
      when " D"
        [:unstaged, :deleted]
      when "D "
        [:staged, :deleted]
      when "MM", "AA", "DD"
        [:staged, :conflict]
      end

      files[staging_status] ||= {}
      files[staging_status][dest] ||= []
      files[staging_status][dest] << file
    end
    files
  end

  def understand_path(path)
    parts = path.split("/", -1)
    file = parts.pop
    file = nil if file.empty?
    folders = parts
    [folders, file]
  end

  def format_file(path)
    folders, file = understand_path(path)

    result = []

    result << '<span class="path">'

    folders.each do |folder|
      result << '<span class="path-folder">' + folder + '</span><span class="path-slash">/</span>'
    end

    if file
      result << '<span class="path-file">' + file + '</span>'
    end

    result << '</span>'

    result.join
  end
end

get "/" do
  @changed_files = changed_files
  haml :index
end

get "/index.css" do
  scss :index
end
