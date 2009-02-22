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
      # TODO: "  .force <msg>            - Force tweet.",
      # TODO: "  .list                   - List recent tweets.",
      "Any other message with two words or more is sent as a tweet.  See the Joggle home page at http://pablotron.org/software/joggle/ for additional information",
    ].join("\n")

    #
    # Handle .help command.
    #
    def do_help(who, arg)
      reply(who, HELP)
    end

    EGGS = [
      # movie quotes
      "This is what happens, Larry!",
      "Got a package, people!",
      "Billy, do you like wrestling?",
      "NO AND DEN!",
      "I'm the dude playing the dude disguised as another dude.",
      "Hey, want to hear the most annoying sound in the world?",
      "Bueller?",
      "Inconcievable!",

      # non-movie quotes
      "You are in a maze of twisty compiler features, all different.",
      "You can tune a filesystem, but you can't tuna fish.",
      "Never attribute to malice that which can adequately explained by stupidity.",
      "The first thing to do when you find yourself in a hole is to stop digging.",
      "I once knew a man who had a dog with only three legs, and yet that man could play the banjo like anything.",
      "The needs of the many outweigh the needs of the guy who can't run fast.",
      "It may look like I'm doing nothing, but I'm actively waiting for my problems to go away.",
      "Nobody ever went broke underestimating the intelligence of the American people.",
      "There are only two things wrong with C++: The initial concept and the implementation.",
      "There are only two kinds of people, those who finish what they start, and so on.",

      # exclamations
      "I'LL SAY!!!",
      "AND HOW!!!",
      "Cha-ching!",
      "Crikey!",
      "Nope.",
      "Sweet!",
      "Blimey!",

      # emoticons
      ":-D",
      "^_^",
      ":(",
      ":-)",
      ":')-|-<",

      # misc
      "http://pablotron.org/offended",
      "<INSERT WITTY REMARK HERE>",
      "0xBEEFCAFE",
    ]

    def do_easteregg(who, arg)
      reply(who, EGGS[rand(EGGS.size])
    end
  end
end
