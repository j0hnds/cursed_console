module CursedConsole

  class DropDownMenu < Curses::Window

    MAX_WINDOW_HEIGHT = 20

    attr_reader :item_list, :sub_path, :plugin_manager, :max_window_height, :status_bar

    def initialize(item_list, 
                   sub_path, 
                   plugin_manager, 
                   top, 
                   left, 
                   status_bar, 
                   max_window_height=MAX_WINDOW_HEIGHT)
      super(item_list.size + 2 > max_window_height ? max_window_height : item_list.size + 2, 
            (item_list.is_a?(Hash) ? item_list.keys : item_list).inject(0) { |acc, item| acc = item.length if item.length > acc; acc } + 2, 
            top, 
            left)
      @item_list = item_list
      @sub_path = sub_path
      @plugin_manager = plugin_manager
      @max_window_height = max_window_height
      @status_bar = status_bar

      color_set(1)
      box('|', '-')
      Curses::curs_set(0)
      keypad(true)
      draw_menu(0)
    end

    def draw_menu(active_index=nil, top_line=0)
      if item_list.is_a?(Hash)
        l = item_list.keys
      else
        l = item_list
      end
      l.slice(top_line..-1).each_with_index do | menu_item, index |
        break if index >= displayable_lines
        setpos(index + 1, 1)
        attrset(((index + top_line) == active_index ? Curses::A_STANDOUT : Curses::A_NORMAL) | Curses::color_pair(1))
        spaces = " " * ((maxx - 2) - menu_item.length)
        addstr(menu_item.to_s + spaces)
      end
    end

    def displayable_lines; maxy - 2 end

    def has_sub_items?
      sub_path.present?
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
            if item_list.is_a?(Hash)
              return [ item_list.keys[position] ]
            else
              return [ item_list[position] ]
            end
          else
            submenu_select = render_sub_menu(position)
            if submenu_select.present?
              if item_list.is_a?(Hash)
                return [ item_list.keys[position] ] + submenu_select
              else
                return [ item_list[position] ] + submenu_select
              end
            end
          end
        when 27, Curses::Key::CANCEL
          return [  ]
        else
          next if ch.is_a?(Fixnum)
          if item_list.is_a?(Hash)
            l = item_list.keys
          else
            l = item_list
          end
          selected_item = l.detect { |item| item.downcase.start_with?(ch.downcase) }
          position = l.index(selected_item) unless selected_item.nil?
        end

        # Make sure the position stays in range
        position = 0 if position < 0
        position = item_list.size - 1 if position >= item_list.size

        # Now, to adjust the scrolling position (if necessary)
        top_line = 0 if (position + 1) < displayable_lines
        top_line = (position + 1) - displayable_lines if (position + 1) >= displayable_lines
        draw_menu(position, top_line)
        update_status_bar(position)
      end
    end

    private

    def update_status_bar(current_position)
      #return if status_bar.nil?
      #status_bar.write_status_message(item_list[item_list.keys[current_position]]) 
      #status_bar.refresh
    end

    def render_sub_menu(position)
      plugin_name = item_list[position]
      submenu = DropDownMenu.new(plugin_manager.actions(sub_path, plugin_name),
                                 nil, # No subpath
                                 plugin_manager,
                                 begy + position, 
                                 begx + maxx, 
                                 status_bar)
      submenu.select_menu_item.tap do | selection |
        submenu.clear
        submenu.refresh
        submenu.close
      end
    end

  end

end
