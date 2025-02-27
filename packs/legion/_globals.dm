GLOBAL_VAR_CONST(legion_warp_sound, 'packs/legion/sounds/legion_arrive.ogg')

GLOBAL_LIST_INIT(legion_voices_sounds, list(\
	'packs/legion/sounds/legion_voices1.ogg'\
))


/// List of strings. Pool of generic messages to use for legion broadcast and narration events.
GLOBAL_LIST_INIT(legion_narrations, list(\
	"A cacaphony of voices suddenly floods you. You can't make anything out.",\
	"The voices. There's so many voices. They're all crying out in endless agony.",\
	"You hear a thousand voices all at once, each trying to scream over the rest. The sound drowns itself out.",\
	"A tidal force of voices shakes your very being, each one shifting in volume and pitch to such degree that it's nothing but an overbearing white noise.",\
	"A wave of voices coalesce and your ears ring as if struck by a hammer.",\
	"A flood of voices crash against eachother with their pleas, their cries and their dying breathes in never-ending throes of noise, sometimes they blend together into nothingness-- and then they come back, stronger and more desperate.",\
	"A turgid symphony assaults you. Fleshy primordial noises are all you can make out. This place is where one abandons their dreams."\
))


/// List of strings. Pool of generic individual voices that can be heard for legion broadcast and narration events.
GLOBAL_LIST_INIT(legion_last_words_generic, list(\
	"I don't want to die!",\
	"No, get away!",\
	"I give up. Just do it already.",\
	"I'm so scared...",\
	"Help me!",\
	"It's so hot!",\
))


/// List of strings. Pool of individual voices from harvested player characters from this round to be used for legion broadcast and narration events. Format should be `"Character Name" => "Last Message/Thought"`
GLOBAL_LIST_INIT(legion_last_words_player, list(\
	list("Andrew Caine", "... I accept your terms. Me and my ship in exchange for my crew escaping unharmed."),\
	list("F.I.N.D.", "I have one final request. Destroy my positronic matrix so they can't have it.")\
))
