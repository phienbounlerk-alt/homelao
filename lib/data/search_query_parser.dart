/// Result of parsing a free-text query into structured filters.
/// [cleanedQuery] is what's left after stripping the recognized phrases and
/// common filler words — that's what still gets sent to the existing
/// free-text search (title/location/description ilike), so the parser only
/// ever narrows results, it never invents matches on its own.
class ParsedSearchQuery {
  const ParsedSearchQuery({
    required this.cleanedQuery,
    required this.matches,
    this.maxPrice,
    this.minBeds,
    this.parking = false,
    this.petFriendly = false,
  });

  final String cleanedQuery;
  final double? maxPrice;
  final int? minBeds;
  final bool parking;
  final bool petFriendly;

  /// Human-readable labels for what was understood, shown as removable
  /// chips so the user can see — and undo — what the parser picked up.
  final List<String> matches;

  bool get isEmpty =>
      maxPrice == null && minBeds == null && !parking && !petFriendly;
}

/// Rule-based (no external API — see the plan discussion on why) natural-
/// language search parser. Recognizes Lao and English phrasing for price
/// ceilings, bed counts, parking, and pet-friendliness. Everything else is
/// run through a stopword filter so a full sentence like "I need a room
/// near the university" reduces to just "university" for the free-text
/// match, instead of the whole sentence (which would never ilike-match
/// anything). Listing titles/locations in this app are written in Lao, so
/// a Lao query like "ໃກ້ມະຫາວິທະຍາໄລ" actually matches real listings;
/// an English landmark word like "university" is extracted correctly too,
/// but won't match Lao-script listing text — that's a real limitation of
/// plain ilike search, not something this parser can fix on its own.
class SearchQueryParser {
  SearchQueryParser._();

  // No trailing \b after the Lao alternatives below: Dart's regex \w (and
  // therefore \b) only recognizes ASCII word characters, so a boundary
  // check right after a Lao word — e.g. between "ລ້ານ" and an immediately
  // adjacent "ກີບ", which Lao is routinely written with no space between —
  // silently never matches. \b still works fine right after a digit (0-9
  // *is* \w), which is the only place these patterns actually need it.
  // No bare "m" abbreviation here — without a working \b to anchor it (see
  // above), "m" would match inside any nearby word containing the letter
  // (e.g. "2 meter room" misreading "m" from "meter" as million).
  static final _millionKip = RegExp(
    r'(\d+(?:\.\d+)?)\s*(?:ລ້ານ|million|mil)\s*(?:ກີບ|kip)?',
    caseSensitive: false,
  );
  static final _underPricePrefix = RegExp(
    r'(ຕ່ຳກວ່າ|ບໍ່ເກີນ|under|below|less than|up to)',
    caseSensitive: false,
  );
  static final _plainKip = RegExp(r'(\d{4,})\s*(?:ກີບ|kip)?');
  static final _bedCount = RegExp(
    r'(\d+)\s*(?:ຫ້ອງນອນ|ຫ້ອງ|bedrooms?|beds?)',
    caseSensitive: false,
  );
  static final _parkingWords = RegExp(
    r'\b(parking)\b|ບ່ອນຈອດລົດ|ຈອດລົດ',
    caseSensitive: false,
  );
  static final _petWords = RegExp(
    r'pet[\s-]?friendly|pets?\s+allowed|ລ້ຽງສັດ|ສັດລ້ຽງ',
    caseSensitive: false,
  );

  /// English filler words, removed via a `\b`-anchored regex — `\b` is
  /// reliable for ASCII text, so this only ever matches whole words (e.g.
  /// the "a" in the list never touches the "a" inside "apartment").
  static const _englishStopwords = [
    'i', 'a', 'an', 'the', 'is', 'are', 'want', 'wanted', 'need',
    'needed', 'looking', 'look', 'for', 'near', 'nearby', 'close', 'to',
    'with', 'that', 'has', 'have', 'my', 'me', 'please', 'room',
    'apartment', 'and', 'or', 'in', 'at', 'of', 'find', 'search', 'show',
  ];
  static final _englishStopwordPattern = RegExp(
    r'\b(?:' + _englishStopwords.join('|') + r')\b',
    caseSensitive: false,
  );

  /// Lao filler words. Dart's `\b` doesn't recognize Lao script (see the
  /// note above `_millionKip`), and Lao is routinely written with no spaces
  /// at all, so these are removed by plain substring replacement instead of
  /// a word-boundary regex. Sorted longest-first so a longer phrase (e.g.
  /// "ຄົ້ນຫາ") is removed whole rather than leaving a dangling remainder
  /// once its prefix ("ຄົ້ນ") is stripped first.
  static final _laoStopwords =
      [
        'ຂ້ອຍ', 'ຢາກ', 'ຕ້ອງການ', 'ໄດ້', 'ໃຫ້', 'ໃກ້', 'ຫາ', 'ຄົ້ນຫາ', 'ຄົ້ນ',
        'ມີ', 'ຢູ່', 'ແດ່', 'ນຳ', 'ໜ້ອຍ', 'ໜຶ່ງ', 'ຫຼື', 'ແລະ', 'ຫ້ອງ',
      ]..sort((a, b) => b.length.compareTo(a.length));

  static ParsedSearchQuery parse(String rawQuery) {
    var text = rawQuery;
    final matches = <String>[];
    double? maxPrice;
    int? minBeds;
    var parking = false;
    var petFriendly = false;

    // "2 million kip" (or "2 ລ້ານ ກີບ") is treated as a price ceiling on
    // its own — someone naming a round budget figure like this almost
    // always means "up to", so this doesn't require an extra "under" cue.
    // A bare 4+ digit number, on the other hand, is too ambiguous (could be
    // a street address) unless paired with an explicit under/below word.
    final millionMatch = _millionKip.firstMatch(text);
    if (millionMatch != null) {
      final value = double.tryParse(millionMatch.group(1)!);
      if (value != null) {
        maxPrice = value * 1000000;
        matches.add('ຕ່ຳກວ່າ ${_formatKip(maxPrice)} ກີບ');
        text = text.replaceRange(millionMatch.start, millionMatch.end, ' ');
      }
    } else if (_underPricePrefix.hasMatch(text)) {
      final plainMatch = _plainKip.firstMatch(text);
      if (plainMatch != null) {
        final value = double.tryParse(plainMatch.group(1)!);
        if (value != null) {
          maxPrice = value;
          matches.add('ຕ່ຳກວ່າ ${_formatKip(maxPrice)} ກີບ');
          text = text.replaceRange(plainMatch.start, plainMatch.end, ' ');
        }
      }
    }
    // Strip the "under/below" qualifier word itself in either price path —
    // it's not useful as free-text, and in the million-kip path especially
    // it sits fused directly against an adjacent Lao word with no space
    // (e.g. "ອາພາດເມັນຕ່ຳກວ່າ"), which would otherwise corrupt the
    // free-text ilike match against real listing titles.
    text = text.replaceAll(_underPricePrefix, ' ');

    final bedMatch = _bedCount.firstMatch(text);
    if (bedMatch != null) {
      final value = int.tryParse(bedMatch.group(1)!);
      if (value != null && value > 0) {
        minBeds = value;
        matches.add('$value+ ຫ້ອງນອນ');
        text = text.replaceRange(bedMatch.start, bedMatch.end, ' ');
      }
    }

    if (_parkingWords.hasMatch(text)) {
      parking = true;
      matches.add('ມີບ່ອນຈອດລົດ');
      text = text.replaceAll(_parkingWords, ' ');
    }

    if (_petWords.hasMatch(text)) {
      petFriendly = true;
      matches.add('ລ້ຽງສັດໄດ້');
      text = text.replaceAll(_petWords, ' ');
    }

    text = text.replaceAll(_englishStopwordPattern, ' ');
    // Lao stopwords are stripped from the edges of each whitespace-delimited
    // chunk only (not floating substring search through the middle) — Lao
    // queries here are written filler-word-first, content-word-last with no
    // internal spaces (e.g. "ຂ້ອຍຢາກໄດ້ຫ້ອງໃກ້ມະຫາວິທະຍາໄລ"), and a filler
    // word can legitimately appear as a substring *inside* a real content
    // word (e.g. "ຫາ" inside "ມະຫາວິທະຍາໄລ"), so removing it wherever it
    // matches would corrupt the word. Peeling repeatedly from each end is
    // safe because it never touches a match sitting inside untouched text.
    final cleaned = text
        .split(RegExp(r'\s+'))
        .map(_stripLaoEdgeStopwords)
        .where((w) => w.isNotEmpty)
        .join(' ')
        .trim();

    return ParsedSearchQuery(
      cleanedQuery: cleaned,
      matches: matches,
      maxPrice: maxPrice,
      minBeds: minBeds,
      parking: parking,
      petFriendly: petFriendly,
    );
  }

  static String _stripLaoEdgeStopwords(String chunk) {
    var result = chunk;
    var changed = true;
    while (changed) {
      changed = false;
      for (final word in _laoStopwords) {
        if (result.startsWith(word)) {
          result = result.substring(word.length);
          changed = true;
          break;
        }
      }
    }
    changed = true;
    while (changed) {
      changed = false;
      for (final word in _laoStopwords) {
        if (result.length > word.length && result.endsWith(word)) {
          result = result.substring(0, result.length - word.length);
          changed = true;
          break;
        }
      }
    }
    return result;
  }

  static String _formatKip(double v) {
    final s = v.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
