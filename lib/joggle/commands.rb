module Joggle
  #
  # Mixin to handle commands.
  #
  module Commands
    #
    # Handle .register command.
    #
    def do_register(who, arg)
      # see if user is registered
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

      # reply to request
      reply(who, msg)
    end

    #
    # Handle .unregister command.
    #
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

    #
    # Handle .list command.
    #
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

    #
    # String constant for .help command.
    #
    HELP = [
      "Joggle Help:",
      "Available commands:",
      "  .help                   - Display this help screen.",
      "  .register <user> <pass> - Register Twitter username and password.",
      "  .unregister             - Forget Twitter username and password.",
      # TODO: "  .force <msg>            - Forget Twitter username and password.",
      "Any other message with two words or more is sent as a tweet.",
      "See the <a title='Joggle home page' alt='Joggle home page' href='http://pablotron.org/software/joggle/'>http://pablotron.org/software/joggle/</a> for additional information",
    ].join("\n")

    #
    # Handle .help command.
    #
    def do_help(who, arg)
      reply(who, HELP)
    end
  end
end
