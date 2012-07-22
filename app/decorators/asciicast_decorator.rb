require 'base64'

class AsciicastDecorator < ApplicationDecorator
  decorates :asciicast

  THUMBNAIL_WIDTH = 20
  THUMBNAIL_HEIGHT = 10
  MAX_DELAY = 5.0

  def as_json(*args)
    data = model.as_json(*args)
    data['escaped_stdout_data'] = escaped_stdout_data
    data['stdout_timing_data'], saved_time = stdout_timing_data
    data['duration'] = data['duration'] - saved_time

    data
  end

  def created_at
    h.distance_of_time_in_words_to_now(model.created_at).sub('about ', '')
  end

  def escaped_stdout_data
    if data = stdout.read
      Base64.strict_encode64(data)
    else
      nil
    end
  end

  def stdout_timing_data
    saved_time = 0

    if file = stdout_timing.file
      f = IO.popen "bzip2 -d", "r+"
      f.write file.read
      f.close_write
      lines = f.readlines
      f.close

      data = lines.map do |line|
        delay, n = line.split
        delay = delay.to_f

        if time_compression && delay > MAX_DELAY
          saved_time += (delay - MAX_DELAY)
          delay = MAX_DELAY
        end

        [delay, n.to_i]
      end
    else
      data = nil
    end

    [data, saved_time]
  end

  def os
    if uname =~ /Linux/
      'Linux'
    elsif uname =~ /Darwin/
      'OSX'
    else
      uname.split(' ', 2)[0]
    end
  end

  def shell_name
    File.basename(shell.to_s)
  end

  def smart_title
    if title.present?
      title
    elsif command.present?
      "$ #{command}"
    else
      "##{id}"
    end
  end

  def thumbnail(width = THUMBNAIL_WIDTH, height = THUMBNAIL_HEIGHT)
    if @thumbnail.nil?
      lines = model.snapshot.to_s.split("\n")

      top_lines = lines[0...height]
      top_text = prepare_lines(top_lines, width, height).join("\n")

      bottom_lines = lines.reverse[0...height].reverse
      bottom_text = prepare_lines(bottom_lines, width, height).join("\n")

      if top_text.gsub(/\s+/, '').size > bottom_text.gsub(/\s+/, '').size
        @thumbnail = top_text
      else
        @thumbnail = bottom_text
      end
    end

    @thumbnail
  end

  private

  def prepare_lines(lines, width, height)
    (height - lines.size).times { lines << '' }

    lines.map do |line|
      line = line[0...width]
      line << ' ' * (width - line.size)
      line
    end
  end
end
