module CursedConsole

  module List 

    attr_accessor :display_lambda

    def each_display
      each do | item |
        yield display_lambda.nil? ? item : display_lambda.call(item)
      end
    end

    def detect_display
      detect do | item |
        yield display_lambda.nil? ? item : display_lambda.call(item)
      end
    end

    def slice_display(range)
      slice(range).tap { | a | a.display_lambda = display_lambda }
    end

    def item_width
      inject(0) do | acc, item |
        item_length = display_lambda.nil? ? item.length : display_lambda.call(item).length
        acc = item_length if item_length > acc
        acc
      end
    end

    def each_display_with_index
      CursedConsole::Logger.debug("The List: #{self.inspect}")
      CursedConsole::Logger.debug("The lambda? #{self.display_lambda.nil?}")
      each_with_index do | item, index |
        CursedConsole::Logger.debug("The lambda? #{self.display_lambda.nil?}")
        yield (self.display_lambda.nil? ? item : self.display_lambda.call(item)), index
      end
    end

  end

end

#
# Extend array with this beautiful stuff
#
class Array
  include CursedConsole::List;
end
