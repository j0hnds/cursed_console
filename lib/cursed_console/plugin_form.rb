module CursedConsole

  class PluginForm < Curses::Window

    attr_accessor :resource, :action, :current_field, :the_form, :fields, :status_bar

    FIELD_START_Y = 3
    LABEL_START_COL = 2
    LABEL_FIELD_GAP = 1
    BUTTON_WIDTH = 10

    def initialize(resource, action, status_bar, height, width, top, left)
      super(height, width, top, left)
      @fields = []
      @current_field = 0
      @resource = resource
      @action = action
      @the_form = @resource.send(action)
      @status_bar = status_bar
      color_set(1)
      box('|', '-')
      keypad(true)
      render_form
      set_cursor_on_current_field
    end

    def render_form
      render_title
      render_fields
    end

    def set_cursor_on_current_field
      field_info = fields[current_field]
      if field_info.is_button?
        Curses::curs_set(0)
        render_button(field_info.name, true)
        render_button(field_info.name == :ok ? :cancel : :ok)
      else
        Curses::curs_set(1)
        render_button(:ok)
        render_button(:cancel)
        setpos(field_info.line, field_info.cursor_col)
      end
    end

    def render_title
      col = (maxx - the_form[:title].length) / 2
      setpos(1, col)
      attron(Curses::A_STANDOUT)
      addstr(the_form[:title])
      attroff(Curses::A_STANDOUT)
    end

    def render_fields
      fields_already_populated = fields.size > 0
      field_y = FIELD_START_Y # We leave a line below the title of the form
      the_form[:fields].each_pair do | field_name, field_config |
        setpos(field_y, LABEL_START_COL)
        addstr(field_config[:label])
        field_start_col = LABEL_START_COL + field_config[:label].length + LABEL_FIELD_GAP
        self.fields << FieldInfo.new(field_name, field_config[:type], field_y, field_start_col, field_start_col + field_config[:width], field_config[:default].present? ? field_config[:default] : "") unless fields_already_populated
        setpos(field_y, field_start_col)
        attron(Curses::A_STANDOUT)
        field = fields.detect { | field | field.name == field_name }
        addstr(field.padded_value)
        attroff(Curses::A_STANDOUT)
        field_y += 2
      end
      render_button(:ok)
      self.fields << FieldInfo.new(:ok, :button) unless fields_already_populated
      render_button(:cancel)
      self.fields << FieldInfo.new(:cancel, :button) unless fields_already_populated
    end

    def render_button(which, focus=false)
      line = maxy - 2 
      col = which == :ok ? (maxx / 3) - (BUTTON_WIDTH / 2) : maxx - (maxx / 3) - (BUTTON_WIDTH / 2)
      setpos(line, col)
      attron(Curses::A_STANDOUT)
      attron(Curses::A_UNDERLINE) if focus
      label = which == :ok ? padded_label(BUTTON_WIDTH, "OK") : padded_label(BUTTON_WIDTH, "Cancel") 
      addstr(label)
      attroff(Curses::A_STANDOUT)
      attroff(Curses::A_UNDERLINE) if focus
    end

    def padded_label(overall_width, label)
      left_pad = (overall_width - label.length) / 2
      right_pad = overall_width - (label.length + left_pad)
      "#{' ' * left_pad}#{label}#{' ' * right_pad}"
    end

    def field_values
      fields.inject({}) do | acc, field |
        if the_form[:fields].has_key?(field.name)
          acc[field.name] = field.value
        end
        acc
      end
    end

    def handle_form(web_service_client)
      field = fields[current_field]
      while ch = getch
        case ch
        when Curses::Key::LEFT
          if field.type == :text
            field.move_cursor_left
            set_cursor_on_current_field
          end
        when Curses::Key::RIGHT
          if field.type == :text
            field.move_cursor_right
            set_cursor_on_current_field
          end
        when 1 # ^A to end
          if field.type == :text
            field.move_cursor_to_start
            render_field_value(field)
          end
        when 5 # ^E to end
          if field.type == :text
            field.move_cursor_to_end
            render_field_value(field)
          end
        when 13, Curses::Key::ENTER
          case field.type
            when :button
              return if field.name == :cancel
              begin
                process_form_result(web_service_client)
                return
              rescue StandardError => ex
                write_status_message(ex.message)
              end
            when :picker
              render_sub_menu(field, web_service_client)
              self.current_field += 1
              set_cursor_on_current_field
          end
        when 9 #Curses::Key::TAB
          self.current_field += 1
          self.current_field = 0 if current_field >= fields.size
          set_cursor_on_current_field
        when 353 # Reverse tab
          self.current_field -= 1
          self.current_field = fields.size - 1 if current_field < 0
          set_cursor_on_current_field
        when 27, Curses::Key::CANCEL
          return :cancelled
        when 127 # backspace
          if field.type == :text
            field.remove_char(true)
            render_field_value(field)
          end
        else
          %x{ echo "Character: #{ch}" >> log.txt }
          # All other characters
          if field.type == :text
            field.update_value(ch)
            render_field_value(field)
          else
            setpos(10, 10)
            addstr("Key pressed: #{ch}")
          end
        end
        field = fields[current_field]
      end
    end

    def render_field_value(field)
      setpos(field.line, field.start_col)
      attron(Curses::A_STANDOUT)
      addstr(field.padded_value)
      attroff(Curses::A_STANDOUT)
      setpos(field.line, field.cursor_col)
    end

    def format_uri(select_list)
      replaceables = select_list.scan(/\:\w+/)
      return select_list if replaceables.empty?
      uri = select_list
      replaceables.each do | replaceable |
        %x{ echo "Replaceable: #{replaceable.slice(1..-1).to_sym.inspect}" >> log.txt }
        field = fields.detect { | field | field.name == replaceable.slice(1..-1).to_sym }
        if the_form[:fields][field.name][:validate].present?
          regex = the_form[:fields][field.name][:validate]
          raise "Invalid value for #{field.name}" unless field.value =~ regex
        end
        value = the_form[:fields][field.name][:base64_encoded] ? Base64.urlsafe_encode64(field.value) : field.value
        raise "Must specify value for #{replaceable}" if value.nil? || value.length == 0
        uri = uri.gsub(replaceable, value)
      end
      uri
    end

    def process_form_result(web_service_client)
      return if the_form[:result].nil?
      uri = format_uri(the_form[:result])
      list = resource.send(the_form[:result_formatter], web_service_client, uri, fields.inject({}) {|acc,fld| acc[fld.name] = fld.value; acc })
      submenu = DropDownMenu.new(list, 
                                nil, # sub_path
                                nil, # plugin_manager
                                1,
                                1,
                                nil)
      selected = submenu.select_menu_item.tap do | selection |
        submenu.clear
        submenu.refresh
        submenu.close
        Curses::curs_set(1)
        render_fields
      end
      refresh
    end

    def render_sub_menu(field, web_service_client)
      field_config = the_form[:fields][field.name]
      if field_config[:select_list].is_a?(Array)
        # This is a hard-coded list of selections in the resource
        list = field_config[:select_list].inject({}) do | acc, tuple |
          acc[tuple.first] = tuple.last
          acc
        end
      elsif field_config[:select_list].is_a?(String)
        # This is supposed to be a call to a web service
        begin
          uri = format_uri(field_config[:select_list])
        rescue StandardError => ex
          write_status_message(ex.message)
          return []
        end
        begin
          list = web_service_client.get(uri)
        rescue Exception => ex
          write_status_message(ex.message)
          return []
        end
        CursedConsole::Logger.debug("The list returned from the server: #{list.inspect}")
        if list.is_a?(Hash)
          if list.has_key?('error')
            list = []
          else
            list = list.keys.map { |k| k.to_s }
          end
        end
        # list = list.is_a?(Hash) ? list.keys.map { |k| k.to_s } : list
        %x{ echo "Resource list: #{list.inspect}" >> log.txt }
      else
        list = ResourceAccessor.resource_menu
      end
      if list.length > 0
        submenu = DropDownMenu.new(list, 
                                  nil, # sub_path
                                  nil, # plugin_manager
                                  field.line + 3, 
                                  field.start_col + 1, 
                                  nil)
        selected = submenu.select_menu_item.tap do | selection |
          submenu.clear
          submenu.refresh
          submenu.close
          Curses::curs_set(1)
          render_fields
        end
        refresh
      else
        selected = [ ]
      end
      %x{ echo "Selected item: '#{selected.inspect}'" >> log.txt }
      if selected.present?
        if field_config[:select_list].is_a?(Array)
          field.value = selected.first # field_config[:select_list][selected.first].first
        elsif field_config[:select_list].is_a?(String)
          field.value = selected.first # list[selected.first]
        else
          field.value = selected.inspect
        end
        render_field_value(field)
      end
    end

    def write_status_message(message=nil, offset=0)
      # %x{ echo "Line: #{lines - 1}, Message: #{message}" >> log.txt}
      # Clear the status line
      setpos(maxy - 4, 1)
      attron(Curses::A_STANDOUT)
      addstr(" " * (maxx - 2))
      attroff(Curses::A_STANDOUT)

      if ! message.nil?
        setpos(maxy - 4, 2)
        attron(Curses::A_STANDOUT)
        addstr(message)
        attroff(Curses::A_STANDOUT)
      end
    end


  end

end

