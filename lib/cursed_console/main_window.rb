module CursedConsole

  class MainWindow < Curses::Window

    QUIT_MENU_ITEM = 'Quit'

    attr_reader :menu_list, :plugin_manager, :web_service_client
    attr_accessor :current_position

    def initialize(plugin_manager, web_service_client)
      super(0, 0, 0, 0)
      @current_position = -1
      @plugin_manager = plugin_manager
      @web_service_client = web_service_client
      @menu_list = @plugin_manager.sub_paths
      Curses::curs_set(0)
      color_set(1)
      keypad(true)
      render_menu
      write_status_message 
    end

    def main_loop
      while ch = getch
        case ch
        when Curses::Key::RIGHT
          self.current_position += 1
        when Curses::Key::LEFT
          self.current_position -= 1
        when 13, Curses::Key::ENTER
          return current_position if current_position == menu_list.size
          submenu_select = render_sub_menu(current_position)
          if submenu_select.present?
            # This is where we should invoke the form
            invoke_action(plugin_manager.sub_paths[current_position], 
                          submenu_select.first, 
                          submenu_select.last)
            # return [ current_position ] + submenu_select
          end
        else
          next if ch.is_a?(Fixnum)
          mlist = menu_list + [ QUIT_MENU_ITEM ]
          selected_item = mlist.detect { |item| item.downcase.start_with?(ch.downcase) }
          self.current_position = mlist.index(selected_item) unless selected_item.nil?
        end
        self.current_position = 0 if current_position < 0
        self.current_position = menu_list.size if current_position > menu_list.size
        render_menu(self.current_position)
        update_status_bar
      end
    end

    def render_menu(item_selected=-1)
      setpos(0, 1)

      (menu_list + [ QUIT_MENU_ITEM ]).map { | i | i.capitalize }.each_with_index do | item, index |
        addstr(" ") if index > 0
        first_char = item.slice(0, 1)
        remainder = item.slice(1..-1)
        attron(Curses::A_STANDOUT) if index == item_selected
        attron(Curses::A_UNDERLINE)
        addstr(first_char)
        attroff(Curses::A_UNDERLINE)
        addstr(remainder)
        attroff(Curses::A_STANDOUT) if index == item_selected
      end
    end
    
    def update_status_bar
      # write_status_message(menu_list[menu_list[current_position]]) unless current_position < 0
    end

    def write_status_message(message=nil, offset=0)
      # %x{ echo "Line: #{lines - 1}, Message: #{message}" >> log.txt}
      # Clear the status line
      setpos(maxy - 1, 0)
      attron(Curses::A_STANDOUT)
      addstr(" " * maxx)
      attroff(Curses::A_STANDOUT)

      if ! message.nil?
        setpos(maxy - 1, 1)
        attron(Curses::A_STANDOUT)
        addstr(message)
        attroff(Curses::A_STANDOUT)
      end
    end

    def position_for_submenu(selected_menu_item)
      pos = 2
      plugin_manager.sub_paths.each_with_index do | item, index |
        break if selected_menu_item >= index
        pos += (item.length + 1)
      end
      pos
    end

    def render_sub_menu(position)
      sub_path = plugin_manager.sub_paths[position]
      plugins = plugin_manager.plugins_for(sub_path)
      submenu = DropDownMenu.new(CursedConsole::List.new(plugins),
                                 sub_path,
                                 plugin_manager,
                                 1, 
                                 position_for_submenu(position), 
                                 self)
      submenu.select_menu_item.tap do | selection |
        submenu.clear
        submenu.refresh
        submenu.close
      end
    end

    def invoke_action(sub_path, plugin, action)
      # Instantiate the plugin...
      plugin = plugin_manager.instantiate_plugin(sub_path, plugin)
      if plugin.requires_input_for?(action.to_sym)
        form = PluginForm.new(plugin, action.to_sym, self, 20, 80, 2, 2)
        form.handle_form(web_service_client)
        form.clear
        form.refresh
        form.close
      else
        # No input required. Don't need no stinkin' form
        the_form = plugin.send(action.to_sym)
        uri = the_form[:result]
        list = plugin.send(the_form[:result_formatter], web_service_client, uri, {})
        data_list = DataList.new(list)
        #submenu = DropDownMenu.new(list, 
                                  #nil, # sub_path
                                  #nil, # plugin_manager
                                  #1,
                                  #1,
                                  #self)  # status_bar
        selected = data_list.handle_list.tap do | selection |
          data_list.clear
          data_list.refresh
          data_list.close
          Curses::curs_set(1)
        end
        #selected = submenu.select_menu_item.tap do | selection |
          #submenu.clear
          #submenu.refresh
          #submenu.close
          #Curses::curs_set(1)
          ## render_fields
        #end
        refresh
      end
    end

  end

end
