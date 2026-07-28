/// One bucket of an owner dashboard chart series — a single day as fetched
/// from the server, or a week/month/year after client-side resampling.
class DailyEvent {
  const DailyEvent({
    required this.day,
    required this.views,
    required this.favorites,
    required this.phoneClicks,
    required this.messages,
    required this.bookings,
  });

  factory DailyEvent.fromMap(Map<String, dynamic> map) {
    return DailyEvent(
      day: DateTime.parse(map['day'] as String),
      views: map['views'] as int,
      favorites: map['favorites'] as int,
      phoneClicks: map['phone_clicks'] as int,
      messages: map['messages'] as int,
      bookings: map['bookings'] as int,
    );
  }

  final DateTime day;
  final int views;
  final int favorites;
  final int phoneClicks;
  final int messages;
  final int bookings;
}
