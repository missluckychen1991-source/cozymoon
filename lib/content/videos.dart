/// Calm video slots for the No-Doomscroll Corner.
///
/// To pick a video, open it on YouTube, copy the part after "watch?v=" (for
/// example the "abc123XYZ_0" in youtube.com/watch?v=abc123XYZ_0) and paste it
/// as [youtubeId]. Until a slot has an id, tapping it searches YouTube instead.
class CalmVideo {
  const CalmVideo(
      {required this.title,
      required this.emoji,
      required this.search,
      this.youtubeId});
  final String title;
  final String emoji;
  final String search;
  final String? youtubeId;
}

const calmVideos = <CalmVideo>[
  CalmVideo(
      title: 'Pottery wheel, no talking',
      emoji: '🏺',
      search: 'relaxing pottery wheel no talking'),
  CalmVideo(
      title: 'Cozy rain walk',
      emoji: '🌧️',
      search: 'rain walk ambience 4k no talking'),
  CalmVideo(
      title: 'Slow baking', emoji: '🥐', search: 'slow baking asmr no talking'),
  CalmVideo(
      title: 'Capybaras chilling',
      emoji: '🦫',
      search: 'capybara hot spring relaxing'),
  CalmVideo(
      title: 'Sea otters holding hands',
      emoji: '🦦',
      search: 'sea otters relaxing'),
  CalmVideo(
      title: 'Gentle forest stream',
      emoji: '🌿',
      search: 'forest stream relaxing nature'),
];
