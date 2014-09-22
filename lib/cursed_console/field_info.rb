module CursedConsole

  class FieldInfo

    attr_accessor :name, :type, :line, :start_col, :end_col, :cursor_col, :value, :display_name

    def initialize(name, type, line=0, start_col=0, end_col=0, default_value="")
      @name = name
      @type = type
      @line = line
      @start_col = start_col
      @end_col = end_col
      @cursor_col = start_col
      @value = default_value
    end

    def is_button?
      type == :button
    end

    def move_cursor_right
      text_end_col = start_col + value.length
      self.cursor_col += 1 if cursor_col < text_end_col
    end

    def move_cursor_left
      self.cursor_col -= 1 if cursor_col > start_col
    end

    def move_cursor_to_end
      self.cursor_col = start_col + value.length
    end

    def move_cursor_to_start
      self.cursor_col = start_col
    end

    def move_cursor_to(col)
      move_cursor_left if col >= value.length
    end

    def update_value(ch)
      return if value.length >= (end_col - start_col)
      index = cursor_col - start_col
      self.value.insert(index, ch.to_s)
      move_cursor_right
    end

    def remove_char(backspace=false)
      index = (cursor_col - start_col) 
      index -= 1 if backspace
      return if index < 0
      head = value.slice(0...index)
      tail = value.slice(index + 1..-1)
      self.value = head
      self.value += tail unless tail.nil?
      move_cursor_left if backspace
      move_cursor_to(index) unless backspace
    end

    def padded_value
      Logger.debug("Value to be rendered: #{value.inspect}")
      width = end_col - start_col
      v_to_display = (value.nil? || (value.is_a?(String) && value.length == 0))  ? "" : display_name ? display_name.call(value) : value
      pad_count = width - v_to_display.length
      "#{v_to_display}#{' ' * pad_count}"
      # "#{value}#{' ' * pad_count}"
    end
  end

end
