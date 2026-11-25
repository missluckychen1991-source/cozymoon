// Learning Hub content: 3 gentle steps a day, never more.
// Everything here is general wellness information, not medical advice.

class QuizStep {
  const QuizStep(
      {required this.question,
      required this.options,
      required this.answer,
      required this.explain});
  final String question;
  final List<String> options;
  final int answer;
  final String explain;
}

class ConceptStep {
  const ConceptStep(
      {required this.title, required this.points, required this.whyItMatters});
  final String title;
  final List<String> points;
  final String whyItMatters;
}

class ActionStep {
  const ActionStep({
    required this.snackTitle,
    required this.snack,
    required this.stretchTitle,
    required this.stretch,
  });
  final String snackTitle;
  final List<String> snack;
  final String stretchTitle;
  final List<String> stretch;
}

class LessonDay {
  const LessonDay(
      {required this.theme,
      required this.emoji,
      required this.quiz,
      required this.concept,
      required this.action});
  final String theme;
  final String emoji;
  final QuizStep quiz;
  final ConceptStep concept;
  final ActionStep action;
}

const lessonDays = <LessonDay>[
  LessonDay(
    theme: 'Bone & Muscle Banking',
    emoji: '🦴',
    quiz: QuizStep(
      question: 'Around what age do most women reach their peak bone mass?',
      options: ['Around 18', 'Around 30', 'Around 45'],
      answer: 1,
      explain:
          'Bone mass peaks around your late 20s to early 30s. After that the goal is keeping what '
          'you have, and the habits you build now really do help.',
    ),
    concept: ConceptStep(
      title: 'Your 30s and 40s are a savings account',
      points: [
        'Muscle slowly starts to decline from your 30s if you don\'t use it. Strength work reverses a lot of that, at any age.',
        'Bones respond to load. Lifting, stairs, brisk walks and little hops tell them to stay strong.',
        'Two short strength sessions a week is a great start. Bodyweight counts.',
        'Protein at each meal, plus calcium and vitamin D, give your body the building blocks.',
      ],
      whyItMatters:
          'Strong muscles and bones mean carrying your own groceries, travelling solo and '
          'feeling capable for decades. That\'s leveling up, not slowing down.',
    ),
    action: ActionStep(
      snackTitle: '5-minute strong-bones yogurt bowl',
      snack: [
        'A big scoop of Greek yogurt (or a fortified plant yogurt)',
        'A handful of almonds or walnuts',
        'Berries or a sliced banana',
        'A drizzle of honey if you like',
      ],
      stretchTitle: '2-minute pajama strength',
      stretch: [
        'Stand in front of a chair. Sit down slowly, stand back up. 10 times.',
        'Hold the back of the chair and rise onto your toes, then lower. 10 times.',
        'Shake out your arms and legs. Done!',
      ],
    ),
  ),
  LessonDay(
    theme: 'Decoding Luteal Cravings',
    emoji: '🍫',
    quiz: QuizStep(
      question:
          'Why do many women crave more food in the week or two before their period?',
      options: [
        'It\'s a lack of willpower',
        'Hormone shifts, and the body uses a little more energy',
        'It\'s all in your head',
      ],
      answer: 1,
      explain:
          'After ovulation, progesterone rises and your resting energy use can go up a little. Mood '
          'chemicals like serotonin can dip too, which makes carbs extra tempting. Your body isn\'t '
          'failing, it\'s asking.',
    ),
    concept: ConceptStep(
      title: 'Cravings are messages, not crimes',
      points: [
        'The luteal phase is the stretch between ovulation and your period, usually about 2 weeks.',
        'Pairing carbs with protein or fat (toast with peanut butter, oats with nuts) keeps energy steadier.',
        'Magnesium-rich foods like dark chocolate, nuts, seeds and leafy greens are good friends this week.',
        'Regular meals help. Long gaps make cravings louder.',
      ],
      whyItMatters:
          'When you know why it happens, you can plan for it and drop the guilt. A planned '
          'treat feels much better than a 1 a.m. raid.',
    ),
    action: ActionStep(
      snackTitle: 'Warm cocoa-banana oats',
      snack: [
        'Half a cup of oats cooked with milk or water',
        'Stir in 1 teaspoon of cocoa powder',
        'Top with sliced banana and a spoon of nut butter',
        'Pinch of cinnamon on top',
      ],
      stretchTitle: '2-minute legs up the wall',
      stretch: [
        'Lie on your back with your bottom close to a wall.',
        'Swing your legs up so they rest on the wall. Arms relaxed by your sides.',
        'Breathe slowly into your belly for 2 minutes. Lovely for crampy, puffy days.',
      ],
    ),
  ),
  LessonDay(
    theme: 'Sleep Through Your Cycle',
    emoji: '😴',
    quiz: QuizStep(
      question: 'Which of these can make sleep worse just before your period?',
      options: [
        'Your body temperature runs slightly higher',
        'You\'re secretly a night owl that week',
        'Your pillow is too soft',
      ],
      answer: 0,
      explain:
          'After ovulation, progesterone nudges your core temperature up a little. A warmer body '
          'finds it harder to fall and stay asleep, so a cooler room really helps.',
    ),
    concept: ConceptStep(
      title: 'Your sleep has seasons too',
      points: [
        'Many women sleep lighter in the days before their period and during the first days of bleeding.',
        'From the late 30s and 40s, changing hormones can bring night sweats or 3 a.m. wake-ups. Very common, and worth mentioning to a doctor if it bothers you.',
        'Keep the bedroom cool, dark and quiet. Breathable sheets are worth it.',
        'A steady wake-up time, morning daylight and less late-night alcohol all make sleep deeper.',
      ],
      whyItMatters:
          'Good sleep softens cramps, cravings and mood swings. Protecting it is one of the '
          'kindest things you can do for future you.',
    ),
    action: ActionStep(
      snackTitle: 'Sleepy-time tea and toast',
      snack: [
        'A cup of chamomile or another caffeine-free herbal tea',
        'Half a slice of wholegrain toast with a little nut butter',
        'Have it about an hour before bed, away from screens if you can',
      ],
      stretchTitle: '2-minute bedtime unwind',
      stretch: [
        'Lie on your back and hug your knees to your chest. Rock gently side to side for 30 seconds.',
        'Drop both knees to the right, arms out wide, head to the left. Breathe for 30 seconds. Switch sides.',
        'Finish with 3 slow breaths, longer out than in.',
      ],
    ),
  ),
];
