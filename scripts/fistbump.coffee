# Description:
#   Recognize users with "fistbumps" for achievements
#
# Commands:
#   :fistbump: <@user> <description> - Award fistbumps to a user
#
# Author:
#   gesparza3

winston = require "./config/winston"
Recognition = require "./recognition"
RecognitionStore = require "./service/recognitionStore"

module.exports = (bot) ->

  # Bot will listen for the :fistbump: emoji in channels it's invited to
  bot.hear /:fistbump:/, (msg) ->
    # Create new Recognition
    rec = new Recognition msg.envelope.user, msg.message.text

    # Add recipients mentioned in recognition
    rec.addRecipients(bot)
    if rec.recipients.length < 1
      winston.info("User[#{rec.sender.name}] did not mention any recipient")
      msg.reply "Forgetting something? Try again..." +
        "this time be sure to mention who you want to recognize with `@user`"

    # Check if user is attempting to recognize themselves
    else if rec.userSelfReferenced()
      winston.info("User[#{rec.sender.name}] recognized themself")
      msg.reply "Nice try `#{@sender.name}`, but you can't toot your own horn!"

    # Verify message has enough detail
    else if !rec.descriptionLengthSatisfied msg.message.text
      winston.info("Description was too short, recognition not sent")
      msg.reply "Whoops, not enough info!" +
        "Please provide more details why you are giving :fistbump:"

    # check recognition count
    curRec = RecognitionStore.countRecognitionsGiven bot, rec.sender, rec.sender.mm.timezone, 1
    desiredRec = curRec + rec.recipients.length 
    winston.debug("User #{rec.sender.name} has sent #{curRec}")
    else if desiredRec > 5
      msg.reply "Sorry you can't do that"

    # Message meets requirements, make reccomendation
    else
      winston.info("Valid recognition, #{rec.sender.name} awarding recpient(s)")

      # Store recognition in brain
      RecognitionStore.giveRecognition(bot, rec)

      # Send recognition notification to receipients
      for r in rec.recipients
        bot.messageRoom r, "You've been recognized by @#{rec.sender.name}!"

      # Reply to sender
      bot.messageRoom rec.sender.name, "Your recognition has been sent!" +
        "Well done! You have [] left to give today"
