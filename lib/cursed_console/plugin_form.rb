module CursedConsole

  #
  # This class creates and manages a user data-entry form.
  #
  class PluginForm < Curses::Window

    attr_accessor :resource, :action, :current_field
    attr_accessor :the_form, :fields, :status_bar

    FIELD_START_Y = 2
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
      setpos(0, col)
      addstr(the_form[:title])
    end

    def render_fields
      fields_already_populated = fields.size > 0
      field_y = FIELD_START_Y # We leave a line below the title of the form
      the_form[:fields].each_pair do | field_name, field_config |
        setpos(field_y, LABEL_START_COL)
        addstr(field_config[:label])
        field_start_col = LABEL_START_COL + field_config[:label].length + LABEL_FIELD_GAP
        unless fields_already_populated
          field_info = FieldInfo.new(field_name, field_config[:type], field_y, field_start_col, field_start_col + field_config[:width], field_config[:default].present? ? field_config[:default] : "")
          field_info.display_name = field_config[:display_name]
          self.fields << field_info
        end
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
                Logger.error(ex.message)
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
        when 330 # delete key
          if field.type == :text
            field.remove_char
            render_field_value(field)
          end
        when 127, 263 # backspace
          if field.type == :text
            field.remove_char(true)
            render_field_value(field)
          end
        else
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
        field = fields.detect { | field | field.name == replaceable.slice(1..-1).to_sym }
        if the_form[:fields][field.name][:validate].present?
          regex = the_form[:fields][field.name][:validate]
          raise "Invalid value for #{field.name}" unless field.value =~ regex
        end
        value = the_form[:fields][field.name][:base64_encoded] ? Base64.urlsafe_encode64(field.value) : field.value
        if value.is_a?(Hash)
          value = value['id']
        end
        raise "Must specify value for #{replaceable}" if value.blank?
        uri = uri.gsub(replaceable, value.to_s)
      end
      uri
    end

    def process_form_result(web_service_client)
      return if the_form[:result].nil?
      uri = format_uri(the_form[:result])
      list = resource.send(the_form[:result_formatter], web_service_client, uri, fields.inject({}) {|acc,fld| acc[fld.name] = fld.value; acc })
      # TODO: THis should be a DataList
      submenu = DropDownMenu.new(list, 
                                nil, # sub_path
                                nil, # plugin_manager
                                1,
                                1)
      selected = submenu.select_menu_item.tap do | selection |
        submenu.clear
        submenu.refresh
        submenu.close
        Curses::curs_set(1)
        render_fields
      end
      refresh
    end

    def get_hard_coded_item_list(field_config)
      # This is a hard-coded list of selections in the resource
      field_config[:select_list].map do | tuple |
        { 'id' => tuple.first, 'display' => tuple.last }
      end
    end

    def get_server_item_list(field_config, web_service_client)
      # This is supposed to be a call to a web service
      begin
        uri = format_uri(field_config[:select_list])
      rescue StandardError => ex
        Logger.error(ex.message)
        return []
      end
      begin
        list = web_service_client.get(uri)
      rescue Exception => ex
        Logger.error(ex.message)
        return []
      end
      Logger.debug("The list returned from the server: #{list.inspect}")
      display_lambda = field_config[:display_name]
      if display_lambda
        list.each do | item |
          item['display'] = display_lambda.call(item)
        end
      end
      list
    end

    def get_item_list(field_config, web_service_client)
      if field_config[:select_list].is_a?(Array)
        get_hard_coded_item_list(field_config)
      elsif field_config[:select_list].is_a?(String)
        get_server_item_list(field_config, web_service_client)
      else
        list = ResourceAccessor.resource_menu
      end
    end

    def render_sub_menu(field, web_service_client)
      field_config = the_form[:fields][field.name]
      list = get_item_list(field_config, web_service_client)
      if list.length > 0
        submenu = DropDownMenu.new(list, 
                                  nil, # next_level
                                  nil, # plugin_manager
                                  field.line + 3, 
                                  field.start_col + 1)
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
      Logger.debug("Selected item: '#{selected.inspect}'")
      if selected.present?
        field.value = list.detect { | item | item['id'] == selected }
        render_field_value(field)
        if field_config[:populate_form].present?
          field_config[:populate_form].each do | field_name |
            f = fields.detect { |fld| fld.name == field_name.to_sym }
            f.value = field.value[field_name] # if f.present?
          end
          render_fields
        end
      end
    end

  end

end

