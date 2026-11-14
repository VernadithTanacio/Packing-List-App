import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  runApp(const PackTrailApp());
}

// ---------- Colors (pink & violet palette) ----------

const kViolet = Color(0xFF8B5CF6);
const kHotPink = Color(0xFFE75C97);
const kLightViolet = Color(0xFFEDE3FF);
const kBackgroundPink = Color(0xFFFFE4F1);
const kSoftPink = Color(0xFFFCE7F3);
const kPinkStripe = Color(0xFFFBD3E6);
const kPinkLine = Color(0xFFF3B8D1);
const kCocoa = Color(0xFF7A3E5C);

const kHeaderGradient = LinearGradient(
  colors: [kViolet, kHotPink],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const kEssentialsCat = 'Essentials';
const kAllCat = 'All';

// Fonts from the HTML: Plus Jakarta Sans for headings, Inter for body text
TextStyle headStyle(double size, {Color color = kCocoa, FontWeight weight = FontWeight.w800}) =>
    GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: weight, color: color);

TextStyle bodyStyle(double size, {Color color = kCocoa, FontWeight weight = FontWeight.w500}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

// ---------- Data ----------

class PackItem {
  String name;
  String category;
  bool essential;
  bool packed;

  PackItem({required this.name, required this.category, this.essential = false, this.packed = false});

  PackItem copy() => PackItem(name: name, category: category, essential: essential);

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'essential': essential,
        'packed': packed,
      };

  factory PackItem.fromJson(Map<String, dynamic> j) => PackItem(
        name: j['name'] as String,
        category: j['category'] as String,
        essential: (j['essential'] as bool?) ?? false,
        packed: (j['packed'] as bool?) ?? false,
      );
}

class PackTemplate {
  final String id;
  String name;
  String emoji;
  String description;
  final bool builtIn;
  List<PackItem> items;

  PackTemplate({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.items,
    this.builtIn = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'description': description,
        'builtIn': builtIn,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory PackTemplate.fromJson(Map<String, dynamic> j) => PackTemplate(
        id: j['id'] as String,
        name: j['name'] as String,
        emoji: j['emoji'] as String,
        description: (j['description'] as String?) ?? '',
        builtIn: (j['builtIn'] as bool?) ?? false,
        items: (j['items'] as List)
            .map((e) => PackItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PackTrip {
  String name;
  String templateName;
  List<PackItem> items;

  PackTrip({required this.name, required this.templateName, required this.items});

  Map<String, dynamic> toJson() => {
        'name': name,
        'templateName': templateName,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory PackTrip.fromJson(Map<String, dynamic> j) => PackTrip(
        name: j['name'] as String,
        templateName: j['templateName'] as String,
        items: (j['items'] as List)
            .map((e) => PackItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// Items that every trip starts with
const essentialLines = [
  'Valid ID',
  'Phone + charger',
  'Power bank',
  'Cash / e-wallet backup',
  'Medicines',
  'Toiletries',
  'Extra clothes',
];

// Lines starting with # are category headers, the rest are items
List<PackItem> itemsFromLines(List<String> lines) {
  final result = <PackItem>[];
  var category = 'General';
  for (final line in lines) {
    if (line.startsWith('#')) {
      category = line.substring(1);
    } else {
      result.add(PackItem(name: line, category: category));
    }
  }
  return result;
}

PackTrip makeTrip(PackTemplate t) => PackTrip(
      name: t.name,
      templateName: t.name,
      items: [
        ...essentialLines.map((n) => PackItem(name: n, category: kEssentialsCat, essential: true)),
        ...t.items.map((i) => i.copy()),
      ],
    );

List<PackTemplate> defaultTemplates() => [
      PackTemplate(
        id: 'tpl-beach',
        name: 'Beach / Island',
        emoji: '🏝️',
        description: 'Carry-on friendly setup for beach and island hopping.',
        builtIn: true,
        items: itemsFromLines([
          '#Clothing',
          'Swimsuit or rash guard',
          'Shorts and light shirt',
          'Cover-up or sarong',
          'Sleepwear',
          'Light jacket for boat rides',
          '#Footwear',
          'Flip-flops or sandals',
          'Water shoes for rocks and coral',
          '#Sun Protection',
          'Reef-safe sunscreen',
          'Sunglasses',
          'Hat or cap',
          'After-sun lotion or aloe vera',
          '#Beach Gear',
          'Dry bag or waterproof pouch',
          'Quick-dry beach towel',
          'Snorkel mask and fins',
          'Reusable water bottle',
          '#Health and Safety',
          'Insect repellent',
          'Motion sickness pills',
          'Antiseptic and plasters',
          'Tissue or wet wipes',
          'Cold and cough medicine',
          '#Miscellaneous',
          'Power bank in a dry bag',
          'Cash (many islands have no ATM)',
          'Plastic bags for wet items',
          'Waterproof phone case',
        ]),
      ),
      PackTemplate(
        id: 'tpl-hiking',
        name: 'Hiking / Mountain',
        emoji: '⛰️',
        description: 'Layers, trail gear, and first aid for day hikes and trekking.',
        builtIn: true,
        items: itemsFromLines([
          '#Clothing',
          'Moisture-wicking shirts',
          'Hiking pants or quick-dry leggings',
          'Warm fleece or down jacket',
          'Waterproof rain jacket',
          'Thermal base layer',
          'Extra socks (wool or synthetic)',
          'Beanie and gloves',
          '#Footwear',
          'Hiking boots (broken in)',
          'Camp shoes or sandals',
          '#Gear',
          'Daypack (20 to 30 liters)',
          'Trekking poles',
          'Headlamp with extra batteries',
          'Trail map or offline GPS app',
          'Whistle',
          'Dry bags or plastic bags',
          '#Food and Water',
          'Water bottle or hydration bladder',
          'Water purification tablets or filter',
          'Trail snacks (nuts, energy bars, dried fruit)',
          'Packed lunch or instant meals',
          '#Health and Safety',
          'First aid kit',
          'Blister pads (moleskin)',
          'Insect repellent',
          'Sunscreen and lip balm',
          'Personal medicines',
          'Emergency blanket',
          'Tissue or wet wipes',
        ]),
      ),
      PackTemplate(
        id: 'tpl-city',
        name: 'City Trip',
        emoji: '🏙️',
        description: 'Light, smart-casual essentials for walking around the city.',
        builtIn: true,
        items: itemsFromLines([
          '#Clothing',
          'Light jacket',
          'Smart casual outfits',
          'Extra shirt',
          '#Footwear',
          'Comfortable walking shoes',
          '#Gear',
          'Daypack',
          'Umbrella',
          'Offline city map or app',
          'Reusable water bottle',
          'Camera (optional)',
          '#Health and Safety',
          'Sunscreen',
          'Hand sanitizer',
        ]),
      ),
      PackTemplate(
        id: 'tpl-camping',
        name: 'Camping',
        emoji: '⛺',
        description: 'Shelter, cooking, and warmth for nights under the stars.',
        builtIn: true,
        items: itemsFromLines([
          '#Clothing',
          'Warm layers',
          'Rain jacket',
          'Extra socks',
          '#Footwear',
          'Hiking shoes or rain boots',
          'Camp sandals',
          '#Gear',
          'Tent',
          'Sleeping bag',
          'Sleeping mat',
          'Stove and fuel',
          'Lighter or matches',
          'Headlamp or flashlight',
          'Cooler box',
          '#Food and Water',
          'Water container',
          'Cooking utensils',
          'Food and snacks',
          '#Health and Safety',
          'Insect repellent',
          'First aid kit',
          'Sunscreen',
        ]),
      ),
      PackTemplate(
        id: 'tpl-road',
        name: 'Road Trip',
        emoji: '🚗',
        description: 'Car comfort, snacks, and documents for long drives.',
        builtIn: true,
        items: itemsFromLines([
          '#Clothing',
          'Comfortable clothes',
          'Light jacket',
          '#Gear',
          'Car charger',
          'Car phone mount',
          "Driver's license",
          'Vehicle registration (OR/CR)',
          'Sunglasses',
          'Playlist downloaded offline',
          '#Food and Water',
          'Snacks',
          'Water bottles',
          '#Health and Safety',
          'First aid kit',
          'Motion sickness pills',
        ]),
      ),
      PackTemplate(
        id: 'tpl-weekend',
        name: 'Weekend Getaway',
        emoji: '🧳',
        description: 'A quick overnight bag with only the essentials.',
        builtIn: true,
        items: itemsFromLines([
          '#Clothing',
          'Light jacket',
          'Swimwear',
          'Sleepwear',
          '#Footwear',
          'Extra shoes',
          '#Gear',
          'Camera',
          'Toiletry bag',
          'Reusable bottle',
          '#Health and Safety',
          'Personal medicines',
          'Sunscreen',
        ]),
      ),
      PackTemplate(
        id: 'tpl-business',
        name: 'Business Trip',
        emoji: '💼',
        description: 'Work-ready clothes, electronics, and documents.',
        builtIn: true,
        items: itemsFromLines([
          '#Clothing',
          'Formal shirts',
          'Slacks or skirts',
          'Blazer',
          '#Footwear',
          'Dress shoes',
          '#Electronics',
          'Laptop and charger',
          'Travel adapter',
          'Power bank',
          '#Documents',
          'ID badge',
          'Printed itinerary',
          'Business cards',
          '#Gear',
          'Notebook and pen',
          'Toiletry bag',
        ]),
      ),
      PackTemplate(
        id: 'tpl-rainy',
        name: 'Rainy Season Trip',
        emoji: '🌧️',
        description: 'Stay dry with waterproof gear and quick-dry clothes.',
        builtIn: true,
        items: itemsFromLines([
          '#Clothing',
          'Quick-dry clothes',
          'Extra socks',
          'Light sweater',
          '#Footwear',
          'Waterproof shoes or rain boots',
          '#Gear',
          'Umbrella',
          'Raincoat',
          'Waterproof bag',
          'Plastic bags',
          '#Health and Safety',
          'First aid kit',
          'Insect repellent',
          'Tissue or wet wipes',
        ]),
      ),
      PackTemplate(
        id: 'tpl-cold',
        name: 'Cold Weather',
        emoji: '🧣',
        description: 'Layering system for chilly highland weather.',
        builtIn: true,
        items: itemsFromLines([
          '#Clothing',
          'Jacket',
          'Thermal wear',
          'Scarf',
          'Warm socks',
          'Beanie',
          'Gloves',
          '#Footwear',
          'Closed shoes',
          '#Health and Safety',
          'Moisturizer',
          'Lip balm',
          'Cough medicine',
        ]),
      ),
      PackTemplate(
        id: 'tpl-overnight',
        name: 'Overnight Provincial Trip',
        emoji: '🚌',
        description: 'Bag for trips to the province, with room for pasalubong.',
        builtIn: true,
        items: itemsFromLines([
          '#Gear',
          'Pillow',
          'Small blanket',
          'Umbrella',
          '#Food and Water',
          'Snacks',
          'Water bottle',
          '#Health and Safety',
          'Motion sickness pills',
          'Tissue',
          'Hand sanitizer',
          '#Miscellaneous',
          'Gifts for relatives',
          'Cash for fare and pasalubong',
        ]),
      ),
    ];

// ---------- Storage (saved on the device) ----------

class Store {
  static late SharedPreferences _prefs;
  static final List<PackTemplate> templates = [];
  static late PackTrip trip;

  static const _templatesKey = 'packtrail_templates';
  static const _tripKey = 'packtrail_trip';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    final rawTemplates = _prefs.getString(_templatesKey);
    if (rawTemplates == null) {
      templates.addAll(defaultTemplates());
      saveTemplates();
    } else {
      final list = jsonDecode(rawTemplates) as List;
      templates.addAll(
        list.map((e) => PackTemplate.fromJson(e as Map<String, dynamic>)),
      );
    }

    final rawTrip = _prefs.getString(_tripKey);
    trip = rawTrip == null
        ? makeTrip(templates.first)
        : PackTrip.fromJson(jsonDecode(rawTrip) as Map<String, dynamic>);
    saveTrip();
  }

  static void saveTemplates() {
    _prefs.setString(
      _templatesKey,
      jsonEncode(templates.map((t) => t.toJson()).toList()),
    );
  }

  static void saveTrip() {
    _prefs.setString(_tripKey, jsonEncode(trip.toJson()));
  }
}

// ---------- Shared widgets and decorations ----------

Widget softCard({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(16)}) {
  return Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: kPinkLine, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: kHotPink.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

InputDecoration inputDecoration(String hint, {IconData? icon}) => InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: bodyStyle(13, color: Colors.grey),
      prefixIcon: icon == null ? null : Icon(icon, size: 18, color: kViolet),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPinkLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPinkLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kHotPink, width: 2),
      ),
    );

Widget fieldLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: bodyStyle(12, weight: FontWeight.w700)),
    );

// Violet-to-pink gradient background with stripes and hearts
class GinghamPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = const LinearGradient(
      colors: [kLightViolet, kBackgroundPink],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = gradient);

    final stripe = Paint()..color = kPinkStripe.withValues(alpha: 0.4);
    const band = 26.0;
    for (double x = 0; x < size.width; x += band * 2) {
      canvas.drawRect(Rect.fromLTWH(x, 0, band, size.height), stripe);
    }
    for (double y = 0; y < size.height; y += band * 2) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, band), stripe);
    }

    final heartPaint = Paint()..color = kHotPink.withValues(alpha: 0.35);
    const spots = [
      Offset(0.06, 0.10),
      Offset(0.94, 0.18),
      Offset(0.10, 0.52),
      Offset(0.92, 0.58),
      Offset(0.18, 0.92),
      Offset(0.84, 0.90),
    ];
    for (final s in spots) {
      canvas.drawPath(
        _heartPath(Offset(s.dx * size.width, s.dy * size.height), 9),
        heartPaint,
      );
    }
  }

  Path _heartPath(Offset c, double s) {
    final p = Path();
    p.moveTo(c.dx, c.dy + s * 0.35);
    p.cubicTo(c.dx - s, c.dy - s * 0.4, c.dx - s * 0.5, c.dy - s, c.dx, c.dy - s * 0.4);
    p.cubicTo(c.dx + s * 0.5, c.dy - s, c.dx + s, c.dy - s * 0.4, c.dx, c.dy + s * 0.35);
    p.close();
    return p;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Pink butterfly
class ButterflyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final wing = Paint()..color = kHotPink.withValues(alpha: 0.85);
    final lowerWing = Paint()..color = kHotPink.withValues(alpha: 0.5);
    final body = Paint()..color = kCocoa;

    canvas.drawOval(Rect.fromLTWH(0, h * 0.05, w * 0.48, h * 0.46), wing);
    canvas.drawOval(Rect.fromLTWH(w * 0.52, h * 0.05, w * 0.48, h * 0.46), wing);
    canvas.drawOval(Rect.fromLTWH(w * 0.1, h * 0.46, w * 0.36, h * 0.38), lowerWing);
    canvas.drawOval(Rect.fromLTWH(w * 0.54, h * 0.46, w * 0.36, h * 0.38), lowerWing);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w / 2, h * 0.5), width: w * 0.06, height: h * 0.72),
        Radius.circular(w),
      ),
      body,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ButterflyWidget extends StatelessWidget {
  final double size;
  const ButterflyWidget({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: ButterflyPainter());
  }
}

// Emoji that gently bounces and tilts forever
class BouncingEmoji extends StatefulWidget {
  final String emoji;
  final double size;
  const BouncingEmoji({super.key, required this.emoji, this.size = 28});

  @override
  State<BouncingEmoji> createState() => _BouncingEmojiState();
}

class _BouncingEmojiState extends State<BouncingEmoji> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -6 * _controller.value),
        child: Transform.rotate(
          angle: 0.12 * (_controller.value - 0.5),
          child: child,
        ),
      ),
      child: Text(widget.emoji, style: TextStyle(fontSize: widget.size)),
    );
  }
}

// ---------- App ----------

class PackTrailApp extends StatelessWidget {
  const PackTrailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PackTrail',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kHotPink,
          primary: kHotPink,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: kBackgroundPink,
        fontFamily: GoogleFonts.inter().fontFamily,
      ),
      home: const HomeScreen(),
    );
  }
}

// ---------- Home: Active Trip and Templates ----------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _onTemplates = false;
  String _selectedCategory = kAllCat;
  bool _hidePacked = false;
  String _quickCategory = 'General';
  bool _quickEssential = false;
  final _quickName = TextEditingController();
  final _search = TextEditingController();

  @override
  void dispose() {
    _quickName.dispose();
    _search.dispose();
    super.dispose();
  }

  void _changed() {
    Store.saveTrip();
    setState(() {});
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: kHotPink,
        content: Text(msg, style: bodyStyle(13, color: Colors.white, weight: FontWeight.w700)),
      ),
    );
  }

  List<String> _categoriesFor(PackTrip trip) {
    final seen = <String>[];
    for (final i in trip.items) {
      if (!seen.contains(i.category)) seen.add(i.category);
    }
    return seen;
  }

  List<String> _addableCategories(PackTrip trip) {
    final cats = <String>['General'];
    for (final i in trip.items) {
      if (i.category != kEssentialsCat && !cats.contains(i.category)) cats.add(i.category);
    }
    return cats;
  }

  int _countFor(PackTrip trip, String cat) => cat == kAllCat
      ? trip.items.length
      : trip.items.where((i) => i.category == cat).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: GinghamPainter())),
          const Positioned(top: 120, right: 6, child: ButterflyWidget(size: 34)),
          const Positioned(bottom: 60, left: 8, child: ButterflyWidget(size: 26)),
          SafeArea(
            child: Column(
              children: [
                _header(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 40),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: _onTemplates ? _templatesView() : _activeView(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Header with logo, name, and the Active Trip / Templates switcher
  Widget _header() {
    return Container(
      decoration: const BoxDecoration(
        gradient: kHeaderGradient,
        boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.luggage, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PackTrail', style: headStyle(20, color: Colors.white)),
                    Text(
                      'BACKPACKER GEAR & LISTS',
                      style: bodyStyle(10, color: Colors.white70, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              _modeSwitch(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeButton('Active Trip', Icons.check_box_outlined, !_onTemplates,
              () => setState(() => _onTemplates = false)),
          _modeButton('Templates', Icons.layers_outlined, _onTemplates,
              () => setState(() => _onTemplates = true)),
        ],
      ),
    );
  }

  Widget _modeButton(String label, IconData icon, bool selected, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? kHotPink : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(label, style: bodyStyle(12, color: Colors.white, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  // ---------- Active Trip view ----------

  Widget _activeView() {
    final trip = Store.trip;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tripCard(trip),
        const SizedBox(height: 14),
        _quickAddBar(trip),
        const SizedBox(height: 14),
        _filters(trip),
        const SizedBox(height: 12),
        _checklist(trip),
      ],
    );
  }

  Widget _badge(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: kLightViolet, borderRadius: BorderRadius.circular(6)),
        child: Text(
          text.toUpperCase(),
          style: bodyStyle(10, color: kViolet, weight: FontWeight.w800),
        ),
      );

  Widget _outlineBtn(String label, IconData icon, VoidCallback onTap, {bool danger = false}) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: bodyStyle(12, weight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        foregroundColor: danger ? kHotPink : kCocoa,
        side: const BorderSide(color: kPinkLine),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _tripCard(PackTrip trip) {
    return softCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _badge('Active Checklist'),
              Text(
                '• From template: ${trip.templateName}',
                style: bodyStyle(12, weight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: Text(trip.name, style: headStyle(22))),
              IconButton(
                tooltip: 'Edit trip name',
                onPressed: _renameTrip,
                icon: const Icon(Icons.edit_outlined, color: kViolet),
              ),
            ],
          ),
          const Divider(color: kPinkLine, height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _outlineBtn('Export', Icons.share_outlined, _showExport),
              _outlineBtn('Save as Template', Icons.bookmark_add_outlined, _saveAsTemplate),
              _outlineBtn('Reset', Icons.restart_alt_rounded, _resetTrip, danger: true),
            ],
          ),
          const SizedBox(height: 14),
          _progressPanel(trip),
        ],
      ),
    );
  }

  Widget _progressPanel(PackTrip trip) {
    final total = trip.items.length;
    final packed = trip.items.where((i) => i.packed).length;
    final pct = total == 0 ? 0 : (packed * 100 / total).round();
    final essRemaining = trip.items.where((i) => i.essential && !i.packed).length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kLightViolet, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 16, color: kViolet),
              const SizedBox(width: 6),
              Text('Packing Progress', style: bodyStyle(13, weight: FontWeight.w700)),
              const Spacer(),
              Text(
                '$packed / $total packed ($pct%)',
                style: bodyStyle(13, weight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : packed / total,
              minHeight: 10,
              backgroundColor: Colors.white,
              color: kHotPink,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  essRemaining == 0
                      ? 'All essentials packed!'
                      : '$essRemaining essential${essRemaining > 1 ? 's' : ''} remaining',
                  style: bodyStyle(11, color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _hidePacked = !_hidePacked),
                child: Text(
                  _hidePacked ? 'Show packed' : 'Hide packed',
                  style: bodyStyle(12, color: kViolet, weight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickAddBar(PackTrip trip) {
    final cats = _addableCategories(trip);
    final selected = cats.contains(_quickCategory) ? _quickCategory : cats.first;

    return softCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _quickName,
              onSubmitted: (_) => _quickAdd(trip),
              style: bodyStyle(14),
              decoration: inputDecoration('Add gear or item (e.g., Headlamp)...', icon: Icons.add),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: selected,
            underline: const SizedBox.shrink(),
            style: bodyStyle(12),
            items: [
              for (final c in cats) DropdownMenuItem<String>(value: c, child: Text(c)),
            ],
            onChanged: (v) => setState(() => _quickCategory = v ?? 'General'),
          ),
          IconButton(
            tooltip: 'Mark as essential',
            onPressed: () => setState(() => _quickEssential = !_quickEssential),
            icon: Icon(
              _quickEssential ? Icons.star_rounded : Icons.star_outline_rounded,
              color: kHotPink,
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kCocoa),
            onPressed: () => _quickAdd(trip),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _quickAdd(PackTrip trip) {
    final name = _quickName.text.trim();
    if (name.isEmpty) return;
    trip.items.add(PackItem(name: name, category: _quickCategory, essential: _quickEssential));
    _quickName.clear();
    _quickEssential = false;
    _changed();
  }

  Widget _catPill(String cat, int count, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selectedCategory = cat),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? kCocoa : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kPinkLine),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                cat,
                style: bodyStyle(12,
                    color: selected ? Colors.white : kCocoa, weight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? kHotPink : kSoftPink,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: bodyStyle(10,
                      color: selected ? Colors.white : kCocoa, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filters(PackTrip trip) {
    final cats = [kAllCat, ..._categoriesFor(trip)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final c in cats) _catPill(c, _countFor(trip, c), _selectedCategory == c),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          style: bodyStyle(13),
          decoration: inputDecoration('Filter items...', icon: Icons.search),
        ),
      ],
    );
  }

  Widget _checklist(PackTrip trip) {
    final q = _search.text.trim().toLowerCase();
    final visible = trip.items.where((i) {
      final matchCat = _selectedCategory == kAllCat || i.category == _selectedCategory;
      final matchSearch = q.isEmpty ||
          i.name.toLowerCase().contains(q) ||
          i.category.toLowerCase().contains(q);
      final matchPacked = !_hidePacked || !i.packed;
      return matchCat && matchSearch && matchPacked;
    }).toList();

    if (visible.isEmpty) {
      return softCard(
        child: Column(
          children: [
            const Icon(Icons.luggage, size: 40, color: kHotPink),
            const SizedBox(height: 8),
            Text('No items found', style: headStyle(16)),
            const SizedBox(height: 4),
            Text(
              'Add an item above, adjust your filter, or load a template.',
              textAlign: TextAlign.center,
              style: bodyStyle(12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final groups = <String, List<PackItem>>{};
    for (final i in visible) {
      groups.putIfAbsent(i.category, () => []).add(i);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
            child: Text(
              entry.key.toUpperCase(),
              style: bodyStyle(11, color: kHotPink, weight: FontWeight.w800),
            ),
          ),
          for (final item in entry.value) _itemRow(trip, item),
        ],
      ],
    );
  }

  Widget _itemRow(PackTrip trip, PackItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kPinkLine),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.only(left: 4, right: 4),
        onTap: () {
          item.packed = !item.packed;
          _changed();
        },
        leading: Checkbox(
          value: item.packed,
          activeColor: kHotPink,
          shape: const CircleBorder(),
          onChanged: (v) {
            item.packed = v ?? false;
            _changed();
          },
        ),
        title: Text(
          item.name,
          style: bodyStyle(
            14,
            color: item.packed ? Colors.grey : kCocoa,
            weight: FontWeight.w600,
          ).copyWith(
            decoration: item.packed ? TextDecoration.lineThrough : TextDecoration.none,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Essential',
              icon: Icon(
                item.essential ? Icons.star_rounded : Icons.star_outline_rounded,
                color: item.essential ? kHotPink : Colors.grey,
              ),
              onPressed: () {
                item.essential = !item.essential;
                _changed();
              },
            ),
            IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.delete_outline, color: kHotPink),
              onPressed: () {
                trip.items.remove(item);
                _changed();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Trip actions ----------

  Future<void> _renameTrip() async {
    final ctrl = TextEditingController(text: Store.trip.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit trip name', style: headStyle(18, color: kHotPink)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: bodyStyle(14),
          decoration: inputDecoration('e.g. Sagada Weekend'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: bodyStyle(13)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kHotPink),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      Store.trip.name = result;
      _changed();
    }
  }

  String _exportText(PackTrip trip) {
    final lines = <String>[
      '🎒 PACKTRAIL LIST: ${trip.name.toUpperCase()}',
      'Packed ${trip.items.where((i) => i.packed).length} / ${trip.items.length}',
      '----------------------------------------',
    ];
    for (final cat in _categoriesFor(trip)) {
      lines.add('\n[ $cat ]');
      for (final i in trip.items.where((i) => i.category == cat)) {
        final check = i.packed ? '[x]' : '[ ]';
        final star = i.essential ? ' ★' : '';
        lines.add('$check ${i.name}$star');
      }
    }
    return lines.join('\n');
  }

  void _showExport() {
    final text = _exportText(Store.trip);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Export packing list', style: headStyle(18, color: kHotPink)),
        content: SizedBox(
          width: 420,
          height: 320,
          child: SingleChildScrollView(
            child: SelectableText(text, style: bodyStyle(13)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: bodyStyle(13)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kHotPink),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(ctx);
              _toast('Copied packing list to clipboard!');
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  void _saveAsTemplate() {
    final trip = Store.trip;
    Store.templates.insert(
      0,
      PackTemplate(
        id: 'tpl-${DateTime.now().millisecondsSinceEpoch}',
        name: trip.name,
        emoji: '🎒',
        description: 'Saved from your active checklist.',
        items: trip.items
            .where((i) => i.category != kEssentialsCat)
            .map((i) => i.copy())
            .toList(),
      ),
    );
    Store.saveTemplates();
    _toast('Saved "${trip.name}" as a reusable template');
  }

  void _resetTrip() {
    for (final i in Store.trip.items) {
      i.packed = false;
    }
    _changed();
    _toast('Checklist reset. Ready for your next trip!');
  }

  // ---------- Templates view ----------

  Widget _templatesView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: kHeaderGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reusable Trip Templates', style: headStyle(20, color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                'Pick a template per trip type to load into your Active Checklist, or build a brand-new master list.',
                style: bodyStyle(12, color: Colors.white.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: kHotPink,
                ),
                onPressed: _createTemplate,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: Text('New Custom Template', style: bodyStyle(13, weight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 560 ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final t in Store.templates) SizedBox(width: width, child: _templateCard(t)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _templateCard(PackTemplate t) {
    return softCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: kSoftPink, shape: BoxShape.circle),
                child: BouncingEmoji(emoji: t.emoji, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(t.name, style: headStyle(15))),
            ],
          ),
          const SizedBox(height: 8),
          Text(t.description, style: bodyStyle(12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            '${t.items.length} items${t.builtIn ? ' • built-in' : ''}',
            style: bodyStyle(11, color: kViolet, weight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: kHotPink),
                  onPressed: () => _useTemplate(t),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Use'),
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined, color: kViolet),
                onPressed: () => _editTemplate(t),
              ),
              if (!t.builtIn)
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline, color: kHotPink),
                  onPressed: () => _deleteTemplate(t),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _useTemplate(PackTemplate t) {
    Store.trip = makeTrip(t);
    Store.saveTrip();
    setState(() {
      _onTemplates = false;
      _selectedCategory = kAllCat;
      _hidePacked = false;
    });
    _toast('Loaded "${t.name}" into your Active Checklist');
  }

  Future<void> _createTemplate() async {
    final t = PackTemplate(
      id: 'tpl-${DateTime.now().millisecondsSinceEpoch}',
      name: 'My Trip',
      emoji: '🧳',
      description: '',
      items: [],
    );
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TemplateEditorPage(template: t, isNew: true)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _editTemplate(PackTemplate t) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TemplateEditorPage(template: t, isNew: false)),
    );
    if (mounted) setState(() {});
  }

  void _deleteTemplate(PackTemplate t) {
    Store.templates.remove(t);
    Store.saveTemplates();
    setState(() {});
    _toast('Template deleted');
  }
}

// ---------- Create or edit a template ----------

class TemplateEditorPage extends StatefulWidget {
  final PackTemplate template;
  final bool isNew;
  const TemplateEditorPage({super.key, required this.template, required this.isNew});

  @override
  State<TemplateEditorPage> createState() => _TemplateEditorPageState();
}

class _TemplateEditorPageState extends State<TemplateEditorPage> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _newItem;
  late final TextEditingController _newCat;
  late List<PackItem> _items;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.template.name);
    _desc = TextEditingController(text: widget.template.description);
    _newItem = TextEditingController();
    _newCat = TextEditingController(text: 'General');
    _items = widget.template.items.map((i) => i.copy()).toList();
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _newItem.dispose();
    _newCat.dispose();
    super.dispose();
  }

  void _addItem() {
    final text = _newItem.text.trim();
    if (text.isEmpty) return;
    final cat = _newCat.text.trim().isEmpty ? 'General' : _newCat.text.trim();
    setState(() => _items.add(PackItem(name: text, category: cat)));
    _newItem.clear();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    widget.template.name = name;
    widget.template.description = _desc.text.trim();
    widget.template.items = _items;
    if (widget.isNew) Store.templates.insert(0, widget.template);
    Store.saveTemplates();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: kHotPink),
        title: Text(
          widget.isNew ? 'New Custom Template' : 'Edit Template',
          style: headStyle(18, color: kHotPink),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: GinghamPainter())),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    softCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          fieldLabel('Template name'),
                          TextField(
                            controller: _name,
                            style: bodyStyle(14),
                            decoration: inputDecoration('e.g. Sagada Trip'),
                          ),
                          const SizedBox(height: 12),
                          fieldLabel('Description'),
                          TextField(
                            controller: _desc,
                            style: bodyStyle(14),
                            decoration: inputDecoration('What is this list for?'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    softCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          fieldLabel('Items'),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _newItem,
                                  onSubmitted: (_) => _addItem(),
                                  style: bodyStyle(13),
                                  decoration: inputDecoration('Item name'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 140,
                                child: TextField(
                                  controller: _newCat,
                                  style: bodyStyle(13),
                                  decoration: inputDecoration('Category'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: kCocoa),
                                onPressed: _addItem,
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_items.isEmpty)
                            Text('No items yet.', style: bodyStyle(12, color: Colors.grey)),
                          for (final e in _items.asMap().entries)
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(e.value.name, style: bodyStyle(13)),
                              subtitle: Text(e.value.category, style: bodyStyle(11, color: Colors.grey)),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, color: kHotPink),
                                onPressed: () => setState(() => _items.removeAt(e.key)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: kHotPink),
                            onPressed: _save,
                            child: const Text('Save template'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}