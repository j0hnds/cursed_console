module CursedConsole

  class BaseResource

    def requires_input_for?(method)
      action_hash = send(method)
      action_hash.present? && action_hash[:fields].present?
    end
  end

end
