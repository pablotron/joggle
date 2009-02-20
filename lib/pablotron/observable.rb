module Pablotron
  module Observable
    class StopEvent < Exception; end

    def on(ev, &block)
      d = lazy_observable_init

      # get next id and create new handler
      ret = (d[:next_id] += 1)
      h = { :id => ret }

      # set handler type
      if ev.kind_of?(String) && block
        h[:fn] = block

        # add handler to handler list and id to id lut
        d[:handlers][ev] << h
        d[:id_lut][ret] = ev

      elsif !ev.kind_of?(String) && !block
        h[:obj] = ev
        d[:object_handlers] << h
      else
        raise "missing listener block"
      end

      # return id
      ret
    end

    def fire(ev, *args)
      d = lazy_observable_init
      ret = true

      # get handlers for this event
      handlers = d[:handlers][ev]

      begin 
        if handlers.size > 0
          handlers.each do |handler| 
            if fn = handler[:fn]
              # run handler
              fn.call(self, ev, *args)
            else
              # FIXME: do nothing, is this an error?
            end
          end
        end

        # get object handlers
        handlers = d[:object_handlers]

        if handlers.size > 0
          handlers.each do |handler|
            if o = handler[:obj]
              # build method symbol
              meth = "on_#{ev}".intern

              # check for method
              if o.respond_to?(meth)
                o.send(meth, self, *args)
              end
            else
              # FIXME: do nothing, is this an error?
            end
          end
        end
      rescue StopEvent => err
        fire(ev + '_stopped', err, *args)
        ret = false
      end

      # return result
      ret
    end

    def un(id)
      d = lazy_observable_init

      # look in event handlers
      if ev = d[:id_lut][id]
        d[:handlers][ev].reject! { |fn| fn[:id] == id }
      end

      # check object handlers
      d[:object_handlers].reject! { |o| o[:id] == id }

      nil
    end

    private

    def lazy_observable_init
      @__observable_data ||= {
        :next_id    => 0,
        :handlers   => Hash.new { |h, k| h[k] = [] },
        :object_handlers => [],
        :id_lut     => {},
      }
    end
  end
end
