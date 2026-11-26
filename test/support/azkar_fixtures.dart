/// One azkar collection with two items, in the bundled asset's shape.
Map<String, dynamic> fixtureRoot() => {
  'collections': [
    {
      'id': 'c1',
      'nameAr': 'أذكار الصباح',
      'nameEn': 'Morning',
      'items': [
        {'text': 'ذِكْرٌ لَهُ ثَلَاثٌ', 'count': 3},
        {'text': 'ذِكْرٌ وَاحِدٌ'},
      ],
    },
  ],
};
