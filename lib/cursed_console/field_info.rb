module CursedConsole

  class FieldInfo

    attr_accessor :name, :type, :line, :start_col, :end_col, :cursor_col, :value

    def initialize(name, type, line=0, start_col=0, end_col=0)
      @name = name
      @type = type
      @line = line
      @start_col = start_col
      @end_col = end_col
      @cursor_col = start_col
      @value = ""
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

    def update_value(ch)
      return if value.length >= (end_col - start_col)
      index = cursor_col - start_col
      self.value.insert(index, ch)
      move_cursor_right
    end

    def remove_char(backspace=false)
      index = (cursor_col - start_col) 
      index -= 1 if backspace
      return if index < 0
      head = value.slice(0, index)
      tail = value.slice(index + 1)
      self.value = head
      self.value += tail unless tail.nil?
      move_cursor_left
    end

    def padded_value
      width = end_col - start_col
      pad_count = width - value.length
      "#{value}#{' ' * pad_count}"
    end
  end

end
