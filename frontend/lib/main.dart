import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';


void main() => runApp(const PocketMoneyProApp());

const double _kFontScale = 1.8;

TextStyle px(double size, {Color? color, FontWeight? weight}) {
  return TextStyle(
    fontSize: size * _kFontScale,
    color: color,
    fontWeight: weight ?? FontWeight.normal,
  );
}

class KPalette {
  static const bgLight      = Color(0xFFF3ECF1);
  static const headerText   = Color(0xFF6D1E45);
  static const cardDark1    = Color(0xFF3B0A24);
  static const cardDark2    = Color(0xFF5C1638);
  static const tileDarkest  = Color(0xFF4A1030);
  static const tileDarkNavy = Color(0xFF2C1B3D);
  static const tileLavender = Color(0xFFB9A0CB);
  static const tilePaleRose = Color(0xFFF6E7EF);
  static const navBg        = Color(0xFF23101B);
  static const navActiveBg  = Color(0xFFB33B6C);
  static const navInactive  = Color(0xB3FFFFFF);
  static const rose         = Color(0xFFB33B6C);
}

class PocketMoneyProApp extends StatelessWidget {
  const PocketMoneyProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Money Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6D1E45),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF4A1030),
          secondary: const Color(0xFF2C1B3D),
          tertiary: const Color(0xFFB33B6C),
          primaryContainer: const Color(0xFFF6E7EF),
          secondaryContainer: const Color(0xFFF6E7EF),
          tertiaryContainer: const Color(0xFFF6E7EF),
          surface: const Color(0xFFF3ECF1),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.white,
          surfaceContainerHighest: const Color(0xFFF3ECF1),
        ),
        useMaterial3: true,
        
      ),
      home: const WelcomePage(),
    );
  }
}

enum UserRole { parent, child }

class Session {
  final String email;
  final UserRole role;
  const Session({required this.email, required this.role});
}

class ChoreItem {
  final String title;
  final double reward;
  bool completed;
  bool approvedByParent;

  ChoreItem({
    required this.title,
    required this.reward,
    this.completed = false,
    this.approvedByParent = false,
  });
}

class Badge {
  final String emoji;
  final String name;
  final String description;
  bool unlocked;

  Badge({
    required this.emoji,
    required this.name,
    required this.description,
    this.unlocked = false,
  });
}

class MockStore {
  static double parentBalance = 250.00;
  static double childBalance  = 35.50;

  static String parentPin = '1234';

  static int xp    = 120;
  static int level = 2;
  static int streak = 5;

  static int get xpForNextLevel => (level * 100);
  static int get xpProgress     => xp % 100;

  static void addXp(int amount) {
    xp += amount;
    if (xp >= level * 100) {
      level++;
    }
  }

  static final List<Badge> badges = [
    Badge(emoji: '🏆', name: 'First Saver',    description: 'Made your first save!',          unlocked: true),
    Badge(emoji: '🌟', name: 'No Spend Week',  description: 'Did not spend for 7 days',       unlocked: false),
    Badge(emoji: '💎', name: 'Goal Crusher',   description: 'Reached a savings goal!',         unlocked: false),
    Badge(emoji: '🔥', name: 'Hot Streak',     description: 'Saved 5 days in a row!',          unlocked: true),
    Badge(emoji: '🧠', name: 'Smart Spender',  description: 'Used budget tracker 10 times',    unlocked: false),
    Badge(emoji: '🐷', name: 'Piggy Champ',    description: 'Saved over \$50 total',            unlocked: false),
  ];

  static final List<ExpenseItem> childExpenses = [
    ExpenseItem(title: 'Snack',      amount: 3.50, category: 'Food'),
    ExpenseItem(title: 'Game coins', amount: 5.99, category: 'Fun'),
    ExpenseItem(title: 'Notebook',   amount: 2.25, category: 'School'),
  ];

  static final List<WishItem> wishList = [
    WishItem(name: 'LEGO set',   target: 45.00, saved: 20.00),
    WishItem(name: 'Headphones', target: 25.00, saved: 10.00),
  ];

  static final List<ChoreItem> chores = [
    ChoreItem(title: 'Do the dishes',     reward: 2.00),
    ChoreItem(title: 'Clean your room',   reward: 3.00),
    ChoreItem(title: 'Finish homework',   reward: 5.00),
    ChoreItem(title: 'Water the plants',  reward: 1.50),
  ];

  static double piggyBank = 0.00;
  static String piggyGoal = 'Big Toy';

  static final List<TransactionItem> transactions = [
    TransactionItem(title: 'Allowance from Parent', amount: 10.00, isCredit: true,  date: DateTime.now().subtract(const Duration(days: 2))),
    TransactionItem(title: 'Snack',                 amount: 3.50,  isCredit: false, date: DateTime.now().subtract(const Duration(days: 1))),
    TransactionItem(title: 'Game coins',            amount: 5.99,  isCredit: false, date: DateTime.now()),
  ];
}

class ExpenseItem {
  final String title;
  final double amount;
  final String category;
  final DateTime date;

  ExpenseItem({
    required this.title,
    required this.amount,
    required this.category,
    DateTime? date,
  }) : date = date ?? DateTime.now();
}

class WishItem {
  final String name;
  final double target;
  double saved;
  WishItem({required this.name, required this.target, this.saved = 0});

  double get progress => (saved / target).clamp(0.0, 1.0);
  bool get isAchieved => saved >= target;
}

class TransactionItem {
  final String title;
  final double amount;
  final bool isCredit;
  final DateTime date;
  TransactionItem({
    required this.title,
    required this.amount,
    required this.isCredit,
    required this.date,
  });
}


class ApiService {
  // ★ NOTE: Using your computer's current WiFi LAN IP (from `ipconfig`)
  // so a real phone on the same WiFi network can reach your backend.
  // If your computer's IP changes later (new WiFi, restart), re-run
  // `ipconfig` (Windows) / `ifconfig` (Mac/Linux) and update this.
  static const String baseUrl = 'https://pocket-money-backend-production.up.railway.app/apis';
  static const String firebaseWebApiKey = 'google_api_key';

  static Map<String, String> get _headers => {'Content-Type': 'application/json'};

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(Uri.parse('$baseUrl$path'),
        headers: _headers, body: jsonEncode(body));
    final data = (jsonDecode(res.body) as Map).cast<String, dynamic>();
    if (res.statusCode >= 400) {
      throw Exception(data['message'] ?? 'Request failed (${res.statusCode})');
    }
    return data;
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    final data = (jsonDecode(res.body) as Map).cast<String, dynamic>();
    if (res.statusCode >= 400) {
      throw Exception(data['message'] ?? 'Request failed (${res.statusCode})');
    }
    return data;
  }

  static Future<void> _delete(String path) async {
    final res = await http.delete(Uri.parse('$baseUrl$path'), headers: _headers);
    if (res.statusCode >= 400) {
      final data = (jsonDecode(res.body) as Map).cast<String, dynamic>();
      throw Exception(data['message'] ?? 'Request failed (${res.statusCode})');
    }
  }

  
  static Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String role,
    String fullName = '',
  }) {
    return _post('/auth/signup', {
      'email': email, 'password': password, 'role': role, 'fullName': fullName,
    });
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final signInRes = await http.post(
      Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$firebaseWebApiKey'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true
      }),
    );

    final signInData =
        (jsonDecode(signInRes.body) as Map).cast<String, dynamic>();

    if (signInRes.statusCode >= 400) {
      throw Exception(
          (signInData['error'] as Map?)?['message'] ?? 'Sign in failed');
    }

    final String idToken = signInData['idToken'];

    final backendRes = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'token': idToken}),
    );

    final backendData =
        (jsonDecode(backendRes.body) as Map).cast<String, dynamic>();

    if (backendRes.statusCode >= 400) {
      throw Exception(backendData['message'] ?? 'Backend login failed');
    }

    return backendData;
  }

  static Future<Map<String, dynamic>> sendTransfer({
    required String senderId,
    required String receiverId,
    required double amount,
    String? note,
  }) {
    return _post('/transfer/send', {
      'senderId': senderId, 'receiverId': receiverId, 'amount': amount, 'note': note,
    });
  }


  static Future<Map<String, dynamic>> addFunds({required String parentId, required double amount}) {
    return _post('/wallet/add-funds', {'parentId': parentId, 'amount': amount});
  }

  static Future<double> getApproxBalance(String userId) async {
    final data = await _get('/expenses/summary/$userId');
    final received = (data['totalReceived'] ?? 0).toDouble();
    final spent = (data['totalSpent'] ?? 0).toDouble();
    return received - spent;
  }

  static Future<Map<String, dynamic>> createChore({
    required String parentId, required String kidId,
    required String title, required double amount,
  }) {
    return _post('/chores/create', {
      'parentId': parentId, 'kidId': kidId, 'title': title, 'amount': amount,
    });
  }

  static Future<List<dynamic>> getKidChores(String kidId) async {
    final data = await _get('/chores/kid/$kidId');
    return (data['chores'] as List?) ?? [];
  }

  static Future<List<dynamic>> getParentChores(String parentId) async {
    final data = await _get('/chores/parent/$parentId');
    return (data['chores'] as List?) ?? [];
  }

  static Future<void> completeChore(String choreId) => _post('/chores/$choreId/complete', {});

  static Future<void> approveChore(String choreId) => _post('/chores/$choreId/approve', {});

 static Future<void> deleteChore(String choreId) => _delete('/chores/$choreId');


  static Future<void> addWish({
    required String kidId, required String itemName, double price = 0, String notes = '',
  }) {
    return _post('/wishlist/add', {
      'kidId': kidId, 'itemName': itemName, 'price': price, 'notes': notes,
    });
  }

  static Future<List<dynamic>> getWishlist(String kidId) async {
    final data = await _get('/wishlist/$kidId');
    return (data['items'] as List?) ?? [];
  }

  static Future<void> deleteWish(String itemId) => _delete('/wishlist/$itemId');

  // PIGGY BANK
  static Future<void> setPiggyTarget({required String kidId, required double targetAmount}) {
    return _post('/piggybank/set-target', {'kidId': kidId, 'targetAmount': targetAmount});
  }

  static Future<void> piggyDeposit({required String kidId, required double amount}) {
    return _post('/piggybank/deposit', {'kidId': kidId, 'amount': amount});
  }

  static Future<void> piggyWithdraw({required String kidId, required double amount}) {
    return _post('/piggybank/withdraw', {'kidId': kidId, 'amount': amount});
  }

  static Future<Map<String, dynamic>> getPiggyBank(String kidId) => _get('/piggybank/$kidId');

  // QR / VENDOR
  static Future<Map<String, dynamic>> getVendor(String vendorId) => _get('/qr/vendor/$vendorId');

  static Future<Map<String, dynamic>> qrPay({
    required String kidId, required String vendorId, required double amount,
  }) {
    return _post('/qr/pay', {'kidId': kidId, 'vendorId': vendorId, 'amount': amount});
  }

 
  static Future<List<dynamic>> getTransactionHistory(String userId) async {
    final data = await _get('/expenses/history/$userId');
    return (data['transactions'] as List?) ?? [];
  }

  static Future<Map<String, dynamic>> getTransactionSummary(String userId) {
    return _get('/expenses/summary/$userId');
  }

  static Future<Map<String, dynamic>> getWeeklyReport(String kidId) => _get('/reports/weekly/$kidId');


  static Future<Map<String, dynamic>> getBadges(String kidId) => _get('/badges/$kidId');


  static Future<void> saveFcmToken({required String uid, required String fcmToken}) {
    return _post('/notifications/save-token', {'uid': uid, 'fcmToken': fcmToken});
  }
}

class AppData {
  static String? currentUid;
  static String? currentEmail;
  static UserRole? currentRole;
  static String? linkedKidId;
  static String? fullName; 
  static File? profileImage; // ★ NEW: locally-picked profile picture
}



enum NotificationType { success, error, info }

void showCuteNotification(
  BuildContext context,
  String message, {
  NotificationType type = NotificationType.info,
  String? emoji,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _CuteTopBanner(
      message: message,
      type: type,
      emoji: emoji,
      onDismissed: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _CuteTopBanner extends StatefulWidget {
  final String message;
  final NotificationType type;
  final String? emoji;
  final VoidCallback onDismissed;

  const _CuteTopBanner({
    required this.message,
    required this.type,
    required this.onDismissed,
    this.emoji,
  });

  @override
  State<_CuteTopBanner> createState() => _CuteTopBannerState();
}

class _CuteTopBannerState extends State<_CuteTopBanner>
    with TickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late AnimationController _wiggleCtrl;
  late Animation<Offset> _slide;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _slide = Tween<Offset>(begin: const Offset(0, -1.6), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.elasticOut));
    _wiggleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _slideCtrl.forward();
    Future.delayed(const Duration(milliseconds: 2600), _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    await _slideCtrl.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _wiggleCtrl.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (widget.type) {
      case NotificationType.success: return const Color(0xFF43C59E);
      case NotificationType.error:   return const Color(0xFF8C2B4F);
      case NotificationType.info:    return const Color(0xFFFFD76A);
    }
  }

  String get _emoji {
    if (widget.emoji != null) return widget.emoji!;
    switch (widget.type) {
      case NotificationType.success: return '🎉';
      case NotificationType.error:   return '😬';
      case NotificationType.info:    return '✨';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        bottom: false,
        child: SlideTransition(
          position: _slide,
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: _dismiss,
                onVerticalDragEnd: (details) {
                  if ((details.primaryVelocity ?? 0) < 0) _dismiss();
                },
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  constraints: const BoxConstraints(maxWidth: 420),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B0A24), Color(0xFF4A1030)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B0A24).withValues(alpha: 0.5),
                        blurRadius: 18, offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      RotationTransition(
                        turns: Tween(begin: -0.045, end: 0.045).animate(_wiggleCtrl),
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.22),
                            shape: BoxShape.circle,
                            border: Border.all(color: _accentColor, width: 1.6),
                          ),
                          child: Center(
                            child: Text(_emoji, style: const TextStyle(fontSize: 16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: px(6, color: Colors.white, weight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.close_rounded,
                          color: Colors.white.withValues(alpha: 0.7), size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BouncyButton extends StatefulWidget {
  final Widget child;
  const _BouncyButton({required this.child});

  @override
  State<_BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<_BouncyButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _scale = 0.96),
      onPointerUp: (_) => setState(() => _scale = 1.0),
      onPointerCancel: (_) => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}


class _AnimatedWallet3D extends StatefulWidget {
  const _AnimatedWallet3D();

  @override
  State<_AnimatedWallet3D> createState() => _AnimatedWallet3DState();
}

class _AnimatedWallet3DState extends State<_AnimatedWallet3D>
    with TickerProviderStateMixin {
  late AnimationController _floatCtrl;
  late AnimationController _rotateCtrl;
  late AnimationController _coinCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _rotateCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4500))
      ..repeat();
    _coinCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _rotateCtrl.dispose();
    _coinCtrl.dispose();
    super.dispose();
  }

  Widget _iconBubble(IconData icon, double size, {required bool dark}) {
    return Container(
      width: size + 26, height: size + 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dark ? KPalette.tileDarkest : Colors.white,
        border: Border.all(
            color: dark ? Colors.white.withValues(alpha: 0.25) : KPalette.headerText.withValues(alpha: 0.12),
            width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Icon(icon, size: size, color: dark ? Colors.white : KPalette.headerText),
    );
  }

  Widget _walletBody() {
    return Container(
      width: 150, height: 110,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B0A24), Color(0xFF4A1030), Color(0xFF7A2050)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B0A24).withValues(alpha: 0.45),
            blurRadius: 24, offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -16, left: 18,
            child: Transform.rotate(
              angle: -0.09,
              child: Container(
                width: 92, height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8C2B4F), Color(0xFFB33B6C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 18, height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 2),
              ),
              child: const Center(child: Icon(Icons.account_balance_rounded, color: Colors.white, size: 22)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatCtrl, _rotateCtrl, _coinCtrl]),
      builder: (context, _) {
        final floatY  = math.sin(_floatCtrl.value * math.pi) * 10;
        final tilt    = math.sin(_rotateCtrl.value * 2 * math.pi) * 0.14;
        final coinY1  = math.sin(_coinCtrl.value * 2 * math.pi) * 14;
        final coinY2  = math.cos(_coinCtrl.value * 2 * math.pi) * 14;
        return SizedBox(
          width: 220, height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 170, height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    const Color(0xFF4A1030).withValues(alpha: 0.25),
                    Colors.transparent,
                  ]),
                ),
              ),
              Transform.translate(
                offset: Offset(-76, -58 + coinY1 * 0.5),
                child: _iconBubble(Icons.account_balance_rounded, 20, dark: true),
              ),
              Transform.translate(
                offset: Offset(72, -60 + coinY2 * 0.5),
                child: _iconBubble(Icons.show_chart_rounded, 18, dark: false),
              ),
              Transform.translate(
                offset: Offset(72, 54 + coinY1 * 0.4),
                child: _iconBubble(Icons.shield_outlined, 18, dark: false),
              ),
              Transform.translate(
                offset: Offset(0, floatY),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(tilt),
                  child: _walletBody(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF3ECF1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('Pocket\nMoney Pro',
                  style: px(16, color: const Color(0xFF4A1030), weight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                'A kid-friendly money app.\nParents send, kids track & spend.',
                style: px(7, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEAD6E3), Color(0xFFE3D3DE), Color(0xFFF6E7EF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A1030).withValues(alpha: 0.28),
                        blurRadius: 28,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Expanded(
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: _AnimatedWallet3D(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _BouncyButton(
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: cs.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => const AuthPage(mode: AuthMode.signIn))),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Sign in', style: px(8, color: Colors.white)),
                                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _BouncyButton(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: cs.primary,
                                    side: BorderSide(color: cs.primary, width: 2),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => const AuthPage(mode: AuthMode.signUp))),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Sign up', style: px(8, color: cs.primary)),
                                      Icon(Icons.person_add_alt_1_rounded, color: cs.primary, size: 18),
                                    ],
                                  ),
                                ),
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
        ),
      ),
    );
  }
}

/* ══════════════════════════════════════════════════════════════
   AUTH PAGE  (★ NEW: a separate Username field — Email, Username,
   Password — instead of deriving the username from the email)
══════════════════════════════════════════════════════════════ */

enum AuthMode { signIn, signUp }

class AuthPage extends StatefulWidget {
  final AuthMode mode;
  const AuthPage({super.key, required this.mode});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey  = GlobalKey<FormState>();
  final _email    = TextEditingController(text: 'kid@example.com');
  final _username = TextEditingController(text: 'kid_user'); // ★ NEW
  final _password = TextEditingController(text: 'password123');
  UserRole _role  = UserRole.child;
  bool _obscure   = true;
  bool _loading   = false;

  @override
  void dispose() {
    _email.dispose();
    _username.dispose(); // ★ NEW
    _password.dispose();
    super.dispose();
  }

  String get _title    => widget.mode == AuthMode.signIn ? 'Sign in' : 'Sign up';
  String get _subtitle => widget.mode == AuthMode.signIn ? 'Welcome back!' : 'Create account';

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (widget.mode == AuthMode.signUp) {
        // ★ NEW: username now comes straight from its own field
        final username = _username.text.trim();

        final res = await ApiService.signup(
          email: _email.text.trim(),
          password: _password.text.trim(),
          role: _role == UserRole.parent ? 'parent' : 'child',
          fullName: username,
        );
        final uid = res['uid'] as String;
        AppData.currentUid   = uid;
        AppData.currentEmail = _email.text.trim();
        AppData.currentRole  = _role;
        AppData.fullName     = username;

        final session = Session(email: _email.text.trim(), role: _role);
        if (!mounted) return;
        if (_role == UserRole.parent) {
          Navigator.pushAndRemoveUntil(context,
              MaterialPageRoute(builder: (_) => ParentPinSetupPage(session: session)),
              (r) => false);
        } else {
          Navigator.pushAndRemoveUntil(context,
              MaterialPageRoute(builder: (_) => KidHome(session: session)),
              (r) => false);
        }
      } else {
        // SIGN IN
        final res = await ApiService.login(
          email: _email.text.trim(),
          password: _password.text.trim(),
        );
        final uid     = res['uid'] as String;
        final roleStr = (res['role'] as String?) ?? 'child';
        final role    = roleStr == 'parent' ? UserRole.parent : UserRole.child;

        // ★ NEW: username comes straight from its own field
        final username = _username.text.trim();

        AppData.currentUid   = uid;
        AppData.currentEmail = _email.text.trim();
        AppData.currentRole  = role;
        AppData.fullName     = username;

        final session = Session(email: _email.text.trim(), role: role);
        if (!mounted) return;

        // Parent signin -> verify PIN
        if (role == UserRole.parent) {
          final enteredPin = await showDialog<String>(
            context: context,
            barrierDismissible: false,
            builder: (_) => const _PinDialog(title: 'Enter your PIN'),
          );
          if (!mounted) return;
          if (enteredPin == null || enteredPin != MockStore.parentPin) {
            showCuteNotification(context, 'Wrong PIN! Access denied ❌',
                type: NotificationType.error);
            setState(() => _loading = false);
            return;
          }
          Navigator.pushAndRemoveUntil(context,
              MaterialPageRoute(builder: (_) => ParentHome(session: session)),
              (r) => false);
        } else {
          Navigator.pushAndRemoveUntil(context,
              MaterialPageRoute(builder: (_) => KidHome(session: session)),
              (r) => false);
        }
      }
    } catch (e) {
      if (!mounted) return;
      showCuteNotification(context, e.toString().replaceFirst('Exception: ', ''),
          type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF3ECF1),
      appBar: AppBar(
        title: Text(_title, style: px(9)),
        backgroundColor: const Color(0xFFF3ECF1),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 4),
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
                      child: child,
                    ),
                    child: Container(
                      key: ValueKey(_role),
                      width: 66, height: 66,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B0A24), Color(0xFF4A1030)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4A1030).withValues(alpha: 0.4),
                            blurRadius: 16, offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _role == UserRole.parent ? '👨‍👩‍👧' : '🧒',
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(_subtitle,
                    style: px(11, color: cs.primary, weight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(
                  _role == UserRole.parent
                      ? 'Manage allowance like a pro 💜'
                      : 'Let\'s get your money sorted! ✨',
                  style: px(6, color: Colors.black45),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.15),
                        blurRadius: 16, offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        style: px(8),
                        decoration: InputDecoration(
                          labelText: '📧 Email',
                          labelStyle: px(7),
                          prefixIcon: Icon(Icons.email_outlined, color: cs.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: cs.primary, width: 2),
                          ),
                        ),
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return 'Enter an email';
                          if (!s.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // ★ NEW: Username field (sits between Email and Password)
                      TextFormField(
                        controller: _username,
                        style: px(8),
                        decoration: InputDecoration(
                          labelText: '🧑 Username',
                          labelStyle: px(7),
                          prefixIcon: Icon(Icons.badge_outlined, color: cs.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: cs.primary, width: 2),
                          ),
                        ),
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return 'Enter a username';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        style: px(8),
                        decoration: InputDecoration(
                          labelText: '🔒 Password',
                          labelStyle: px(7),
                          prefixIcon: Icon(Icons.lock_outline, color: cs.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: cs.primary, width: 2),
                          ),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure ? Icons.visibility : Icons.visibility_off,
                              color: cs.primary,
                            ),
                          ),
                        ),
                        validator: (v) {
                          final s = (v ?? '');
                          if (s.isEmpty) return 'Enter a password';
                          if (s.length < 6) return 'Min 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Who\'s signing in?', style: px(8, weight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<UserRole>(
                        segments: [
                          ButtonSegment(
                            value: UserRole.parent,
                            label: Text('Parent', style: px(7)),
                            icon: const Icon(Icons.supervised_user_circle_outlined),
                          ),
                          ButtonSegment(
                            value: UserRole.child,
                            label: Text('Kid', style: px(7)),
                            icon: const Icon(Icons.sentiment_satisfied_alt_outlined),
                          ),
                        ],
                        selected: {_role},
                        onSelectionChanged: (set) => setState(() => _role = set.first),
                      ),
                      if (widget.mode == AuthMode.signIn) ...[
                        const SizedBox(height: 6),
                        Text(
                          "(For sign in, your real role comes back from the backend — this toggle is only used for sign up.)",
                          style: px(5, color: Colors.black38),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _loading ? null : _continue,
                  child: _loading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          widget.mode == AuthMode.signIn ? 'Continue' : 'Create account',
                          style: px(8, color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ══════════════════════════════════════════════════════════════
   PARENT HOME  — bottom-nav shell: Home / Chores / Reports / Profile
   (same KPalette colors + same nav bar style as Kid Portal)
══════════════════════════════════════════════════════════════ */

class ParentHome extends StatefulWidget {
  final Session session;
  const ParentHome({super.key, required this.session});

  @override
  State<ParentHome> createState() => _ParentHomeState();
}

class _ParentHomeState extends State<ParentHome> {
  int _tab = 0;

  static const _titles = ['Parent Portal', 'Chores', 'Reports', 'Profile'];

  @override
  Widget build(BuildContext context) {
    final pages = [
      _ParentDashboardTab(session: widget.session),
      const _ParentChoresTab(),
      const _ParentReportsTab(),
      const ParentProfileTab(),
    ];

    return Scaffold(
      backgroundColor: KPalette.bgLight,
      appBar: AppBar(
        title: Text(_titles[_tab],
            style: px(9, color: KPalette.headerText, weight: FontWeight.bold)),
        backgroundColor: KPalette.bgLight,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const WelcomePage()),
                (r) => false),
            icon: const Icon(Icons.logout, color: KPalette.headerText),
          ),
        ],
      ),
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: _KPortalNavBar(
        index: _tab,
        onChanged: (i) => setState(() => _tab = i),
        items: const [
          _NavItem(icon: Icons.home_rounded, label: 'Home'),
          _NavItem(icon: Icons.checklist_rounded, label: 'Chores'),
          _NavItem(icon: Icons.bar_chart_rounded, label: 'Reports'),
          _NavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
        ],
      ),
    );
  }
}

/* ── Home tab: balances, link kid, quick actions ─────────────── */
class _ParentDashboardTab extends StatefulWidget {
  final Session session;
  const _ParentDashboardTab({required this.session});

  @override
  State<_ParentDashboardTab> createState() => _ParentDashboardTabState();
}

class _ParentDashboardTabState extends State<_ParentDashboardTab> {
  double? _parentBalance;
  double? _kidBalance;
  bool _loading = true;
  late final TextEditingController _kidIdCtrl =
      TextEditingController(text: AppData.linkedKidId ?? '');

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  @override
  void dispose() {
    _kidIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBalances() async {
    setState(() => _loading = true);
    try {
      final parentBal = await ApiService.getApproxBalance(AppData.currentUid!);
      double? kidBal;
      if (AppData.linkedKidId != null && AppData.linkedKidId!.isNotEmpty) {
        kidBal = await ApiService.getApproxBalance(AppData.linkedKidId!);
      }
      if (!mounted) return;
      setState(() {
        _parentBalance = parentBal;
        _kidBalance = kidBal;
      });
    } catch (e) {
      if (!mounted) return;
      showCuteNotification(context, 'Could not load balances: $e', type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _saveLinkedKid() {
    final id = _kidIdCtrl.text.trim();
    if (id.isEmpty) return;
    setState(() => AppData.linkedKidId = id);
    showCuteNotification(context, 'Kid linked! 🎉', type: NotificationType.success);
    _loadBalances();
  }

  Future<void> _showAddFundsDialog() async {
    final ctrl = TextEditingController(text: '10');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: KPalette.bgLight,
        title: Text('Add Funds', style: px(9)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter amount to add to your account:',
                style: px(6, color: Colors.black54)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: px(8),
              decoration: InputDecoration(
                prefixText: '\$ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: px(7, color: Colors.black45)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF43C59E)),
            onPressed: () async {
              final amount = double.tryParse(ctrl.text.trim());
              if (amount == null || amount <= 0) return;
              Navigator.pop(context);
              try {
                await ApiService.addFunds(
                  parentId: AppData.currentUid!,
                  amount: amount,
                );
                if (!mounted) return;
                showCuteNotification(context,
                    '\$${amount.toStringAsFixed(2)} added! 💰',
                    type: NotificationType.success);
                _loadBalances();
              } catch (e) {
                if (!mounted) return;
                showCuteNotification(context, 'Failed: $e',
                    type: NotificationType.error);
              }
            },
            child: Text('Add', style: px(7, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
      onRefresh: _loadBalances,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Hello! 👋', style: px(9, color: KPalette.headerText, weight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(AppData.fullName ?? session.email,
                style: px(7, color: Colors.black54),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('Your User ID: ${AppData.currentUid ?? '—'}',
                style: px(5, color: Colors.black38),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [KPalette.cardDark1, KPalette.cardDark2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: KPalette.cardDark1.withValues(alpha: 0.35),
                      blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Balance', style: px(7, color: Colors.white70)),
                        const SizedBox(height: 6),
                        Text('\$${(_parentBalance ?? 0).toStringAsFixed(2)}',
                            style: px(13, color: Colors.white, weight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: KPalette.headerText.withValues(alpha: 0.1),
                      blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: KPalette.rose.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.child_care_outlined,
                        color: KPalette.rose, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kid Balance', style: px(7, color: Colors.black54)),
                        const SizedBox(height: 6),
                        Text('\$${(_kidBalance ?? 0).toStringAsFixed(2)}',
                            style: px(13, color: KPalette.headerText, weight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: KPalette.headerText.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _kidIdCtrl,
                      style: px(7),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: "Kid's User ID",
                        labelStyle: px(6),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _saveLinkedKid,
                    child: Text('Link', style: px(7, color: KPalette.headerText, weight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Quick Actions', style: px(9, weight: FontWeight.bold, color: KPalette.headerText)),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.add_card,
              title: 'Add Funds',
              subtitle: 'Add money to your account',
              accent: KPalette.tileDarkest,
              onTap: () async {
                await _showAddFundsDialog();
              },
            ),
            _ActionTile(
              icon: Icons.sync_alt,
              title: 'Transfer Money',
              subtitle: 'Send allowance to kid',
              accent: KPalette.rose,
              onTap: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TransferMoneyPage()));
                _loadBalances();
              },
            ),
            _ActionTile(
              icon: Icons.receipt_long_outlined,
              title: 'Expense Tracker',
              subtitle: "See kid's recent spending",
              accent: KPalette.tileDarkNavy,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const KidsExpenseTrackerPage())),
            ),
            _ActionTile(
              icon: Icons.settings_outlined,
              title: 'Account Settings',
              subtitle: 'Profile, limits, notifications',
              accent: KPalette.tileLavender,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AccountSettingsPage())),
            ),
          ],
        ),
      ),
    );
  }
}

/* ── Chores tab: chore manager (embedded, no extra app bar) ──── */
class _ParentChoresTab extends StatefulWidget {
  const _ParentChoresTab();

  @override
  State<_ParentChoresTab> createState() => _ParentChoresTabState();
}

class _ParentChoresTabState extends State<_ParentChoresTab> {
  final _titleCtrl  = TextEditingController();
  final _rewardCtrl = TextEditingController();
  late final TextEditingController _kidIdCtrl =
      TextEditingController(text: AppData.linkedKidId ?? '');

  List<dynamic> _chores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChores();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _rewardCtrl.dispose();
    _kidIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadChores() async {
    setState(() => _loading = true);
    try {
      final chores = await ApiService.getParentChores(AppData.currentUid!);
      if (!mounted) return;
      setState(() => _chores = chores);
    } catch (e) {
      if (!mounted) return;
      showCuteNotification(context, 'Could not load chores: $e', type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addChore() async {
    final title  = _titleCtrl.text.trim();
    final reward = double.tryParse(_rewardCtrl.text.trim());
    final kidId  = _kidIdCtrl.text.trim();
    if (title.isEmpty || reward == null || reward <= 0 || kidId.isEmpty) {
      showCuteNotification(context, 'Fill chore name, reward and Kid ID',
          type: NotificationType.error);
      return;
    }
    try {
      await ApiService.createChore(
        parentId: AppData.currentUid!, kidId: kidId, title: title, amount: reward,
      );
      AppData.linkedKidId = kidId;
      _titleCtrl.clear();
      _rewardCtrl.clear();
      showCuteNotification(context, 'Chore created! 🧹', type: NotificationType.success);
      _loadChores();
    } catch (e) {
      showCuteNotification(context, 'Failed: $e', type: NotificationType.error);
    }
  }

  Future<void> _approveChore(String choreId, double amount) async {
    try {
      await ApiService.approveChore(choreId);
      showCuteNotification(context, 'Approved! \$${amount.toStringAsFixed(2)} sent to kid 🎉',
          type: NotificationType.success);
      _loadChores();
    } catch (e) {
      showCuteNotification(context, 'Failed: $e', type: NotificationType.error);
    }
  }

  Future<void> _confirmDeleteChore(String choreId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: KPalette.bgLight,
        title: Text('Delete chore?', style: px(9)),
        content: Text('Are you sure you want to delete "$title"?', style: px(7)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: px(7, color: Colors.black45)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: px(7, color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.deleteChore(choreId);
      if (!mounted) return;
      showCuteNotification(context, 'Chore deleted 🗑️', type: NotificationType.success);
      _loadChores();
    } catch (e) {
      if (!mounted) return;
      showCuteNotification(context, 'Failed: $e', type: NotificationType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadChores,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: KPalette.headerText.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: KPalette.headerText.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add New Chore', style: px(8, weight: FontWeight.bold, color: KPalette.headerText)),
                const SizedBox(height: 10),
                TextField(
                  controller: _kidIdCtrl,
                  style: px(7),
                  decoration: InputDecoration(
                    labelText: "Kid's User ID", labelStyle: px(6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: KPalette.headerText, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleCtrl,
                  style: px(7),
                  decoration: InputDecoration(
                    labelText: 'Chore name', labelStyle: px(6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: KPalette.headerText, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _rewardCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: px(7),
                  decoration: InputDecoration(
                    labelText: 'Reward (\$)', labelStyle: px(6),
                    prefixText: '\$ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: KPalette.headerText, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: KPalette.headerText,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _addChore,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text('Add Chore', style: px(7, color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('All Chores', style: px(8, weight: FontWeight.bold, color: KPalette.headerText)),
          const SizedBox(height: 10),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_chores.isEmpty)
            Text('No chores yet.', style: px(7, color: Colors.black45))
          else
            for (final c in _chores)
              _ChoreCard(
                title: c['title'] ?? '',
                reward: (c['amount'] ?? 0).toDouble(),
                status: c['status'] ?? 'pending',
                onApprove: c['status'] == 'done'
                    ? () => _approveChore(c['choreId'], (c['amount'] ?? 0).toDouble())
                    : null,
                onDelete: () => _confirmDeleteChore(c['choreId'], c['title'] ?? 'this chore'),
              ),
        ],
      ),
    );
  }
}

/* ── Reports tab: weekly report (embedded, no extra app bar) ─── */
class _ParentReportsTab extends StatefulWidget {
  const _ParentReportsTab();

  @override
  State<_ParentReportsTab> createState() => _ParentReportsTabState();
}

class _ParentReportsTabState extends State<_ParentReportsTab> {
  Map<String, dynamic>? _report;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final kidId = AppData.linkedKidId;
    if (kidId == null || kidId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final data = await ApiService.getWeeklyReport(kidId);
      if (!mounted) return;
      setState(() => _report = data);
    } catch (e) {
      if (!mounted) return;
      showCuteNotification(context, 'Could not load report: $e', type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      KPalette.headerText,
      KPalette.tileDarkNavy,
      KPalette.rose,
      const Color(0xFF43C59E),
      const Color(0xFFFF8C42),
    ];

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (AppData.linkedKidId == null || AppData.linkedKidId!.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            Center(child: Text(
                "Link a kid's User ID from the Home tab first.",
                style: px(7, color: Colors.black45), textAlign: TextAlign.center)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [KPalette.cardDark1, KPalette.cardDark2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This Week', style: px(7, color: Colors.white70)),
                const SizedBox(height: 6),
                Text('\$${(_report?['totalSpent'] ?? 0).toStringAsFixed(2)} spent',
                    style: px(14, color: Colors.white, weight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('\$${(_report?['totalReceived'] ?? 0).toStringAsFixed(2)} received',
                    style: px(8, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Spending By Type', style: px(8, weight: FontWeight.bold, color: KPalette.headerText)),
          const SizedBox(height: 10),
          ...(() {
            final breakdown = (_report?['spentBreakdown'] as Map?) ?? {};
            final total = (_report?['totalSpent'] ?? 0).toDouble();
            final entries = breakdown.entries.toList();
            if (entries.isEmpty) {
              return [Text('No spending recorded this week.',
                  style: px(7, color: Colors.black45))];
            }
            return entries.asMap().entries.map((entry) {
              final idx  = entry.key;
              final type = entry.value.key.toString();
              final amt  = (entry.value.value as num).toDouble();
              final pct  = total > 0 ? amt / total : 0.0;
              final color = colors[idx % colors.length];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(type, style: px(7, color: Colors.black87)),
                        Text('\$${amt.toStringAsFixed(2)}',
                            style: px(7, color: color, weight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 12,
                        backgroundColor: color.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          })(),
        ],
      ),
    );
  }
}

/* ── Profile tab: parent's profile — email, avatar picker, etc. ── */
class ParentProfileTab extends StatefulWidget {
  const ParentProfileTab({super.key});

  @override
  State<ParentProfileTab> createState() => _ParentProfileTabState();
}

class _ParentProfileTabState extends State<ParentProfileTab> {
  double _balance = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final balance = await ApiService.getApproxBalance(AppData.currentUid!);
      if (!mounted) return;
      setState(() => _balance = balance);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (file == null) return;
      setState(() => AppData.profileImage = File(file.path));
    } catch (e) {
      if (!mounted) return;
      showCuteNotification(context, 'Could not open gallery: $e', type: NotificationType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: KPalette.cardDark1,
                backgroundImage: AppData.profileImage != null
                    ? FileImage(AppData.profileImage!)
                    : null,
                child: AppData.profileImage == null
                    ? const Text('👨‍👩‍👧', style: TextStyle(fontSize: 34))
                    : null,
              ),
              Positioned(
                right: 0, bottom: 0,
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: KPalette.rose,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(AppData.fullName ?? 'Parent',
              style: px(10, color: KPalette.headerText, weight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(AppData.currentEmail ?? '—',
              style: px(6, color: Colors.black45)),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: KPalette.headerText.withValues(alpha: 0.1),
                  blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            children: [
              _profileRow(Icons.badge_outlined, 'Role', 'Parent'),
              const Divider(height: 20),
              _profileRow(Icons.email_outlined, 'Email', AppData.currentEmail ?? '—'),
              const Divider(height: 20),
              _profileRow(Icons.fingerprint, 'User ID', AppData.currentUid ?? '—'),
              const Divider(height: 20),
              _profileRow(Icons.child_care_outlined, "Linked Kid",
                  AppData.linkedKidId ?? 'Not linked'),
              const Divider(height: 20),
              _profileRow(Icons.account_balance_wallet_outlined, 'Balance',
                  _loading ? '…' : '\$${_balance.toStringAsFixed(2)}'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: KPalette.headerText.withValues(alpha: 0.1),
                  blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: ListTile(
            leading: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: KPalette.headerText.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.pin_outlined, color: KPalette.headerText, size: 20),
            ),
            title: Text('Account Settings', style: px(7, weight: FontWeight.bold)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('PIN, limits, notifications', style: px(6, color: Colors.black45)),
            ),
            trailing: const Icon(Icons.chevron_right, color: KPalette.headerText),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AccountSettingsPage())),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: KPalette.headerText,
            side: BorderSide(color: KPalette.headerText.withValues(alpha: 0.4), width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.pushAndRemoveUntil(context,
              MaterialPageRoute(builder: (_) => const WelcomePage()), (r) => false),
          icon: const Icon(Icons.logout),
          label: Text('Sign out', style: px(7)),
        ),
      ],
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: KPalette.headerText, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: px(6, color: Colors.black54))),
        Flexible(
          child: Text(value,
              style: px(7, weight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

/* ══════════════════════════════════════════════════════════════
   SHARED WIDGETS
══════════════════════════════════════════════════════════════ */

class _BalanceCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color accent;
  final IconData icon;

  const _BalanceCard({
    required this.title,
    required this.amount,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.10), accent.withValues(alpha: 0.24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.16), blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: px(7, color: Colors.black54)),
                const SizedBox(height: 6),
                Text('\$${amount.toStringAsFixed(2)}',
                    style: px(13, color: accent, weight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _BouncyButton(
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, accent.withValues(alpha: 0.06)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: ListTile(
          onTap: onTap,
          leading: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent.withValues(alpha: 0.22), accent.withValues(alpha: 0.12)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          title: Text(title, style: px(8, weight: FontWeight.bold)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(subtitle, style: px(6, color: Colors.black45)),
          ),
          trailing: Icon(Icons.chevron_right, color: accent),
        ),
      ),
    );
  }
}

/* ══════════════════════════════════════════════════════════════
   ACCOUNT SETTINGS
══════════════════════════════════════════════════════════════ */

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  bool notifications = true;
  double dailyLimit  = 10;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF3ECF1),
      appBar: AppBar(
        title: Text('Settings', style: px(9)),
        backgroundColor: const Color(0xFFF3ECF1),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              SwitchListTile(
                value: notifications,
                onChanged: (v) => setState(() => notifications = v),
                activeThumbColor: cs.primary,
                title: Text('Notifications', style: px(8)),
                subtitle: Text('Alerts for transfers & spending',
                    style: px(6, color: Colors.black45)),
              ),
              const SizedBox(height: 12),
              Text('Daily spend limit', style: px(8, weight: FontWeight.bold)),
              const SizedBox(height: 8),
              Slider(
                value: dailyLimit,
                min: 0, max: 50, divisions: 10,
                activeColor: cs.primary,
                label: '\$${dailyLimit.toStringAsFixed(0)}',
                onChanged: (v) => setState(() => dailyLimit = v),
              ),
              Text('Limit: \$${dailyLimit.toStringAsFixed(0)}',
                  style: px(8, color: cs.primary)),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Text('Security', style: px(8, weight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
                ),
                child: ListTile(
                  leading: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.pin_outlined, color: cs.primary, size: 20),
                  ),
                  title: Text('Change PIN', style: px(8, weight: FontWeight.bold)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Current PIN: ${MockStore.parentPin}',
                        style: px(6, color: Colors.black45)),
                  ),
                  trailing: Icon(Icons.chevron_right, color: cs.primary),
                  onTap: () async {
                    final old = await showDialog<String>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const _PinDialog(title: 'Enter current PIN'),
                    );
                    if (old == null || old != MockStore.parentPin) {
                      if (!mounted) return;
                      showCuteNotification(context, 'Wrong PIN!', type: NotificationType.error);
                      return;
                    }
                    if (!mounted) return;
                    await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => _ChangePinPage(),
                    ));
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ══════════════════════════════════════════════════════════════
   CHANGE PIN PAGE
══════════════════════════════════════════════════════════════ */

class _ChangePinPage extends StatefulWidget {
  @override
  State<_ChangePinPage> createState() => _ChangePinPageState();
}

class _ChangePinPageState extends State<_ChangePinPage> {
  String _pin     = '';
  String _confirm = '';
  bool _step2     = false;
  String _error   = '';

  void _onKey(String digit) {
    setState(() {
      _error = '';
      if (!_step2) {
        if (_pin.length >= 4) return;
        _pin += digit;
        if (_pin.length == 4) {
          Future.delayed(const Duration(milliseconds: 180),
              () { if (mounted) setState(() => _step2 = true); });
        }
      } else {
        if (_confirm.length >= 4) return;
        _confirm += digit;
        if (_confirm.length == 4) {
          Future.delayed(const Duration(milliseconds: 180), () {
            if (!mounted) return;
            if (_confirm == _pin) {
              MockStore.parentPin = _pin;
              showCuteNotification(context, 'PIN changed! ✅', type: NotificationType.success);
              Navigator.pop(context);
            } else {
              setState(() {
                _error = 'PINs do not match. Try again!';
                _pin = ''; _confirm = ''; _step2 = false;
              });
            }
          });
        }
      }
    });
  }

  void _onDelete() {
    setState(() {
      _error = '';
      if (!_step2) {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_confirm.isNotEmpty) _confirm = _confirm.substring(0, _confirm.length - 1);
      }
    });
  }

  Widget _numBtn(String label, {VoidCallback? onTap, Color? bg}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: bg ?? const Color(0xFFF6E7EF),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap ?? () => _onKey(label),
            child: SizedBox(
              height: 56,
              child: Center(
                child: label == '⌫'
                    ? const Icon(Icons.backspace_outlined, color: Color(0xFF5C1638), size: 22)
                    : Text(label, style: px(13, color: const Color(0xFF5C1638), weight: FontWeight.bold)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cur = _step2 ? _confirm : _pin;
    return Scaffold(
      backgroundColor: const Color(0xFFF3ECF1),
      appBar: AppBar(
        title: Text('Change PIN', style: px(9)),
        backgroundColor: const Color(0xFFF3ECF1),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A1030), Color(0xFF3B0A24)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(
                      color: const Color(0xFF4A1030).withValues(alpha: 0.4),
                      blurRadius: 14, offset: const Offset(0, 5),
                    )],
                  ),
                  child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 16),
                Text(_step2 ? 'Confirm new PIN' : 'Enter new PIN',
                    style: px(9, color: const Color(0xFF3B0A24), weight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final filled = i < cur.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled
                            ? const Color(0xFF4A1030)
                            : const Color(0xFF4A1030).withValues(alpha: 0.18),
                        border: Border.all(color: const Color(0xFF4A1030), width: 2),
                      ),
                    );
                  }),
                ),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6E7EF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_error,
                        style: px(6, color: const Color(0xFFB33B6C)),
                        textAlign: TextAlign.center),
                  ),
                ],
                const SizedBox(height: 24),
                for (final row in [['1','2','3'],['4','5','6'],['7','8','9']])
                  Row(children: row.map((d) => _numBtn(d)).toList()),
                Row(children: [
                  _numBtn('', onTap: () {}, bg: Colors.transparent),
                  _numBtn('0'),
                  _numBtn('⌫', onTap: _onDelete, bg: const Color(0xFFF6E7EF)),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ══════════════════════════════════════════════════════════════
   TRANSFER MONEY
══════════════════════════════════════════════════════════════ */

class TransferMoneyPage extends StatefulWidget {
  const TransferMoneyPage({super.key});

  @override
  State<TransferMoneyPage> createState() => _TransferMoneyPageState();
}

class _TransferMoneyPageState extends State<TransferMoneyPage> {
  final _amountController = TextEditingController(text: '5');
  final _noteController   = TextEditingController(text: 'Allowance');
  late final TextEditingController _kidIdController =
      TextEditingController(text: AppData.linkedKidId ?? '');
  bool isSending = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _kidIdController.dispose();
    super.dispose();
  }

  Future<void> _confirmPinThenSend() async {
    final entered = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PinDialog(title: 'Enter PIN to\nconfirm transfer'),
    );
    if (entered == null) return;
    if (entered != MockStore.parentPin) {
      _toast('Wrong PIN ❌ Transfer cancelled');
      return;
    }
    await _send();
  }

  Future<void> _send() async {
    final amount = double.tryParse(_amountController.text.trim());
    final kidId  = _kidIdController.text.trim();
    if (kidId.isEmpty) { _toast("Enter the kid's User ID"); return; }
    if (amount == null || amount <= 0) { _toast('Enter a valid amount'); return; }

    setState(() => isSending = true);
    try {
      await ApiService.sendTransfer(
        senderId: AppData.currentUid!,
        receiverId: kidId,
        amount: amount,
        note: _noteController.text.trim(),
      );
      AppData.linkedKidId = kidId;
      setState(() => isSending = false);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Done!', style: px(10)),
          content: Text(
              'Sent \$${amount.toStringAsFixed(2)} to kid.\nNote: ${_noteController.text}',
              style: px(8)),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              child: Text('Done', style: px(8)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isSending = false);
      _toast(e.toString().contains('Insufficient') ? 'Not enough balance' : 'Transfer failed: $e');
    }
  }

  void _toast(String msg) {
    final lower = msg.toLowerCase();
    final isError = lower.contains('wrong') ||
        lower.contains('enter') ||
        lower.contains('not enough') ||
        lower.contains('failed');
    showCuteNotification(context, msg,
        type: isError ? NotificationType.error : NotificationType.success);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF3ECF1),
      appBar: AppBar(
        title: Text('Transfer Money', style: px(9)),
        backgroundColor: const Color(0xFFF3ECF1),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              TextField(
                controller: _kidIdController,
                style: px(8),
                decoration: InputDecoration(
                  labelText: "Kid's User ID", labelStyle: px(7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: px(8),
                decoration: InputDecoration(
                  labelText: 'Amount', labelStyle: px(7), prefixText: '\$ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                style: px(8),
                decoration: InputDecoration(
                  labelText: 'Note', labelStyle: px(7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isSending ? null : _confirmPinThenSend,
                icon: isSending
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, color: Colors.white),
                label: Text(isSending ? 'Sending...' : 'Send',
                    style: px(8, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ══════════════════════════════════════════════════════════════
   KIDS EXPENSE TRACKER (Parent view)
══════════════════════════════════════════════════════════════ */

class KidsExpenseTrackerPage extends StatefulWidget {
  const KidsExpenseTrackerPage({super.key});

  @override
  State<KidsExpenseTrackerPage> createState() => _KidsExpenseTrackerPageState();
}

class _KidsExpenseTrackerPageState extends State<KidsExpenseTrackerPage> {
  List<dynamic> _expenses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final kidId = AppData.linkedKidId;
    if (kidId == null || kidId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final all = await ApiService.getTransactionHistory(kidId);
      final spent = all.where((t) => t['direction'] == 'out').toList();
      if (!mounted) return;
      setState(() => _expenses = spent);
    } catch (e) {
      if (!mounted) return;
      showCuteNotification(context, 'Could not load expenses: $e', type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF3ECF1),
      appBar: AppBar(
        title: Text('Expense Tracker', style: px(9)),
        backgroundColor: const Color(0xFFF3ECF1),
        elevation: 0,
        actions: [
          IconButton(onPressed: _load, icon: Icon(Icons.refresh, color: cs.primary)),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : (AppData.linkedKidId == null || AppData.linkedKidId!.isEmpty)
                  ? Center(child: Text(
                      "Link a kid's User ID from Parent Home first.",
                      style: px(7, color: Colors.black45), textAlign: TextAlign.center))
                  : ListView(
                      children: [
                        Text('Recent expenses', style: px(8, weight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        if (_expenses.isEmpty)
                          Text('No expenses yet.', style: px(7, color: Colors.black45)),
                        for (final e in _expenses)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF2C1B3D).withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.payments_outlined, color: cs.secondary, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e['description'] ?? e['type'] ?? '',
                                          style: px(8, weight: FontWeight.bold)),
                                      const SizedBox(height: 3),
                                      Text(e['type'] ?? '', style: px(6, color: Colors.black45)),
                                    ],
                                  ),
                                ),
                                Text('-\$${(e['amount'] ?? 0).toStringAsFixed(2)}',
                                    style: px(8, color: const Color(0xFFB33B6C), weight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    ),
        ),
      ),
    );
  }
}

/* ══════════════════════════════════════════════════════════════
   PIN DIALOG WIDGET
══════════════════════════════════════════════════════════════ */

class _PinDialog extends StatefulWidget {
  final String title;
  const _PinDialog({required this.title});

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  String _pin = '';

  void _onKey(String digit) {
    if (_pin.length >= 4) return;
    setState(() => _pin += digit);
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) Navigator.pop(context, _pin);
      });
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Widget _numBtn(String label, {VoidCallback? onTap, Color? bg}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: bg ?? const Color(0xFFF3ECF1),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap ?? () => _onKey(label),
            child: SizedBox(
              height: 58,
              child: Center(
                child: label == '⌫'
                    ? const Icon(Icons.backspace_outlined, color: Color(0xFF5C1638), size: 22)
                    : Text(label, style: px(13, color: const Color(0xFF5C1638), weight: FontWeight.bold)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: const Color(0xFFF3ECF1),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6D1E45), Color(0xFF5C1638)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF6D1E45).withValues(alpha: 0.35),
                        blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.lock_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 14),
              Text(widget.title,
                  style: px(7, color: const Color(0xFF5C1638), weight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _pin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? const Color(0xFF6D1E45)
                          : const Color(0xFF6D1E45).withValues(alpha: 0.2),
                      border: Border.all(color: const Color(0xFF6D1E45), width: 2),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 22),
              for (final row in [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
              ])
                Row(children: row.map((d) => _numBtn(d)).toList()),
              Row(children: [
                _numBtn('', onTap: () {}, bg: Colors.transparent),
                _numBtn('0'),
                _numBtn('⌫', onTap: _onDelete, bg: const Color(0xFFF6E7EF)),
              ]),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text('Cancel', style: px(7, color: Colors.black45)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ══════════════════════════════════════════════════════════════
   PARENT PIN SETUP PAGE
══════════════════════════════════════════════════════════════ */

class ParentPinSetupPage extends StatefulWidget {
  final Session session;
  const ParentPinSetupPage({super.key, required this.session});

  @override
  State<ParentPinSetupPage> createState() => _ParentPinSetupPageState();
}

class _ParentPinSetupPageState extends State<ParentPinSetupPage> {
  String _pin    = '';
  String _confirm = '';
  bool _step2    = false;
  String _error  = '';

  void _onKey(String digit) {
    setState(() {
      _error = '';
      if (!_step2) {
        if (_pin.length >= 4) return;
        _pin += digit;
        if (_pin.length == 4) {
          Future.delayed(const Duration(milliseconds: 180), () {
            if (mounted) setState(() => _step2 = true);
          });
        }
      } else {
        if (_confirm.length >= 4) return;
        _confirm += digit;
        if (_confirm.length == 4) {
          Future.delayed(const Duration(milliseconds: 180), () {
            if (!mounted) return;
            if (_confirm == _pin) {
              MockStore.parentPin = _pin;
              Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (_) => ParentHome(session: widget.session)),
                  (r) => false);
            } else {
              setState(() {
                _error   = 'PINs do not match. Try again!';
                _pin     = '';
                _confirm = '';
                _step2   = false;
              });
            }
          });
        }
      }
    });
  }

  void _onDelete() {
    setState(() {
      _error = '';
      if (!_step2) {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_confirm.isNotEmpty) _confirm = _confirm.substring(0, _confirm.length - 1);
      }
    });
  }

  Widget _numBtn(String label, {VoidCallback? onTap, Color? bg}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: bg ?? const Color(0xFFF3ECF1),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap ?? () => _onKey(label),
            child: SizedBox(
              height: 58,
              child: Center(
                child: label == '⌫'
                    ? const Icon(Icons.backspace_outlined, color: Color(0xFF5C1638), size: 22)
                    : Text(label, style: px(13, color: const Color(0xFF5C1638), weight: FontWeight.bold)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPin = _step2 ? _confirm : _pin;

    return Scaffold(
      backgroundColor: const Color(0xFFF3ECF1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6D1E45), Color(0xFF5C1638)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF6D1E45).withValues(alpha: 0.4),
                          blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 20),
                Text(
                  _step2 ? 'Confirm your PIN' : 'Set a 4-digit PIN',
                  style: px(9, color: const Color(0xFF5C1638), weight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _step2
                      ? 'Re-enter your PIN to confirm'
                      : 'This PIN will be needed\nfor every money transfer',
                  style: px(6, color: Colors.black45),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final filled = i < currentPin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled
                            ? const Color(0xFF6D1E45)
                            : const Color(0xFF6D1E45).withValues(alpha: 0.18),
                        border: Border.all(color: const Color(0xFF6D1E45), width: 2),
                      ),
                    );
                  }),
                ),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6E7EF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_error,
                        style: px(6, color: const Color(0xFFB33B6C)),
                        textAlign: TextAlign.center),
                  ),
                ],
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _stepDot(active: !_step2, done: _step2),
                    const SizedBox(width: 8),
                    _stepDot(active: _step2, done: false),
                  ],
                ),
                const SizedBox(height: 24),
                for (final row in [
                  ['1', '2', '3'],
                  ['4', '5', '6'],
                  ['7', '8', '9'],
                ])
                  Row(children: row.map((d) => _numBtn(d)).toList()),
                Row(children: [
                  _numBtn('', onTap: () {}, bg: Colors.transparent),
                  _numBtn('0'),
                  _numBtn('⌫', onTap: _onDelete, bg: const Color(0xFFF6E7EF)),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepDot({required bool active, required bool done}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 24 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: active || done
            ? const Color(0xFF6D1E45)
            : const Color(0xFF6D1E45).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

/* ══════════════════════════════════════════════════════════════
   CHORE MANAGER (Parent)  ★ NEW: each chore now has a delete (🗑️)
   button so the parent can remove chores they created, calling the
   new DELETE /api/chores/:choreId backend route.
══════════════════════════════════════════════════════════════ */

class ChoreManagerPage extends StatefulWidget {
  const ChoreManagerPage({super.key});

  @override
  State<ChoreManagerPage> createState() => _ChoreManagerPageState();
}

class _ChoreManagerPageState extends State<ChoreManagerPage> {
  final _titleCtrl  = TextEditingController();
  final _rewardCtrl = TextEditingController();
  late final TextEditingController _kidIdCtrl =
      TextEditingController(text: AppData.linkedKidId ?? '');

  List<dynamic> _chores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChores();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _rewardCtrl.dispose();
    _kidIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadChores() async {
    setState(() => _loading = true);
    try {
      final chores = await ApiService.getParentChores(AppData.currentUid!);
      if (!mounted) return;
      setState(() => _chores = chores);
    } catch (e) {
      if (!mounted) return;
      showCuteNotification(context, 'Could not load chores: $e', type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addChore() async {
    final title  = _titleCtrl.text.trim();
    final reward = double.tryParse(_rewardCtrl.text.trim());
    final kidId  = _kidIdCtrl.text.trim();
    if (title.isEmpty || reward == null || reward <= 0 || kidId.isEmpty) {
      showCuteNotification(context, 'Fill chore name, reward and Kid ID',
          type: NotificationType.error);
      return;
    }
    try {
      await ApiService.createChore(
        parentId: AppData.currentUid!, kidId: kidId, title: title, amount: reward,
      );
      AppData.linkedKidId = kidId;
      _titleCtrl.clear();
      _rewardCtrl.clear();
      showCuteNotification(context, 'Chore created! 🧹', type: NotificationType.success);
      _loadChores();
    } catch (e) {
      showCuteNotification(context, 'Failed: $e', type: NotificationType.error);
    }
  }

  Future<void> _approveChore(String choreId, double amount) async {
    try {
      await ApiService.approveChore(choreId);
      showCuteNotification(context, 'Approved! \$${amount.toStringAsFixed(2)} sent to kid 🎉',
          type: NotificationType.success);
      _loadChores();
    } catch (e) {
      showCuteNotification(context, 'Failed: $e', type: NotificationType.error);
    }
  }

  // ★ NEW: confirm, then delete the chore via the backend, then refresh.
  Future<void> _confirmDeleteChore(String choreId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFF3ECF1),
        title: Text('Delete chore?', style: px(9)),
        content: Text('Are you sure you want to delete "$title"?', style: px(7)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: px(7, color: Colors.black45)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: px(7, color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.deleteChore(choreId);
      if (!mounted) return;
      showCuteNotification(context, 'Chore deleted 🗑️', type: NotificationType.success);
      _loadChores();
    } catch (e) {
      if (!mounted) return;
      showCuteNotification(context, 'Failed: $e', type: NotificationType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF43C59E);

    return Scaffold(
      backgroundColor: const Color(0xFFF3ECF1),
      appBar: AppBar(
        title: Text('Chore Manager', style: px(9)),
        backgroundColor: const Color(0xFFF3ECF1),
        elevation: 0,
        actions: [
          IconButton(onPressed: _loadChores, icon: const Icon(Icons.refresh, color: accent)),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add New Chore', style: px(8, weight: FontWeight.bold, color: accent)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _kidIdCtrl,
                      style: px(7),
                      decoration: InputDecoration(
                        labelText: "Kid's User ID", labelStyle: px(6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: accent, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleCtrl,
                      style: px(7),
                      decoration: InputDecoration(
                        labelText: 'Chore name', labelStyle: px(6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: accent, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _rewardCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: px(7),
                      decoration: InputDecoration(
                        labelText: 'Reward (\$)', labelStyle: px(6),
                        prefixText: '\$ ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: accent, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _addChore,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: Text('Add Chore', style: px(7, color: Colors.white)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('All Chores', style: px(8, weight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_chores.isEmpty)
                Text('No chores yet.', style: px(7, color: Colors.black45))
              else
                for (final c in _chores)
                  _ChoreCard(
                    title: c['title'] ?? '',
                    reward: (c['amount'] ?? 0).toDouble(),
                    status: c['status'] ?? 'pending',
                    onApprove: c['status'] == 'done'
                        ? () => _approveChore(c['choreId'], (c['amount'] ?? 0).toDouble())
                        : null,
                    // ★ NEW: delete is always available, regardless of status
                    onDelete: () => _confirmDeleteChore(c['choreId'], c['title'] ?? 'this chore'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoreCard extends StatelessWidget {
  final String title;
  final double reward;
  final String status; // 'pending' | 'done' | 'approved'
  final VoidCallback? onApprove;
  final VoidCallback? onDelete; // ★ NEW
  const _ChoreCard({
    required this.title,
    required this.reward,
    required this.status,
    this.onApprove,
    this.onDelete, // ★ NEW
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF43C59E);
    Color statusColor = status == 'approved'
        ? Colors.green
        : status == 'done' ? Colors.orange : Colors.grey;
    String statusText = status == 'approved'
        ? 'Paid ✓'
        : status == 'done' ? 'Needs Approval' : 'Pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.task_alt, color: statusColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: px(7, weight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text('Reward: \$${reward.toStringAsFixed(2)}  •  $statusText',
                    style: px(6, color: statusColor)),
              ],
            ),
          ),
          // ★ NEW: Approve (if applicable) + Delete, stacked together
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onApprove != null)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: onApprove,
                  child: Text('Approve', style: px(6, color: Colors.white)),
                ),
              if (onApprove != null) const SizedBox(height: 6),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'Delete chore',
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ══════════════════════════════════════════════════════════════
   WEEKLY REPORT (Parent)
══════════════════════════════════════════════════════════════ */

class WeeklyReportPage extends StatefulWidget {
  const WeeklyReportPage({super.key});

  @override
  State<WeeklyReportPage> createState() => _WeeklyReportPageState();
}

class _WeeklyReportPageState extends State<WeeklyReportPage> {
  Map<String, dynamic>? _report;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final kidId = AppData.linkedKidId;
    if (kidId == null || kidId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final data = await ApiService.getWeeklyReport(kidId);
      if (!mounted) return;
      setState(() => _report = data);
    } catch (e) {
      if (!mounted) return;
      showCuteNotification(context, 'Could not load report: $e', type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF6D1E45),
      const Color(0xFF2C1B3D),
      const Color(0xFFB33B6C),
      const Color(0xFF43C59E),
      const Color(0xFFFF8C42),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3ECF1),
      appBar: AppBar(
        title: Text('Weekly Report', style: px(9)),
        backgroundColor: const Color(0xFFF3ECF1),
        elevation: 0,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: Color(0xFF6D1E45))),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : (AppData.linkedKidId == null || AppData.linkedKidId!.isEmpty)
                  ? Center(child: Text(
                      "Link a kid's User ID from Parent Home first.",
                      style: px(7, color: Colors.black45), textAlign: TextAlign.center))
                  : ListView(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF3ECF1), Color(0xFFF6E7EF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('This Week', style: px(7, color: Colors.black54)),
                              const SizedBox(height: 6),
                              Text('\$${(_report?['totalSpent'] ?? 0).toStringAsFixed(2)} spent',
                                  style: px(14, color: const Color(0xFF6D1E45), weight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('\$${(_report?['totalReceived'] ?? 0).toStringAsFixed(2)} received',
                                  style: px(8, color: Colors.black45)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Spending By Type', style: px(8, weight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        ...(() {
                          final breakdown = (_report?['spentBreakdown'] as Map?) ?? {};
                          final total = (_report?['totalSpent'] ?? 0).toDouble();
                          final entries = breakdown.entries.toList();
                          if (entries.isEmpty) {
                            return [Text('No spending recorded this week.',
                                style: px(7, color: Colors.black45))];
                          }
                          return entries.asMap().entries.map((entry) {
                            final idx  = entry.key;
                            final type = entry.value.key.toString();
                            final amt  = (entry.value.value as num).toDouble();
                            final pct  = total > 0 ? amt / total : 0.0;
                            final color = colors[idx % colors.length];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(type, style: px(7, color: Colors.black87)),
                                      Text('\$${amt.toStringAsFixed(2)}',
                                          style: px(7, color: color, weight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: pct,
                                      minHeight: 12,
                                      backgroundColor: color.withValues(alpha: 0.15),
                                      valueColor: AlwaysStoppedAnimation<Color>(color),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList();
                        })(),
                      ],
                    ),
        ),
      ),
    );
  }
}

/* ══════════════════════════════════════════════════════════════
   KID HOME  — bottom-nav shell: Home / Challenges / Rewards / Profile
══════════════════════════════════════════════════════════════ */

class KidHome extends StatefulWidget {
  final Session session;
  const KidHome({super.key, required this.session});

  @override
  State<KidHome> createState() => _KidHomeState();
}

class _KidHomeState extends State<KidHome> {
  int _tab = 0;

  static const _titles = ['Kid Portal', 'Challenges', 'Rewards', 'Profile'];

  @override
  Widget build(BuildContext context) {
    final pages = [
      _KidDashboardTab(session: widget.session),
      const _KidChallengesTab(),
      const _KidRewardsTab(),
      const KidProfileTab(),
    ];

    return Scaffold(
      backgroundColor: KPalette.bgLight,
      appBar: AppBar(
        title: Text(_titles[_tab],
            style: px(9, color: KPalette.headerText, weight: FontWeight.bold)),
        backgroundColor: KPalette.bgLight,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const WelcomePage()),
                (r) => false),
            icon: const Icon(Icons.logout, color: KPalette.headerText),
          ),
        ],
      ),
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: _KPortalNavBar(
        index: _tab,
        onChanged: (i) => setState(() => _tab = i),
        items: const [
          _NavItem(icon: Icons.home_rounded, label: 'Home'),
          _NavItem(icon: Icons.emoji_events_outlined, label: 'Challenges'),
          _NavItem(icon: Icons.star_border_rounded, label: 'Rewards'),
          _NavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

/* Shared bottom nav bar used by both Kid & Parent portals — dark
   maroon bar with a pink pill highlight on the active tab. */
class _KPortalNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final List<_NavItem> items;
  const _KPortalNavBar({required this.index, required this.onChanged, required this.items});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: KPalette.navBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: KPalette.navBg.withValues(alpha: 0.45),
                blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(items.length, (i) {
            final selected = i == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? KPalette.navActiveBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[i].icon,
                          color: selected ? Colors.white : KPalette.navInactive, size: 20),
                      const SizedBox(height: 3),
                      Text(items[i].label,
                          style: px(5,
                              color: selected ? Colors.white : KPalette.navInactive,
                              weight: selected ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/* ── Home tab: balance, level, quick actions ─────────────────── */
class _KidDashboardTab extends StatefulWidget {
  final Session session;
  const _KidDashboardTab({required this.session});

  @override
  State<_KidDashboardTab> createState() => _KidDashboardTabState();
}

class _KidDashboardTabState extends State<_KidDashboardTab> {
  double _balance = 0;
  Map<String, dynamic>? _level;
  int _earnedCount = 0;
  int _totalBadges = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final uid = AppData.currentUid!;
      final balance = await ApiService.getApproxBalance(uid);
      final badgeData = await ApiService.getBadges(uid);
      if (!mounted) return;
      setState(() {
        _balance = balance;
        _level = badgeData['level'] as Map<String, dynamic>?;
        _earnedCount = badgeData['earnedCount'] ?? 0;
        _totalBadges = badgeData['totalBadges'] ?? 0;
      });
    } catch (e) {
      if (!mounted) return;
      showCuteNotification(context, 'Could not load your data: $e', type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
      onRefresh: _loadAll,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Hello! 👋', style: px(9, color: KPalette.headerText, weight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(AppData.fullName ?? session.email,
                style: px(7, color: Colors.black54),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('Your User ID: ${AppData.currentUid ?? '—'}',
                style: px(5, color: Colors.black38),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [KPalette.cardDark1, KPalette.cardDark2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: KPalette.cardDark1.withValues(alpha: 0.35),
                      blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _level != null
                          ? 'Level ${_level!['number']}: ${_level!['title']}'
                          : 'Level 1: Beginner',
                      style: px(8, color: Colors.white, weight: FontWeight.bold),
                    ),
                  ),
                  Text('$_earnedCount/$_totalBadges 🏆',
                      style: px(6, color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: KPalette.headerText.withValues(alpha: 0.12),
                      blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, size: 30, color: KPalette.headerText),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your balance', style: px(7, color: Colors.black54)),
                      const SizedBox(height: 6),
                      Text('\$${_balance.toStringAsFixed(2)}',
                          style: px(16, color: KPalette.headerText, weight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Cool stuff', style: px(9, weight: FontWeight.bold, color: KPalette.headerText)),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.qr_code_scanner,
              title: 'Spend with QR',
              subtitle: 'Scan a QR to pay',
              accent: KPalette.tileDarkest,
              onTap: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SpendWithQrPage()));
                _loadAll();
              },
            ),
            _ActionTile(
              icon: Icons.insights_outlined,
              title: 'Track expenses',
              subtitle: 'See what you spent',
              accent: KPalette.tileDarkNavy,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const KidExpensesPage())),
            ),
            _ActionTile(
              icon: Icons.calculate_outlined,
              title: 'Calculator',
              subtitle: 'Quick math for saving',
              accent: KPalette.tileLavender,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CalculatorPage())),
            ),
            _ActionTile(
              icon: Icons.favorite_border,
              title: 'Savings goals',
              subtitle: 'Set goals and achieve',
              accent: KPalette.rose,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const WishListPage())),
            ),
            _ActionTile(
              icon: Icons.savings_rounded,
              title: 'Piggy Bank',
              subtitle: 'Save for your goal',
              accent: const Color(0xFFB33B6C),
              onTap: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PiggyBankPage()));
                _loadAll();
              },
            ),
            _ActionTile(
              icon: Icons.history_rounded,
              title: 'Transaction History',
              subtitle: 'All your money moves',
              accent: const Color(0xFF5C1638),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TransactionHistoryPage())),
            ),
          ],
        ),
      ),
    );
  }
}

/* ── Challenges tab: chores (embedded, no extra app bar) ─────── */
class _KidChallengesTab extends StatefulWidget {
  const _KidChallengesTab();

  @override
  State<_KidChallengesTab> createState() => _KidChallengesTabState();
}

class _KidChallengesTabState extends State<_KidChallengesTab> {
  List<dynamic> _chores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChores();
  }

  Future<void> _loadChores() async {
    setState(() => _loading = true);
    try {
      final chores = await ApiService.getKidChores(AppData.currentUid!);
      if (!mounted) return;
      setState(() => _chores = chores);
    } catch (e) {
      if (!mounted) return;
      showCuteNotification(context, 'Could not load chores: $e', type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markDone(String choreId) async {
    try {
      await ApiService.completeChore(choreId);
      showCuteNotification(context, 'Chore marked done! Wait for parent approval 🎉',
          type: NotificationType.success);
      _loadChores();
    } catch (e) {
      showCuteNotification(context, 'Failed: $e', type: NotificationType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_chores.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadChores,
        child: ListView(
          children: [
            SizedBox(height: 120),
            Center(child: Text('No challenges yet!\nAsk your parent to add some 😊',
                style: px(7, color: Colors.black45), textAlign: TextAlign.center)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadChores,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Complete challenges to earn money!',
              style: px(7, color: Colors.black54)),
          const SizedBox(height: 12),
          for (final c in _chores)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: KPalette.headerText.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: c['status'] == 'approved'
                          ? Colors.green.withValues(alpha: 0.15)
                          : c['status'] == 'done'
                              ? Colors.orange.withValues(alpha: 0.15)
                              : KPalette.rose.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      c['status'] == 'approved'
                          ? Icons.check_circle
                          : c['status'] == 'done'
                              ? Icons.hourglass_top
                              : Icons.radio_button_unchecked,
                      color: c['status'] == 'approved'
                          ? Colors.green
                          : c['status'] == 'done'
                              ? Colors.orange
                              : KPalette.rose,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['title'] ?? '', style: px(7, weight: FontWeight.bold)),
                        const SizedBox(height: 3),
                        Text(
                          c['status'] == 'approved'
                              ? '✅ Paid \$${(c['amount'] ?? 0).toStringAsFixed(2)}'
                              : c['status'] == 'done'
                                  ? '⏳ Waiting for approval'
                                  : '💰 Earn \$${(c['amount'] ?? 0).toStringAsFixed(2)}',
                          style: px(6, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  if (c['status'] == 'pending')
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: KPalette.rose,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _markDone(c['choreId']),
                      child: Text('Done!', style: px(6, color: Colors.white)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/* ── Rewards tab: badges (embedded, no extra app bar) ─────────── */
class _KidRewardsTab extends StatefulWidget {
  const _KidRewardsTab();

  @override
  State<_KidRewardsTab> createState() => _KidRewardsTabState();
}

class _KidRewardsTabState extends State<_KidRewardsTab> {
  List<dynamic> _badges = [];
  Map<String, dynamic>? _level;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getBadges(AppData.currentUid!);
      if (!mounted) return;
      setState(() {
        _badges = (data['badges'] as List?) ?? [];
        _level  = data['level'] as Map<String, dynamic>?;
      });
    } catch (e) {
      if (!mounted) return;
      showCuteNotification(context, 'Could not load rewards: $e', type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Achievements 🏆', style: px(8, weight: FontWeight.bold, color: KPalette.headerText)),
            const SizedBox(height: 6),
            if (_level != null)
              Text("Level ${_level!['number']}: ${_level!['title']}",
                  style: px(7, color: KPalette.rose)),
            const SizedBox(height: 4),
            Text(
              '${_badges.where((b) => b['earned'] == true).length}/${_badges.length} unlocked',
              style: px(7, color: Colors.black45),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _badges.isEmpty
                  ? ListView(children: [
                      SizedBox(height: 80),
                      Center(child: Text('No rewards yet.', style: px(7, color: Colors.black45))),
                    ])
                  : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: _badges.length,
                itemBuilder: (context, i) {
                  final b = _badges[i];
                  final unlocked = b['earned'] == true;
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: unlocked ? Colors.white : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: unlocked
                            ? KPalette.rose.withValues(alpha: 0.5)
                            : Colors.grey.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: unlocked
                          ? [BoxShadow(
                              color: KPalette.rose.withValues(alpha: 0.15),
                              blurRadius: 8, offset: const Offset(0, 2))]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          unlocked ? '🏆' : '🔒',
                          style: TextStyle(fontSize: 32, color: unlocked ? null : Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          b['title'] ?? '',
                          style: px(6,
                              color: unlocked ? Colors.black87 : Colors.grey,
                              weight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          b['description'] ?? '',
                          style: px(5, color: Colors.black45),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text('${b['progress']}/${b['total']}',
                            style: px(5, color: KPalette.rose)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ── Profile tab: kid's profile — email, avatar picker, etc. ──── */
class KidProfileTab extends StatefulWidget {
  const KidProfileTab({super.key});

  @override
  State<KidProfileTab> createState() => _KidProfileTabState();
}

class _KidProfileTabState extends State<KidProfileTab> {
  double _balance = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final balance = await ApiService.getApproxBalance(AppData.currentUid!);
      if (!mounted) return;
      setState(() => _balance = balance);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (file == null) return;
      setState(() => AppData.profileImage = File(file.path));
    } catch (e) {
      if (!mounted) return;
      showCuteNotification(context, 'Could not open gallery: $e', type: NotificationType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: KPalette.cardDark1,
                backgroundImage: AppData.profileImage != null
                    ? FileImage(AppData.profileImage!)
                    : null,
                child: AppData.profileImage == null
                    ? const Text('🧒', style: TextStyle(fontSize: 40))
                    : null,
              ),
              Positioned(
                right: 0, bottom: 0,
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: KPalette.rose,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(AppData.fullName ?? 'Kid',
              style: px(10, color: KPalette.headerText, weight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(AppData.currentEmail ?? '—',
              style: px(6, color: Colors.black45)),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: KPalette.headerText.withValues(alpha: 0.1),
                  blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            children: [
              _profileRow(Icons.badge_outlined, 'Role', 'Kid'),
              const Divider(height: 20),
              _profileRow(Icons.email_outlined, 'Email', AppData.currentEmail ?? '—'),
              const Divider(height: 20),
              _profileRow(Icons.fingerprint, 'User ID', AppData.currentUid ?? '—'),
              const Divider(height: 20),
              _profileRow(Icons.account_balance_wallet_outlined, 'Balance',
                  _loading ? '…' : '\$${_balance.toStringAsFixed(2)}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: KPalette.headerText,
            side: BorderSide(color: KPalette.headerText.withValues(alpha: 0.4), width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.pushAndRemoveUntil(context,
              MaterialPageRoute(builder: (_) => const WelcomePage()), (r) => false),
          icon: const Icon(Icons.logout),
          label: Text('Sign out', style: px(7)),
        ),
      ],
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: KPalette.headerText, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: px(6, color: Colors.black54))),
        Flexible(
          child: Text(value,
              style: px(7, weight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

/* ══════════════════════════════════════════════════════════════
   KID CHORES PAGE
══════════════════════════════════════════════════════════════ */

class KidChoresPage extends StatefulWidget {
  const KidChoresPage({super.key});

  @override
  State<KidChoresPage> createState() => _KidChoresPageState();
}

class _KidChoresPageState extends State<KidChoresPage> {
  List<dynamic> _chores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChores();
  }

  Future<void> _loadChores() async {
    setState(() => _loading = true);
    try {
      final chores = await ApiService.getKidChores(AppData.currentUid!);
      if (!mounted) return;
      setState(() => _chores = chores);
    } catch (e) {
      if (!mounted) return;
      showCuteNotification(context, 'Could not load chores: $e', type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markDone(String choreId) async {
    try {
      await ApiService.completeChore(choreId);
      showCuteNotification(context, 'Chore marked done! Wait for parent approval 🎉',
          type: NotificationType.success);
      _loadChores();
    } catch (e) {
      showCuteNotification(context, 'Failed: $e', type: NotificationType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF43C59E);

    return Scaffold(
      backgroundColor: const Color(0xFFF3ECF1),
      appBar: AppBar(
        title: Text('My Chores', style: px(9)),
        backgroundColor: const Color(0xFFF3ECF1),
        elevation: 0,
        actions: [
          IconButton(onPressed: _loadChores, icon: const Icon(Icons.refresh, color: accent)),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _chores.isEmpty
                  ? Center(child: Text('No chores yet!\nAsk your parent to add some 😊',
                      style: px(7, color: Colors.black45), textAlign: TextAlign.center))
                  : ListView(
                      children: [
                        Text('Complete chores to earn money!',
                            style: px(7, color: Colors.black54)),
                        const SizedBox(height: 12),
                        for (final c in _chores)
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: accent.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: c['status'] == 'approved'
                                        ? Colors.green.withValues(alpha: 0.15)
                                        : c['status'] == 'done'
                                            ? Colors.orange.withValues(alpha: 0.15)
                                            : accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    c['status'] == 'approved'
                                        ? Icons.check_circle
                                        : c['status'] == 'done'
                                            ? Icons.hourglass_top
                                            : Icons.radio_button_unchecked,
                                    color: c['status'] == 'approved'
                                        ? Colors.green
                                        : c['status'] == 'done'
                                            ? Colors.orange
                                            : accent,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(c['title'] ?? '', style: px(7, weight: FontWeight.bold)),
                                      const SizedBox(height: 3),
                                      Text(
                                        c['status'] == 'approved'
                                            ? '✅ Paid \$${(c['amount'] ?? 0).toStringAsFixed(2)}'
                                            : c['status'] == 'done'
                                                ? '⏳ Waiting for approval'
                                                : '💰 Earn \$${(c['amount'] ?? 0).toStringAsFixed(2)}',
                                        style: px(6, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),
                                if (c['status'] == 'pending')
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: accent,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () => _markDone(c['choreId']),
                                    child: Text('Done!', style: px(6, color: Colors.white)),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
        ),
      ),
    );
  }
}

/* ══════════════════════════════════════════════════════════════
   BADGES PAGE
══════════════════════════════════════════════════════════════ */

class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {
  List<dynamic> _badges = [];
  Map<String, dynamic>? _level;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getBadges(AppData.currentUid!);
      if (!mounted) return;
      setState(() {
        _badges = (data['badges'] as List?) ?? [];
        _level  = data['level'] as Map<String, dynamic>?;
      });
    } catch (e) {
      if (!mounted) return;
      showCuteNotification(context, 'Could not load badges: $e', type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3ECF1),
      appBar: AppBar(
        title: Text('Badges', style: px(9)),
        backgroundColor: const Color(0xFFF3ECF1),
        elevation: 0,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: Color(0xFFFF8C42))),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Achievements 🏆', style: px(8, weight: FontWeight.bold)),
              const SizedBox(height: 6),
              if (_level != null)
                Text("Level ${_level!['number']}: ${_level!['title']}",
                    style: px(7, color: const Color(0xFF6D1E45))),
              const SizedBox(height: 4),
              Text(
                '${_badges.where((b) => b['earned'] == true).length}/${_badges.length} unlocked',
                style: px(7, color: Colors.black45),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _badges.length,
                  itemBuilder: (context, i) {
                    final b = _badges[i];
                    final unlocked = b['earned'] == true;
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: unlocked ? Colors.white : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: unlocked
                              ? const Color(0xFFFF8C42).withValues(alpha: 0.5)
                              : Colors.grey.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        boxShadow: unlocked
                            ? [BoxShadow(
                                color: const Color(0xFFFF8C42).withValues(alpha: 0.15),
                                blurRadius: 8, offset: const Offset(0, 2))]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            unlocked ? '🏆' : '🔒',
                            style: TextStyle(fontSize: 32, color: unlocked ? null : Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            b['title'] ?? '',
                            style: px(6,
                                color: unlocked ? Colors.black87 : Colors.grey,
                                weight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            b['description'] ?? '',
                            style: px(5, color: Colors.black45),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text('${b['progress']}/${b['total']}',
                              style: px(5, color: const Color(0xFFFF8C42))),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ══════════════════════════════════════════════════════════════
   PIGGY BANK PAGE
══════════════════════════════════════════════════════════════ */

class PiggyBankPage extends StatefulWidget {
  const PiggyBankPage({super.key});

  @override
  State<PiggyBankPage> createState() => _PiggyBankPageState();
}

class _PiggyBankPageState extends State<PiggyBankPage> {
  final _amountCtrl = TextEditingController(text: '5');
  double piggyTarget = 30.0;
  double _piggySaved = 0;
  double _balance = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final kidId = AppData.currentUid!;
      final piggy = await ApiService.getPiggyBank(kidId);
      final balance = await ApiService.getApproxBalance(kidId);
      if (!mounted) return;
      setState(() {
        _piggySaved = (piggy['savedAmount'] ?? 0).toDouble();
        final t = (piggy['targetAmount'] ?? 30).toDouble();
        piggyTarget = t > 0 ? t : 30;
        _balance = balance;
      });
    } catch (e) {
      if (!mounted) return;
      showCuteNotification(context, 'Could not load piggy bank: $e', type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final amt = double.tryParse(_amountCtrl.text.trim());
    if (amt == null || amt <= 0) { _toast('Enter valid amount'); return; }
    if (amt > _balance) { _toast('Not enough balance!'); return; }
    try {
      final kidId = AppData.currentUid!;
      await ApiService.setPiggyTarget(kidId: kidId, targetAmount: piggyTarget);
      await ApiService.piggyDeposit(kidId: kidId, amount: amt);
      _toast('Saved \$${amt.toStringAsFixed(2)} to Piggy Bank! 🐷');
      _loadAll();
    } catch (e) {
      _toast('Failed: $e');
    }
  }

  Future<void> _withdraw() async {
    if (_piggySaved <= 0) { _toast('Nothing to withdraw!'); return; }
    try {
      await ApiService.piggyWithdraw(kidId: AppData.currentUid!, amount: _piggySaved);
      _toast('Withdrawn from Piggy Bank 💸');
      _loadAll();
    } catch (e) {
      _toast('Failed: $e');
    }
  }

  void _toast(String msg) {
    final lower = msg.toLowerCase();
    final isError = lower.contains('not enough') ||
        lower.contains('enter valid') ||
        lower.contains('nothing to') ||
        lower.contains('failed');
    showCuteNotification(context, msg,
        type: isError ? NotificationType.error : NotificationType.success);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const accent = Color(0xFFB33B6C);
    final progress = piggyTarget > 0 ? (_piggySaved / piggyTarget).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF3ECF1),
      appBar: AppBar(
        title: Text('Piggy Bank', style: px(9)),
        backgroundColor: const Color(0xFFF3ECF1),
        elevation: 0,
        actions: [
          IconButton(onPressed: _loadAll, icon: const Icon(Icons.refresh, color: accent)),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF6E7EF), Color(0xFFE3AFC0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text('🐷', style: TextStyle(fontSize: 60)),
                    const SizedBox(height: 10),
                    Text('\$${_piggySaved.toStringAsFixed(2)}',
                        style: px(18, color: accent, weight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 14,
                        backgroundColor: Colors.white.withValues(alpha: 0.5),
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('${(progress * 100).toStringAsFixed(0)}% of \$${piggyTarget.toStringAsFixed(0)} goal',
                        style: px(6, color: Colors.black45)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Target: \$${piggyTarget.toStringAsFixed(0)}',
                  style: px(7, weight: FontWeight.bold)),
              Slider(
                value: piggyTarget,
                min: 10, max: 200, divisions: 19,
                activeColor: accent,
                label: '\$${piggyTarget.toStringAsFixed(0)}',
                onChanged: (v) => setState(() => piggyTarget = v),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: px(7),
                decoration: InputDecoration(
                  labelText: 'Amount to save',
                  labelStyle: px(6),
                  prefixText: '\$ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: accent, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _save,
                      icon: const Icon(Icons.savings_rounded, color: Colors.white),
                      label: Text('Save!', style: px(8, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        side: const BorderSide(color: accent, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _withdraw,
                      icon: const Icon(Icons.undo),
                      label: Text('Withdraw', style: px(7, color: accent)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('Balance: \$${_balance.toStringAsFixed(2)}',
                  style: px(7, color: cs.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

/* ══════════════════════════════════════════════════════════════
   TRANSACTION HISTORY PAGE
══════════════════════════════════════════════════════════════ */

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  List<dynamic> _txns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final txns = await ApiService.getTransactionHistory(AppData.currentUid!);
      if (!mounted) return;
      setState(() => _txns = txns);
    } catch (e) {
      if (!mounted) return;
      showCuteNotification(context, 'Could not load history: $e', type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(dynamic createdAt) {
    try {
      if (createdAt is Map) {
        final seconds = createdAt['_seconds'] ?? createdAt['seconds'];
        if (seconds != null) {
          final d = DateTime.fromMillisecondsSinceEpoch((seconds as int) * 1000);
          return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        }
      }
      if (createdAt is String) {
        final d = DateTime.tryParse(createdAt);
        if (d != null) {
          return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        }
      }
    } catch (_) {}
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3ECF1),
      appBar: AppBar(
        title: Text('History', style: px(9)),
        backgroundColor: const Color(0xFFF3ECF1),
        elevation: 0,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: Color(0xFF5C1638))),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _txns.isEmpty
                  ? Center(child: Text('No transactions yet!', style: px(7, color: Colors.black45)))
                  : ListView.builder(
                      itemCount: _txns.length,
                      itemBuilder: (_, i) {
                        final t = _txns[i];
                        final isCredit = t['direction'] == 'in';
                        final amount = (t['amount'] ?? 0).toDouble();
                        final title  = t['description'] ?? (t['type'] ?? 'Transaction');
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCredit
                                  ? Colors.green.withValues(alpha: 0.3)
                                  : const Color(0xFFB33B6C).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: isCredit
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : const Color(0xFFB33B6C).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: isCredit ? Colors.green : const Color(0xFFB33B6C),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: px(7, weight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(_fmt(t['createdAt']), style: px(5, color: Colors.black45)),
                                  ],
                                ),
                              ),
                              Text(
                                '${isCredit ? '+' : '-'}\$${amount.toStringAsFixed(2)}',
                                style: px(8,
                                    color: isCredit ? Colors.green : const Color(0xFFB33B6C),
                                    weight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

/* ══════════════════════════════════════════════════════════════
   SPEND WITH QR
══════════════════════════════════════════════════════════════ */

class SpendWithQrPage extends StatefulWidget {
  const SpendWithQrPage({super.key});

  @override
  State<SpendWithQrPage> createState() => _SpendWithQrPageState();
}

class _SpendWithQrPageState extends State<SpendWithQrPage> {
  final _merchantController = TextEditingController(text: '');
  final _amountController   = TextEditingController(text: '4.25');
  bool paying = false;
  String? _vendorId;

  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _scanCaptured = false;
  bool _torchOn      = false;

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onQrDetected(BarcodeCapture capture) {
    if (_scanCaptured) return;
    if (capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['vendorId'] != null) {
        setState(() {
          _scanCaptured = true;
          _vendorId = decoded['vendorId'].toString();
          _merchantController.text = decoded['vendorName']?.toString() ?? 'Vendor';
        });
        _scannerController.stop();
        showCuteNotification(context, 'Scanned: ${_merchantController.text} 📷',
            type: NotificationType.success);
        return;
      }
    } catch (_) {}
    showCuteNotification(context, 'QR code not recognized 🤔', type: NotificationType.error);
  }

  void _rescan() {
    setState(() {
      _scanCaptured = false;
      _vendorId = null;
      _merchantController.clear();
    });
    _scannerController.start();
  }

  Future<void> _mockScanAndPay() async {
    if (_vendorId == null) { _toast('Scan a vendor QR code first'); return; }
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) { _toast('Enter a valid amount'); return; }
    setState(() => paying = true);
    try {
      final res = await ApiService.qrPay(
        kidId: AppData.currentUid!, vendorId: _vendorId!, amount: amount,
      );
      if (!mounted) return;
      setState(() => paying = false);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Paid!', style: px(10)),
          content: Text(
              'You paid \$${amount.toStringAsFixed(2)} to ${res['vendorName'] ?? _merchantController.text}.',
              style: px(8)),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              child: Text('Nice', style: px(8)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => paying = false);
      _toast(e.toString().contains('Insufficient') ? 'Not enough balance' : 'Payment failed: $e');
    }
  }

  void _toast(String msg) {
    final lower = msg.toLowerCase();
    final isError = lower.contains('enter a valid') || lower.contains('not enough') ||
        lower.contains('scan a vendor') || lower.contains('failed');
    showCuteNotification(context, msg,
        type: isError ? NotificationType.error : NotificationType.success);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF3ECF1),
      appBar: AppBar(
        title: Text('Spend with QR', style: px(9)),
        backgroundColor: const Color(0xFFF3ECF1),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 240,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: const Color(0xFFB33B6C).withValues(alpha: 0.3)),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: _onQrDetected,
                        errorBuilder: (context, error, child) {
                          return Container(
                            color: Colors.black87,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.camera_alt_outlined, color: Colors.white70, size: 36),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Camera not available.\nAllow camera access, or enter\ndetails manually below.',
                                      textAlign: TextAlign.center,
                                      style: px(6, color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (!_scanCaptured)
                        Center(
                          child: Container(
                            width: 170, height: 170,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      if (!_scanCaptured)
                        Positioned(
                          bottom: 8, left: 0, right: 0,
                          child: Text("Point camera at a vendor's QR code",
                              textAlign: TextAlign.center,
                              style: px(6, color: Colors.white)),
                        ),
                      Positioned(
                        top: 8, right: 8,
                        child: IconButton(
                          onPressed: () {
                            setState(() => _torchOn = !_torchOn);
                            _scannerController.toggleTorch();
                          },
                          icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
                          style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: 0.35)),
                        ),
                      ),
                      if (_scanCaptured)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.55),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 40),
                                  const SizedBox(height: 8),
                                  Text('Vendor scanned!', style: px(8, color: Colors.white, weight: FontWeight.bold)),
                                  const SizedBox(height: 10),
                                  TextButton.icon(
                                    onPressed: _rescan,
                                    icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                                    label: Text('Scan again', style: px(7, color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _merchantController,
                readOnly: true,
                style: px(8),
                decoration: InputDecoration(
                  labelText: 'Merchant (from scanned QR)', labelStyle: px(7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: px(8),
                decoration: InputDecoration(
                  labelText: 'Amount', labelStyle: px(7), prefixText: '\$ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB33B6C),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: paying ? null : _mockScanAndPay,
                icon: paying
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.qr_code_scanner, color: Colors.white),
                label: Text(paying ? 'Processing...' : 'Pay',
                    style: px(8, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
/* ══════════════════════════════════════════════════════════════
   SEND MONEY (Kid → anyone)
══════════════════════════════════════════════════════════════ */

class SendMoneyPage extends StatefulWidget {
  const SendMoneyPage({super.key});

  @override
  State<SendMoneyPage> createState() => _SendMoneyPageState();
}

class _SendMoneyPageState extends State<SendMoneyPage> {
  final _receiverIdController = TextEditingController();
  final _amountController = TextEditingController(text: '5');
  final _noteController = TextEditingController(text: 'For you!');
  double _balance = 0;
  bool _loadingBalance = true;
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void dispose() {
    _receiverIdController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    try {
      final bal = await ApiService.getApproxBalance(AppData.currentUid!);
      if (!mounted) return;
      setState(() => _balance = bal);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingBalance = false);
    }
  }

  Future<void> _confirmThenSend() async {
    final receiverId = _receiverIdController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (receiverId.isEmpty) { _toast("Enter the receiver's User ID"); return; }
    if (amount == null || amount <= 0) { _toast('Enter a valid amount'); return; }
    if (amount > _balance) { _toast('Not enough balance'); return; }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFF3ECF1),
        title: Text('Confirm', style: px(9)),
        content: Text(
          'Send \$${amount.toStringAsFixed(2)} to:\n$receiverId ?',
          style: px(7),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: px(7, color: Colors.black45)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2C1B3D)),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Send', style: px(7, color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _send(receiverId, amount);
  }

  Future<void> _send(String receiverId, double amount) async {
    setState(() => isSending = true);
    try {
      await ApiService.sendTransfer(
        senderId: AppData.currentUid!,
        receiverId: receiverId,
        amount: amount,
        note: _noteController.text.trim(),
      );
      if (!mounted) return;
      setState(() => isSending = false);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Sent! 🎉', style: px(10)),
          content: Text(
              'You sent \$${amount.toStringAsFixed(2)} to $receiverId.',
              style: px(8)),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              child: Text('Done', style: px(8)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isSending = false);
      _toast(e.toString().contains('Insufficient')
          ? 'Not enough balance'
          : 'Send failed: $e');
    }
  }

  void _toast(String msg) {
    final lower = msg.toLowerCase();
    final isError = lower.contains('enter') ||
        lower.contains('not enough') ||
        lower.contains('failed');
    showCuteNotification(context, msg,
        type: isError ? NotificationType.error : NotificationType.success);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF3ECF1),
      appBar: AppBar(
        title: Text('Send Money', style: px(9)),
        backgroundColor: const Color(0xFFF3ECF1),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Text(
                _loadingBalance
                    ? 'Loading balance...'
                    : 'Your balance: \$${_balance.toStringAsFixed(2)}',
                style: px(8, color: const Color(0xFF2C1B3D)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _receiverIdController,
                style: px(8),
                decoration: InputDecoration(
                  labelText: "Receiver's User ID", labelStyle: px(7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: px(8),
                decoration: InputDecoration(
                  labelText: 'Amount', labelStyle: px(7), prefixText: '\$ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                style: px(8),
                decoration: InputDecoration(
                  labelText: 'Note', labelStyle: px(7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2C1B3D),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isSending ? null : _confirmThenSend,
                icon: isSending
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, color: Colors.white),
                label: Text(isSending ? 'Sending...' : 'Send',
                    style: px(8, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ══════════════════════════════════════════════════════════════
   KID EXPENSES PAGE
══════════════════════════════════════════════════════════════ */

class KidExpensesPage extends StatefulWidget {
  const KidExpensesPage({super.key});

  @override
  State<KidExpensesPage> createState() => _KidExpensesPageState();
}

class _KidExpensesPageState extends State<KidExpensesPage> {
  List<dynamic> _expenses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final all = await ApiService.getTransactionHistory(AppData.currentUid!);
      final spent = all.where((t) => t['direction'] == 'out').toList();
      if (!mounted) return;
      setState(() => _expenses = spent);
    } catch (e) {
      if (!mounted) return;
      showCuteNotification(context, 'Could not load expenses: $e', type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = _expenses.fold<double>(0, (s, e) => s + (e['amount'] ?? 0).toDouble());

    return Scaffold(
      backgroundColor: const Color(0xFFF3ECF1),
      appBar: AppBar(
        title: Text('Your Expenses', style: px(9)),
        backgroundColor: const Color(0xFFF3ECF1),
        elevation: 0,
        actions: [
          IconButton(onPressed: _load, icon: Icon(Icons.refresh, color: cs.primary)),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF6E7EF), Color(0xFFF3ECF1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_graph_outlined, color: cs.secondary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Total: \$${total.toStringAsFixed(2)}',
                          style: px(9, color: cs.primary, weight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_expenses.isEmpty)
                Text('No expenses yet.', style: px(7, color: Colors.black45)),
              for (final e in _expenses)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shopping_bag_outlined, color: cs.secondary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e['description'] ?? e['type'] ?? '', style: px(8, weight: FontWeight.bold)),
                            const SizedBox(height: 3),
                            Text(e['type'] ?? '', style: px(6, color: Colors.black45)),
                          ],
                        ),
                      ),
                      Text('-\$${(e['amount'] ?? 0).toStringAsFixed(2)}',
                          style: px(8, color: const Color(0xFFB33B6C), weight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ══════════════════════════════════════════════════════════════
   CALCULATOR
══════════════════════════════════════════════════════════════ */

class _CuteCalcButton extends StatefulWidget {
  final String label;
  final Color bg;
  final Color fg;
  final double height;
  final VoidCallback? onTap;

  const _CuteCalcButton({
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
    this.height = 52,
  });

  @override
  State<_CuteCalcButton> createState() => _CuteCalcButtonState();
}

class _CuteCalcButtonState extends State<_CuteCalcButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.88),
        onTapUp: (_) => setState(() => _scale = 1.0),
        onTapCancel: () => setState(() => _scale = 1.0),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: Container(
            height: widget.height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.bg, widget.bg.withValues(alpha: 0.78)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: widget.bg.withValues(alpha: 0.45),
                  blurRadius: 8, offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(widget.label,
                style: px(9, color: widget.fg, weight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _display   = '0';
  String _input     = '';
  double? _operandA;
  String? _pendingOp;
  bool _freshResult = false;

  void _onNumber(String digit) {
    setState(() {
      if (_freshResult) { _input = ''; _freshResult = false; }
      if (digit == '.' && _input.contains('.')) return;
      if (_input.length >= 12) return;
      _input   = (_input == '0' && digit != '.') ? digit : _input + digit;
      _display = _input;
    });
  }

  void _onOperator(String op) {
    setState(() {
      _operandA    = double.tryParse(_input.isEmpty ? '0' : _input) ?? 0;
      _pendingOp   = op;
      _input       = '';
      _freshResult = false;
    });
  }

  void _onEquals() {
    if (_pendingOp == null || _operandA == null) return;
    final b = double.tryParse(_input.isEmpty ? '0' : _input) ?? 0;
    double r;
    switch (_pendingOp) {
      case '+': r = _operandA! + b; break;
      case '-': r = _operandA! - b; break;
      case '×': r = _operandA! * b; break;
      case '÷': r = b == 0 ? double.nan : _operandA! / b; break;
      default:  r = b;
    }
    setState(() {
      _display     = r.isNaN ? 'Error'
          : (r % 1 == 0 ? r.toInt().toString() : r.toStringAsFixed(2));
      _input       = _display;
      _operandA    = null;
      _pendingOp   = null;
      _freshResult = true;
    });
  }

  void _onPercent() {
    setState(() {
      final v   = double.tryParse(_input.isEmpty ? '0' : _input) ?? 0;
      final res = v / 100;
      _input    = res % 1 == 0 ? res.toInt().toString() : res.toStringAsFixed(4);
      _display  = _input;
    });
  }

  void _onCE() => setState(() { _input = '0'; _display = '0'; });

  void _onON() => setState(() {
    _display = '0'; _input = ''; _operandA = null; _pendingOp = null; _freshResult = false;
  });

  Widget _btn(String label,
      {Color? bg, Color? fg, int flex = 1, VoidCallback? onTap}) {
    return Expanded(
      flex: flex,
      child: _CuteCalcButton(
        label: label,
        bg: bg ?? const Color(0xFFB33B6C),
        fg: fg ?? Colors.white,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const pinkBody = Color(0xFFE9C9D6);
    const pinkDeep = Color(0xFFB33B6C);
    const mint     = Color(0xFF43C59E);
    const peach    = Color(0xFFFFD76A);
    const peachFg  = Color(0xFF8A5C16);
    const keyWhite = Colors.white;
    const keyText  = Color(0xFF8C2B4F);

    return Scaffold(
      backgroundColor: const Color(0xFFF3ECF1),
      appBar: AppBar(
        title: Text('Calculator', style: px(9)),
        backgroundColor: const Color(0xFFF3ECF1),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46, height: 46,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8C2B4F), Color(0xFFB33B6C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB33B6C).withValues(alpha: 0.4),
                        blurRadius: 12, offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🐻', style: TextStyle(fontSize: 22)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: pinkBody,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: pinkDeep.withValues(alpha: 0.25),
                        blurRadius: 18, offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: pinkDeep.withValues(alpha: 0.35), width: 1.5),
                        ),
                        child: Text(
                          _display,
                          textAlign: TextAlign.right,
                          style: px(14, color: pinkDeep, weight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(children: [
                        _btn('ON', bg: pinkDeep, fg: Colors.white, onTap: _onON),
                        _btn('CE', bg: mint,     fg: Colors.white, onTap: _onCE),
                        _btn('%',  bg: mint,     fg: Colors.white, onTap: _onPercent),
                        _btn('÷',  bg: peach,    fg: peachFg, onTap: () => _onOperator('÷')),
                      ]),
                      Row(children: [
                        _btn('7', bg: keyWhite, fg: keyText, onTap: () => _onNumber('7')),
                        _btn('8', bg: keyWhite, fg: keyText, onTap: () => _onNumber('8')),
                        _btn('9', bg: keyWhite, fg: keyText, onTap: () => _onNumber('9')),
                        _btn('×', bg: keyWhite, fg: keyText, onTap: () => _onOperator('×')),
                      ]),
                      Row(children: [
                        _btn('4', bg: keyWhite, fg: keyText, onTap: () => _onNumber('4')),
                        _btn('5', bg: keyWhite, fg: keyText, onTap: () => _onNumber('5')),
                        _btn('6', bg: keyWhite, fg: keyText, onTap: () => _onNumber('6')),
                        _btn('-', bg: keyWhite, fg: keyText, onTap: () => _onOperator('-')),
                      ]),
                      IntrinsicHeight(
                        child: Row(children: [
                          _btn('1', bg: keyWhite, fg: keyText, onTap: () => _onNumber('1')),
                          _btn('2', bg: keyWhite, fg: keyText, onTap: () => _onNumber('2')),
                          _btn('3', bg: keyWhite, fg: keyText, onTap: () => _onNumber('3')),
                          Expanded(
                            child: _CuteCalcButton(
                              label: '+',
                              bg: mint,
                              fg: Colors.white,
                              height: 112,
                              onTap: () => _onOperator('+'),
                            ),
                          ),
                        ]),
                      ),
                      Row(children: [
                        _btn('0', bg: keyWhite, fg: keyText, onTap: () => _onNumber('0')),
                        _btn('.', bg: keyWhite, fg: keyText, onTap: () => _onNumber('.')),
                        _btn('=', bg: keyWhite, fg: keyText, onTap: _onEquals),
                        const Expanded(child: SizedBox()),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ══════════════════════════════════════════════════════════════
   WISH LIST
══════════════════════════════════════════════════════════════ */

class WishListPage extends StatefulWidget {
  const WishListPage({super.key});

  @override
  State<WishListPage> createState() => _WishListPageState();
}

class _WishListPageState extends State<WishListPage> {
  final _name   = TextEditingController();
  final _target = TextEditingController();

  List<dynamic> _wishes = [];
  bool _loading = true;
  double _balance = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final kidId = AppData.currentUid!;
      final wishes = await ApiService.getWishlist(kidId);
      final balance = await ApiService.getApproxBalance(kidId);
      if (!mounted) return;
      setState(() {
        _wishes = wishes;
        _balance = balance;
      });
    } catch (e) {
      if (!mounted) return;
      showCuteNotification(context, 'Could not load wish list: $e', type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addWish() async {
    final name   = _name.text.trim();
    final target = double.tryParse(_target.text.trim());
    if (name.isEmpty || target == null || target <= 0) {
      showCuteNotification(context, 'Enter a wish name and valid amount',
          type: NotificationType.error);
      return;
    }
    try {
      await ApiService.addWish(kidId: AppData.currentUid!, itemName: name, price: target);
      _name.clear();
      _target.clear();
      _loadAll();
    } catch (e) {
      showCuteNotification(context, 'Failed: $e', type: NotificationType.error);
    }
  }

  Future<void> _confirmDeleteWish(String? itemId, String name) async {
    if (itemId == null) {
      showCuteNotification(context, 'Could not delete this wish', type: NotificationType.error);
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFF3ECF1),
        title: Text('Delete wish?', style: px(9)),
        content: Text('Are you sure you want to remove "$name"?', style: px(7)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: px(7, color: Colors.black45)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: px(7, color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.deleteWish(itemId);
      if (!mounted) return;
      showCuteNotification(context, 'Wish removed 🗑️', type: NotificationType.success);
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      showCuteNotification(context, 'Failed: $e', type: NotificationType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF3ECF1),
      appBar: AppBar(
        title: Text('Wish List', style: px(9)),
        backgroundColor: const Color(0xFFF3ECF1),
        elevation: 0,
        actions: [
          IconButton(onPressed: _loadAll, icon: Icon(Icons.refresh, color: cs.primary)),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Text('Add a new wish', style: px(8, weight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _name,
                style: px(8),
                decoration: InputDecoration(
                  labelText: 'Wish name', labelStyle: px(7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _target,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: px(8),
                decoration: InputDecoration(
                  labelText: 'Target amount', labelStyle: px(7), prefixText: '\$ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB33B6C),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _addWish,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text('Add', style: px(8, color: Colors.white)),
              ),
              const SizedBox(height: 20),
              Text('Your wishes', style: px(8, weight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (_wishes.isEmpty)
                Text('No wishes yet.', style: px(7, color: Colors.black45)),
              for (final w in _wishes)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFB33B6C).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.favorite_border, color: cs.tertiary, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(w['itemName'] ?? '', style: px(8, weight: FontWeight.bold)),
                      ),
                      Text('\$${(w['price'] ?? 0).toStringAsFixed(2)}',
                          style: px(7, color: const Color(0xFFB33B6C), weight: FontWeight.bold)),
                      IconButton(
                        onPressed: () => _confirmDeleteWish(
                            (w['itemId'] ?? w['id'])?.toString(), w['itemName'] ?? 'this wish'),
                        tooltip: 'Delete wish',
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              Text('Balance: \$${_balance.toStringAsFixed(2)}',
                  style: px(7, color: cs.primary)),
            ],
          ),
        ),
      ),
    );
  }
}