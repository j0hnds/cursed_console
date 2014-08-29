module CursedConsole

  class List < Array

    attr_reader :display_lambda

    def initialize(ary, display_lambda=nil)
      super(ary)

      @display_lambda = display_lambda
    end

    def each_display
      each do | item |
        yield display_lambda.nil? ? item : display_lambda.call(item)
      end
    end

    def slice_display(range)
      CursedConsole::List.new(slice(range), display_lambda)
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
