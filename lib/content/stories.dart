enum StoryTag { romance, sliceOfLife, funny, sleepy }

extension StoryTagLabel on StoryTag {
  String get label => switch (this) {
        StoryTag.romance => 'Soft Romance',
        StoryTag.sliceOfLife => 'Cozy Slice-of-Life',
        StoryTag.funny => 'Light & Funny',
        StoryTag.sleepy => 'Sleepy Tale',
      };
  String get emoji => switch (this) {
        StoryTag.romance => '🌸',
        StoryTag.sliceOfLife => '☕',
        StoryTag.funny => '😂',
        StoryTag.sleepy => '🌙',
      };
}

class Story {
  const Story(
      {required this.title,
      required this.tag,
      required this.minutes,
      required this.body});
  final String title;
  final StoryTag tag;
  final int minutes;
  final String body;
}

const stories = <Story>[
  Story(
    title: 'The Umbrella Swap',
    tag: StoryTag.romance,
    minutes: 3,
    body:
        '''Linh grabbed the wrong umbrella from the café stand. She only noticed at the bus stop, when she opened it and found it covered in tiny cartoon ducks.

Hers was plain navy. Sensible. This one quacked with personality.

The next morning she brought it back. The barista pointed at a man by the window, reading with a navy umbrella hooked over his chair. He looked up, saw the ducks, and laughed so suddenly that he dropped his book.

"I've been carrying yours around feeling very serious," he said. "It's been a strange day."

"I've been carrying yours feeling very silly," she said. "It's been a lovely day."

They swapped back. Then they ordered another coffee, because the rain hadn't stopped and neither of them was in a hurry.

He came every Tuesday after that. So did she. Sometimes they talked about books. Sometimes they just sat at neighbouring tables, comfortable, the way you are with weather you like.

On the first sunny Tuesday, she found a small paper duck tucked under her saucer. On its wing, in tidy pencil: "Same time when it rains?"

She checked the forecast. Rain on Thursday. She smiled into her cup.''',
  ),
  Story(
    title: 'The Bakery on Hill Lane',
    tag: StoryTag.sliceOfLife,
    minutes: 3,
    body: '''At 5 a.m., Hill Lane belongs to Mai and her oven.

She opened the bakery at forty-one, after a decade of spreadsheets and one very long winter of deciding. People told her it was a risk. She told them so was staying.

The first loaves come out crackling. She listens to them the way other people listen to music, a soft popping as the crust cools. The cat from next door sits on the windowsill and supervises.

Her regulars arrive in order. The nurse finishing a night shift, who takes two cinnamon buns and says nothing until the first one is gone. The old man who argues gently about the weather. The teenager who is trying to save money and always "just looks", so Mai always has a "slightly broken" croissant she can't possibly sell.

By noon her arms ache and her shelves are empty. She sweeps flour off the floor, sets the chairs on the tables, and stands for a moment in the warm, quiet room.

Nobody gave her this life. She built it, one early morning at a time. Tomorrow she'll try a new recipe with cardamom. She writes it on the chalkboard so she can't back out.''',
  ),
  Story(
    title: 'The Plant Who Would Not Die',
    tag: StoryTag.funny,
    minutes: 2,
    body:
        '''Hana has killed eleven plants. She has a spreadsheet. It is colour-coded in shades of regret.

Plant number twelve is a pothos named Gerald, bought out of spite after a coworker said, "Some people just aren't plant people."

Hana forgets to water Gerald for two weeks. Gerald grows a new leaf.

She over-waters Gerald out of guilt. Gerald grows two more.

She goes on holiday and forgets to ask anyone to look after him. She returns to find Gerald has wrapped himself halfway around the curtain rod like he's planning an escape, or a takeover.

"Are you okay?" she asks him.

Gerald, being a plant, says nothing. But he looks smug.

Her friends start sending her photos of their dying plants, asking for advice. She has no advice. She just says, "Talk to them like a coworker you're slightly afraid of."

It works. Nobody knows why.

Gerald now has three children in jars on the windowsill. Hana has updated her spreadsheet. There is a new colour. It is green.''',
  ),
  Story(
    title: 'The Night Train North',
    tag: StoryTag.sleepy,
    minutes: 4,
    body:
        '''The night train hums as it leaves the city. You have a small cabin all to yourself, with a narrow bed, a reading lamp, and a window the size of a painting.

You change into soft clothes. The sheets are cool and smell faintly of lavender. Somewhere down the corridor, a door clicks shut.

Outside, the city lights thin out and become towns, then villages, then nothing but dark fields and a slow, silver moon.

The train sways, gently, like a hammock. The wheels keep a steady rhythm on the rails. Tik-tak. Tik-tak. Tik-tak.

There is nothing you need to do now. No messages to answer. No one to look after. The train knows the way.

You notice your shoulders drop a little. Your jaw softens. Your breath slows to match the rhythm under you. Tik-tak. Tik-tak.

A station passes, sleepy and yellow-lit. A man in a cap lifts a lantern. Then it is gone, and there is only the dark again, and the hum, and the warm weight of the blanket.

In the morning there will be mountains and coffee and a new town to wander. But that is later. For now, there is only this: the rocking, the quiet, the long road north, and you, drifting, safe, carried.''',
  ),
  Story(
    title: 'Letters to the Lighthouse',
    tag: StoryTag.romance,
    minutes: 3,
    body:
        '''Every month, a letter arrives at the lighthouse museum addressed simply "To whoever is reading this."

Ana, the museum's only staff member, reads them all. They come from someone named R., who describes the sea from a city very far from it. "I've never seen a lighthouse," the first one said. "But I like knowing someone keeps a light on."

Ana writes back. She describes the fog rolling in, the gulls arguing, the way the lamp turns like a slow, patient thought.

The letters grow longer. They trade favourite soups, worst haircuts, and the books that saved them at seventeen. R. is funny in a quiet way. Ana finds herself saving the letters for evenings, with tea.

One spring, a letter says: "I've booked a train. Would it be strange to visit?"

It would be strange, Ana thinks. Strange and wonderful.

R. turns out to be a woman with paint on her sleeves and a nervous laugh that matches her handwriting exactly. They climb the stairs together. At the top, R. goes very quiet, looking at the sea.

"It's bigger than you wrote it," she says.

"You'll have to stay longer," Ana says, "so I can describe it properly."''',
  ),
  Story(
    title: 'The Snow Day Library',
    tag: StoryTag.sleepy,
    minutes: 3,
    body:
        '''The snow started at noon and by two the whole town had gone soft and silent.

The little library stays open, because the librarian lives upstairs and says it would be rude to close on such a nice day.

You find a deep armchair by the radiator. Someone has left a knitted blanket over the arm. You pull it over your knees.

Outside the tall windows, snowflakes drift down past the streetlamp, slow as feathers. Inside, the radiator ticks and sighs. A clock somewhere counts the minutes without hurrying them.

You pick a book you've read before, one you love, so there's no worry about how it ends. The pages are soft at the corners.

The librarian walks by with a pot of tea and pours you a cup without asking. "Snow days are for slow things," she says.

You read a page. Then another. The words begin to blur, gently. You let your eyes close for a moment, the book open on your chest, the warmth of the tea still in your hands.

The snow keeps falling. The town keeps sleeping. Nobody needs anything from you at all.''',
  ),
];

/// Tiny calm activities for the Mystery Comfort Envelope.
const comfortPrompts = <String>[
  'Put your hand on your belly. Breathe in through your nose for 4, out through your mouth for 6. Three times. That\'s it.',
  'Name 5 things you can see, 4 you can touch, 3 you can hear, 2 you can smell and 1 you can taste.',
  'Make the warmest drink you have and hold the mug with both hands until it\'s done.',
  'Roll your shoulders back 5 times, then let your jaw hang loose for 10 seconds.',
  'Text someone you like a single emoji. No explanation needed.',
  'Lie on the floor with your legs up the wall for 2 minutes. Let gravity do the work.',
  'Write down one thing your body did for you today, even if it\'s just "got me to the couch".',
  'Open a window and take three slow breaths of outside air.',
];
