module CursedConsole

  #
  # This class is just for displaying lists of data. It requires
  # no other control other than possible scrolling of the data.
  #
  class DataList < Curses::Window

    PAD_HEIGHT = 3

    attr_reader :item_list

    #
    # The expectation is that the item_list simply contains a list of strings.
    # The window will auto-position itself based on the width of the data.
    #
    def initialize(item_list, max_window_height=Curses::lines - 3 * PAD_HEIGHT)
      super *calculate_size_position(item_list, max_window_height)
      @item_list = item_list

      color_set(1)
      box('|', '-')
      Curses::curs_set(0)
      keypad(true)

      draw_list
    end

    def handle_list
      # The stuff for scrolling
      top_line = 0

      # The stuff for selection
      position = 0
      while ch = getch
        case ch
        when Curses::Key::UP
          position -= 1
        when Curses::Key::DOWN
          position += 1
        when 13, Curses::Key::ENTER
          # Just exit the list returning the current position of the cursor
          return position
        when 27, Curses::Key::CANCEL
          # Just exit the list returning the current position of the cursor
          return position
        else
          next if ch.is_a?(Fixnum)
          #
          # Using a key to select a row
          selected_item = item_list.detect { |item| item.downcase.start_with?(ch.downcase) }
          position = item_list.index(selected_item) unless selected_item.nil?
        end

        # Make sure the position stays in range
        position = 0 if position < 0
        position = item_list.size - 1 if position >= item_list.size

        # Now, to adjust the scrolling position (if necessary)
        top_line = 0 if (position + 1) < displayable_lines
        top_line = (position + 1) - displayable_lines if (position + 1) >= displayable_lines
        draw_list(position, top_line)
      end
    end

    private

    def displayable_lines; maxy - 2 end

    def draw_list(active_index=0, top_line=0)
      item_list.slice(top_line..-1).each_with_index do | item, index |
        break if index >= displayable_lines
        item_length = item.length > (maxx - 4) ? maxx - 4 : item.length
        setpos(index + 1, 1)
        attrset(((index + top_line) == active_index ? Curses::A_STANDOUT : Curses::A_NORMAL) | Curses::color_pair(1))
        spaces = " " * ((maxx - 4) - item_length)
        clipped_item = item.to_s.slice(0, item_length)
        addstr(clipped_item + spaces)
      end
    end

    def calculate_size_position(item_list, max_window_height)
      max_width = item_list.inject(0) { | acc, item | acc = item.length if item.length > acc; acc }
      width = max_width > (Curses::cols - 2) ? Curses::cols - 2 : max_width
      height = (item_list.length + 2) > max_window_height ? max_window_height : item_list.length + 2
      top = (Curses::lines - height) / 2
      left = (Curses::cols - width) / 2
      [ height, width, top, left ]
    end

  end

end
