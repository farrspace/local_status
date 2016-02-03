require "sinatra"
require "sinatra/reloader"
require "tilt/haml"
require "tilt/sass"

helpers do
  def font_awesome(icon_name, extra_classes="")
    icon_name ||= ""
    icon_name.gsub!(' ', '-')
    icon_name.gsub!(/[^\w-]/, '')
    "<i class=\"fa fa-fw #{extra_classes} fa-#{icon_name}\"></i>"
  end
  alias_method :fa, :font_awesome

  def changed_files
    gs = `cd ~/projects/local_status; git status -s`

    files = {}

    gs.to_s.lines do |line|
      file = line[2..-1].strip

      staging_status, dest = case line[0..1]
      when " M"
        [:unstaged, :modified]
      when "M "
        [:staged, :modified]
      when "??"
        [:untracked, :untracked]
      when "A "
        [:staged, :added]
      when " D"
        [:unstaged, :deleted]
      when "D "
        [:staged, :deleted]
      when "AA", "DD"
        [:conflicted, :conflict]
      when "MM"
        [:staged_unstaged, :modified]
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

  def format_staging_status(status)
    case status.to_s
    when "staged"
      font_awesome("cloud upload")
    when "unstaged"
      font_awesome "folder open"
    when "untracked"
      font_awesome("cubes")
    when "staged_unstaged"
      font_awesome("cloud upload") + " / " + font_awesome("folder open")
    when "conflicted"
      font_awesome("bomb")
    else
      status
    end
  end

  def format_file(path)
    folders, file = understand_path(path)

    result = []

    result << '<span class="path">'

    if file
      icon = if !file["."]
        "gear"
      elsif file.end_with?(".json")
        "indent"
      elsif file.end_with?(".yml")
        "tree"
      elsif file.end_with?("_spec.rb")
        "flask"
      elsif file.end_with?(".rb")
        "diamond"
      elsif file.end_with?(".html.erb", ".html.haml", ".html")
        "file-code-o"
      elsif file.end_with?(".js.erb", ".js", ".js.map")
        "meh o"
      elsif file.end_with?(".css", ".scss", ".less")
        "paint-brush"
      else
        "cube"
      end
      result << font_awesome(icon)
    else
      result << font_awesome("folder o")
    end

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
