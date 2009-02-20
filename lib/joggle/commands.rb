module Joggle
  module Commands
    def do_register(who, arg)
      # see if user is registered
        File.open('/tmp/foo.log', 'a') do |fh|
          fh.puts("who = #{who}, arg = #{arg}")
        end
      if user = @tweeter.registered?(who)
        # user is registered, return error
        msg = "Already registered as #{user}"
      else 
        # user isn't registered, so add them
         
        # get twitter username and password from argument
        user, pass = arg.split(/\s+/, 2)

        # register user
        begin 
          @tweeter.register(who, user, pass)
          msg = "Registered as #{user}"
        rescue Exception => err
          msg = "Couldn't register: #{err}"
        end
      end
        File.open('/tmp/foo.log', 'a') do |fh|
          fh.puts("msg = #{msg}")
        end

      # reply to request
      reply(who, msg)
    end

    def do_unregister(who, arg)
      # see if user is registered
      if @tweeter.registered?(who)
        # user is registerd, so unregister them
         
        begin 
          # unregister user
          @tweeter.unregister(who)

          # send success
          msg = "Unregistered."
        rescue Exception => err
          msg = "Couldn't unregister: #{err}"
        end
      else 
        # user isn't registered, send error
        msg = "Not registered."
      end

      # reply to request
      reply(who, msg)
    end

    def do_list(who, arg)
      # see if user is registered
      if @tweeter.registered?(who)
        # user is registerd, so unregister them
         
        begin 
          msgs = []

          # build list
          @tweeter.list(who) do |id, time, from, msg|
            msgs << make_response(id, time, from, msg)
          end

          # build response
          if msgs.size > 0
            msg = msgs.join("\n")
          else
            msg = 'No tweets.'
          end
        rescue Exception => err
          msg = "Couldn't list tweets: #{err}"
        end
      else 
        # user isn't registered, send error
        msg = "Not registered."
      end

      # reply to request
      reply(who, msg)
    end

    HELP = [
      "This is a help message",
      "Eventually help commands will go here."
    ].join("\n")

    def do_help(who, arg)
      reply(who, HELP)
    end
  end
end
