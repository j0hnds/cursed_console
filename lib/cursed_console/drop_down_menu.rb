module CursedConsole

  #
  # This class assumes that it is passed a list of hashes. No
  # exceptions. The hash will be composed of:
  #
  # { 'id' => key_selector, 'display' => display_value }
  #
  # Any other keys are fine; they will just be ignored.
  #
  class DropDownMenu < Curses::Window

    MAX_WINDOW_HEIGHT = 20
    HIGHLIGHT = Curses::A_STANDOUT | Curses::color_pair(1)
    NORMAL = Curses::A_NORMAL | Curses::color_pair(1)

    attr_reader :item_list, :next_level, :plugin_manager
    attr_reader :max_window_height

    def initialize(item_list, 
                   next_level, 
                   plugin_manager, 
                   top, 
                   left, 
                   max_window_height=MAX_WINDOW_HEIGHT)
      super *calculate_size_position(item_list, max_window_height, top, left)

      @item_list = item_list
      @next_level = next_level
      @plugin_manager = plugin_manager
      @max_window_height = max_window_height

      color_set(1)
      box('|', '-')
      Curses::curs_set(0)
      keypad(true)

      draw_menu(0)
    end

    def draw_menu(active_index=nil, top_line=0)
      item_list[top_line..-1].each_with_index do | item, index |
        menu_item = item['display']

        break if index >= displayable_lines

        setpos(index + 1, 1)
        attrset((index + top_line) == active_index ? HIGHLIGHT : NORMAL)
        spaces = " " * ((maxx - 2) - menu_item.length)
        addstr(menu_item.to_s + spaces)
      end
    end

    def displayable_lines
      maxy - 2 
    end

    def has_sub_items?
      next_level.present?
    end

    def select_menu_item
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
          if ! has_sub_items?
            return item_list[position]['id']
          else
            submenu_select = render_sub_menu(position)
            if submenu_select.present?
              return [ item_list[position]['id'], submenu_select ]
            end
          end
        when 27, Curses::Key::CANCEL
          return [  ]
        else
          next if ch.is_a?(Fixnum)
          selected_item = item_list.detect do |item| 
            item['display'].downcase.start_with?(ch.downcase) 
          end
          position = item_list.index(selected_item) unless selected_item.nil?
        end

        # Make sure the position stays in range
        position = 0 if position < 0
        position = item_list.size - 1 if position >= item_list.size

        # Now, to adjust the scrolling position (if necessary)
        top_line = 0 if (position + 1) < displayable_lines
        top_line = (position + 1) - displayable_lines if (position + 1) >= displayable_lines
        draw_menu(position, top_line)
      end
    end

    private

    def render_sub_menu(position)
      plugin_name = item_list[position]['id']
      action_menu = plugin_manager.actions_for(next_level, plugin_name).map do |action|
        { 'id' => action, 'display' => action.capitalize }
      end
      submenu = DropDownMenu.new(action_menu,
                                 nil, # No subpath
                                 plugin_manager,
                                 begy + position, 
                                 begx + maxx)
      submenu.select_menu_item.tap do | selection |
        submenu.clear
        submenu.refresh
        submenu.close
      end
    end

    def calculate_size_position(item_list, max_window_height, top, left)
      height = item_list.size + 2 > max_window_height ? max_window_height : item_list.size + 2

      width = item_list.inject(0) do |acc, item|
        acc = item['display'].size if item['display'].size > acc
        acc
      end + 2

      [ height, width, top, left ]
    end

  end

end
