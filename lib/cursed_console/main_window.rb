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
      @menu_list = @plugin_manager.plugins

      Curses::curs_set(0)
      color_set(1)
      keypad(true)

      render_menu
    end

    def main_loop
      while ch = getch
        case ch
        when Curses::Key::RIGHT
          self.current_position += 1
        when Curses::Key::LEFT
          self.current_position -= 1
        when 13, Curses::Key::ENTER
          next if current_position < 0 # Don't do anything if nothing selected
          return current_position if current_position == menu_list.size
          submenu_select = render_sub_menu(current_position)
          if submenu_select.present?
            # This is where we should invoke the form
            invoke_action(plugin_manager.plugins[current_position], 
                          submenu_select.first, 
                          submenu_select.last)
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
    
    def position_for_submenu(selected_menu_item)
      pos = 1
      menu_list.each_with_index do | item, index |
        break if selected_menu_item <= index
        pos += (item.length + 1)
      end
      pos
    end

    def render_sub_menu(position)
      plugin = menu_list[position]
      resources = plugin_manager.resources_for(plugin)
      resource_menu = resources.map do | resource |
        { id: resource, display: resource.capitalize }
      end
      submenu = DropDownMenu.new(resource_menu,
                                 plugin,
                                 plugin_manager,
                                 1, 
                                 position_for_submenu(position))
      submenu.select_menu_item.tap do | selection |
        submenu.clear
        submenu.refresh
        submenu.close
      end
    end

    def invoke_action(plugin, resource, action)
      # Instantiate the resource...
      rsrc = plugin_manager.instantiate_resource(plugin, resource)
      if rsrc.requires_input_for?(action.to_sym)
        handle_form(rsrc, action)
      else
        # No input required. Don't need no stinkin' form
        handle_results(rsrc, action)
      end
    end

    def handle_form(rsrc, action)
      form = PluginForm.new(rsrc, action.to_sym, self, 20, 80, 2, 2)
      form.handle_form(web_service_client)
      form.clear
      form.refresh
      form.close
    end

    def handle_results(rsrc, action)
      the_form = rsrc.send(action.to_sym)
      uri = the_form[:result]
      list = rsrc.send(the_form[:result_formatter], web_service_client, uri, {})
      data_list = DataList.new(list)
      selected = data_list.handle_list.tap do | selection |
        data_list.clear
        data_list.refresh
        data_list.close
        Curses::curs_set(1)
      end
      refresh
    end

  end

end
