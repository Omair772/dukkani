import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'firebase_options.dart';

// --- 1. نموذج البيانات (Models) ---

class Product {
  final String id;
  final String name;
  final String category;
  final String imagePath;
  final String description;
  final double price;
  bool isFavorite;

  Product({
    required this.id, required this.name, required this.category,
    required this.imagePath, required this.price, this.description = "", this.isFavorite = false,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['title'] ?? '',
      category: data['category'] ?? '',
      imagePath: data['image'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['title'] ?? '',
      category: json['category'] ?? '',
      imagePath: json['image'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'title': name, 'category': category, 'image': imagePath, 'description': description, 'price': price, 'isFavorite': isFavorite,
  };
}

class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});

  Map<String, dynamic> toJson() => {'product': product.toJson(), 'quantity': quantity};
  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(product: Product.fromJson(json['product']), quantity: json['quantity']);
}

// --- 2. إدارة الحالة (Provider) ---

class DukaniProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<CartItem> _cart = [];
  List<String> _favoriteIds = [];

  bool _isLoading = true;
  String _selectedCategory = '';

  List<Product> get products => _products;
  List<CartItem> get cart => _cart;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  List<Product> get favoriteProducts => _products.where((p) => p.isFavorite).toList();

  DukaniProvider() {
    _initLocalData();
    fetchProductsFromFirestore();
  }

  Future<void> _initLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedFavs = prefs.getString('fav_ids');
    if (savedFavs != null) _favoriteIds = List<String>.from(json.decode(savedFavs));

    final String? savedCart = prefs.getString('cart_data');
    if (savedCart != null) {
      final List<dynamic> cartJson = json.decode(savedCart);
      _cart = cartJson.map((item) => CartItem.fromJson(item)).toList();
    }
  }

  void fetchProductsFromFirestore() {
    FirebaseFirestore.instance.collection('products').snapshots().listen((snapshot) {
      _products = snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
      for (var p in _products) {
        if (_favoriteIds.contains(p.id)) p.isFavorite = true;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _saveCartToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cart_data', json.encode(_cart.map((item) => item.toJson()).toList()));
  }

  void selectCategory(String categoryName) {
    _selectedCategory = categoryName;
    notifyListeners();
  }

  Future<void> toggleFavorite(String productId) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      _products[index].isFavorite = !_products[index].isFavorite;
      _products[index].isFavorite ? _favoriteIds.add(productId) : _favoriteIds.remove(productId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fav_ids', json.encode(_favoriteIds));
      notifyListeners();
    }
  }

  void addToCart(Product product) {
    final index = _cart.indexWhere((item) => item.product.id == product.id);
    index != -1 ? _cart[index].quantity++ : _cart.add(CartItem(product: product));
    _saveCartToPrefs();
    notifyListeners();
  }

  void incrementQuantity(String productId) {
    final index = _cart.indexWhere((item) => item.product.id == productId);
    if (index != -1) { _cart[index].quantity++; _saveCartToPrefs(); notifyListeners(); }
  }

  void decrementQuantity(String productId) {
    final index = _cart.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      if (_cart[index].quantity > 1) { _cart[index].quantity--; } else { _cart.removeAt(index); }
      _saveCartToPrefs(); notifyListeners();
    }
  }

  double get cartTotal => _cart.fold(0, (sum, item) => sum + (item.product.price * item.quantity));

  Future<void> placeOrder() async {
    if (_cart.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('orders').add({
      'userId': user?.uid,
      'userName': user?.displayName ?? 'عميل',
      'email': user?.email,
      'total': cartTotal,
      'items': _cart.map((item) => {'name': item.product.name, 'quantity': item.quantity, 'price': item.product.price}).toList(),
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'قيد الانتظار',
    });
    _cart.clear();
    await _saveCartToPrefs();
    notifyListeners();
  }
}

// --- 3. التهيئة والسمات ---

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(create: (context) => DukaniProvider(), child: const DukaniApp()),
  );
}

class DukaniApp extends StatelessWidget {
  const DukaniApp({super.key});
  static const Color neonPurple = Color(0xFFD500F9);
  static const Color neonBlue = Color(0xFF00E5FF);
  static const Color darkBg = Color(0xFF0A0E17);
  static const Color darkCard = Color(0xFF141A29);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'دكاني',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: darkBg, primaryColor: neonPurple,
        appBarTheme: const AppBarTheme(backgroundColor: darkBg, elevation: 0),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: darkCard, selectedItemColor: neonPurple, unselectedItemColor: Colors.grey,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

bool checkAuth(BuildContext context) {
  if (FirebaseAuth.instance.currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى تسجيل الدخول أولاً! 🔒', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
    return false;
  }
  return true;
}

// --- 4. شاشة التنقل الرئيسية ---

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [const HomeScreen(), const FavoritesScreen(), const CartScreen(), const AuthScreen()];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DukaniProvider>();
    return Scaffold(
      body: Directionality(textDirection: TextDirection.rtl, child: _pages[_selectedIndex]),
      bottomNavigationBar: Directionality(
        textDirection: TextDirection.rtl,
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Badge(label: Text(provider.favoriteProducts.length.toString()), isLabelVisible: provider.favoriteProducts.isNotEmpty, child: const Icon(Icons.favorite)), label: 'المفضلة'),
            BottomNavigationBarItem(icon: Badge(label: Text(provider.cart.length.toString()), isLabelVisible: provider.cart.isNotEmpty, backgroundColor: DukaniApp.neonBlue, textColor: Colors.black, child: const Icon(Icons.shopping_cart)), label: 'السلة'),
            const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
          ],
        ),
      ),
    );
  }
}

// --- 5. شاشات الحساب وملف المستخدم ---

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasData) return const UserProfileScreen();
        return isLogin ? LoginScreen(onToggle: () => setState(() => isLogin = false)) : SignUpScreen(onToggle: () => setState(() => isLogin = true));
      },
    );
  }
}

class LoginScreen extends StatelessWidget {
  final VoidCallback onToggle;
  LoginScreen({super.key, required this.onToggle});
  final _email = TextEditingController(); final _password = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.lock_person_outlined, size: 80, color: DukaniApp.neonBlue), const SizedBox(height: 20),
      TextField(controller: _email, decoration: const InputDecoration(hintText: 'البريد', filled: true, fillColor: DukaniApp.darkCard)), const SizedBox(height: 15),
      TextField(controller: _password, obscureText: true, decoration: const InputDecoration(hintText: 'كلمة المرور', filled: true, fillColor: DukaniApp.darkCard)), const SizedBox(height: 20),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: DukaniApp.neonBlue, minimumSize: const Size(double.infinity, 50)), onPressed: () => FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text.trim(), password: _password.text.trim()), child: const Text('دخول', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
      TextButton(onPressed: onToggle, child: const Text('إنشاء حساب جديد', style: TextStyle(color: DukaniApp.neonPurple))),
    ])));
  }
}

class SignUpScreen extends StatelessWidget {
  final VoidCallback onToggle;
  SignUpScreen({super.key, required this.onToggle});
  final _name = TextEditingController(); final _email = TextEditingController(); final _password = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.person_add_alt_1, size: 80, color: DukaniApp.neonPurple), const SizedBox(height: 20),
      TextField(controller: _name, decoration: const InputDecoration(hintText: 'الاسم', filled: true, fillColor: DukaniApp.darkCard)), const SizedBox(height: 15),
      TextField(controller: _email, decoration: const InputDecoration(hintText: 'البريد', filled: true, fillColor: DukaniApp.darkCard)), const SizedBox(height: 15),
      TextField(controller: _password, obscureText: true, decoration: const InputDecoration(hintText: 'كلمة المرور', filled: true, fillColor: DukaniApp.darkCard)), const SizedBox(height: 20),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: DukaniApp.neonPurple, minimumSize: const Size(double.infinity, 50)), onPressed: () async { UserCredential u = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _password.text.trim()); u.user?.updateDisplayName(_name.text.trim()); }, child: const Text('إنشاء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      TextButton(onPressed: onToggle, child: const Text('لدي حساب', style: TextStyle(color: DukaniApp.neonBlue))),
    ])));
  }
}

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // ⚠️⚠️⚠️ انتبه هنا: ضع الإيميل اللي سجلت فيه أنت ليكون هو إيميل المدير!
    final bool isAdmin = user?.email == 'omair@admin.com';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle, size: 100, color: DukaniApp.neonBlue), const SizedBox(height: 20),
          Text(user?.displayName ?? 'مستخدم دكاني', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(user?.email ?? '', style: const TextStyle(color: Colors.grey)), const SizedBox(height: 40),

          if (isAdmin) ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, minimumSize: const Size(200, 50)),
              icon: const Icon(Icons.dashboard_customize), label: const Text('لوحة تحكم الإدارة ⚙️', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen())),
            ),
            const SizedBox(height: 20),
          ],

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), foregroundColor: Colors.red, minimumSize: const Size(200, 50)),
            icon: const Icon(Icons.logout), label: const Text('تسجيل الخروج'),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
          const SizedBox(height: 50),
          const Text('Made with ❤️ by', style: TextStyle(color: Colors.grey, fontSize: 14)),
          Text('Eng. OmairSadeq Aldedaa', style: TextStyle(color: DukaniApp.neonBlue.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// --- 6. لوحة تحكم المدير ---

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('إدارة دكاني 🛡️', style: TextStyle(color: DukaniApp.neonPurple, fontWeight: FontWeight.bold)),
            bottom: const TabBar(
              indicatorColor: DukaniApp.neonBlue,
              tabs: [Tab(icon: Icon(Icons.list), text: 'المنتجات'), Tab(icon: Icon(Icons.add_box), text: 'إضافة'), Tab(icon: Icon(Icons.receipt_long), text: 'المبيعات')],
            ),
          ),
          body: const TabBarView(
            children: [AdminProductsTab(), AdminAddProductTab(), AdminOrdersTab()],
          ),
        ),
      ),
    );
  }
}

class AdminProductsTab extends StatefulWidget {
  const AdminProductsTab({super.key});
  @override
  State<AdminProductsTab> createState() => _AdminProductsTabState();
}

class _AdminProductsTabState extends State<AdminProductsTab> {
  bool isImporting = false;

  // 🚀 الزر السحري: استيراد البيانات من API القديم إلى Firestore
  Future<void> importFromApi() async {
    setState(() => isImporting = true);
    try {
      final response = await http.get(Uri.parse('https://gist.githubusercontent.com/Omair772/b67e36ad77580c9cba511ebaa7bddc5b/raw/1eb9d12273e9357aa4284762b869b1b3f5f45c07/dukani.json'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        for (var item in data) {
          await FirebaseFirestore.instance.collection('products').add({
            'title': item['title'] ?? '',
            'category': item['category'] ?? '',
            'image': item['image'] ?? '',
            'description': item['description'] ?? '',
            'price': (item['price'] ?? 0).toDouble(),
          });
        }
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم استيراد جميع المنتجات بنجاح! 🎉'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الاستيراد'), backgroundColor: Colors.red));
    }
    setState(() => isImporting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: DukaniApp.neonBlue, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 50)),
            icon: isImporting ? const CircularProgressIndicator(color: Colors.black) : const Icon(Icons.cloud_download),
            label: Text(isImporting ? 'جاري الاستيراد...' : 'استيراد المنتجات القديمة من API 🚀', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            onPressed: isImporting ? null : importFromApi,
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('products').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Center(child: Text('لا توجد منتجات، اضغط على زر الاستيراد 👆'));
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    color: DukaniApp.darkCard, margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: DukaniApp.darkBg, child: Icon(Icons.fastfood, color: DukaniApp.neonPurple)),
                      title: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${data['price']} ر.ي', style: const TextStyle(color: DukaniApp.neonBlue)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _editProductDialog(context, doc)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => FirebaseFirestore.instance.collection('products').doc(doc.id).delete()),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _editProductDialog(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final priceCtrl = TextEditingController(text: data['price'].toString());
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: DukaniApp.darkCard, title: const Text('تعديل السعر', textDirection: TextDirection.rtl),
      content: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(filled: true, fillColor: DukaniApp.darkBg)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () {
          FirebaseFirestore.instance.collection('products').doc(doc.id).update({'price': double.parse(priceCtrl.text)});
          Navigator.pop(context);
        }, style: ElevatedButton.styleFrom(backgroundColor: DukaniApp.neonBlue), child: const Text('حفظ', style: TextStyle(color: Colors.black))),
      ],
    ));
  }
}

class AdminAddProductTab extends StatefulWidget { const AdminAddProductTab({super.key}); @override State<AdminAddProductTab> createState() => _AdminAddProductTabState(); }
class _AdminAddProductTabState extends State<AdminAddProductTab> {
  final _title = TextEditingController(); final _desc = TextEditingController(); final _price = TextEditingController(); final _image = TextEditingController();
  String _category = 'وجبات خفيفة';
  bool _isLoading = false;
  Future<void> _addProduct() async {
    setState(() => _isLoading = true);
    await FirebaseFirestore.instance.collection('products').add({'title': _title.text.trim(), 'description': _desc.text.trim(), 'price': double.tryParse(_price.text.trim()) ?? 0.0, 'image': _image.text.trim(), 'category': _category});
    setState(() => _isLoading = false);
    _title.clear(); _desc.clear(); _price.clear(); _image.clear();
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة المنتج بنجاح ✅', textDirection: TextDirection.rtl), backgroundColor: Colors.green));
  }
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'اسم المنتج', filled: true, fillColor: DukaniApp.darkCard)), const SizedBox(height: 10),
          TextField(controller: _price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعر', filled: true, fillColor: DukaniApp.darkCard)), const SizedBox(height: 10),
          TextField(controller: _image, decoration: const InputDecoration(labelText: 'رابط الصورة', filled: true, fillColor: DukaniApp.darkCard)), const SizedBox(height: 10),
          TextField(controller: _desc, maxLines: 3, decoration: const InputDecoration(labelText: 'الوصف', filled: true, fillColor: DukaniApp.darkCard)), const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _category, decoration: const InputDecoration(filled: true, fillColor: DukaniApp.darkCard),
            items: ['وجبات خفيفة', 'عصائر', 'سلاشات', 'وجبات حارقة'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (val) => setState(() => _category = val!),
          ), const SizedBox(height: 30),
          _isLoading ? const CircularProgressIndicator() : ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: DukaniApp.neonPurple, minimumSize: const Size(double.infinity, 55)), onPressed: _addProduct, child: const Text('إضافة لقاعدة البيانات', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))
        ],
      ),
    );
  }
}

class AdminOrdersTab extends StatelessWidget {
  const AdminOrdersTab({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('لا توجد مبيعات حتى الآن'));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final items = data['items'] as List<dynamic>;
            return Card(
              color: DukaniApp.darkCard, margin: const EdgeInsets.all(8),
              child: ExpansionTile(
                leading: const Icon(Icons.receipt_long, color: DukaniApp.neonPurple),
                title: Text('طلب من: ${data['userName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('الإجمالي: ${data['total']} ر.ي', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                children: items.map((item) => ListTile(title: Text(item['name']), trailing: Text('الكمية: ${item['quantity']}'))).toList(),
              ),
            );
          },
        );
      },
    );
  }
}

// --- 7. الشاشة الرئيسية وبطاقات المنتجات (التصميم الفاخر الأصلي) ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isCategorySelected = false;
  final List<Map<String, dynamic>> mainCategories = [
    {'n': 'وجبات خفيفة', 'c': DukaniApp.neonBlue, 'i': Icons.fastfood},
    {'n': 'عصائر', 'c': Colors.orange, 'i': Icons.local_drink},
    {'n': 'سلاشات', 'c': Colors.yellow, 'i': Icons.icecream},
    {'n': 'وجبات حارقة', 'c': DukaniApp.neonPurple, 'i': Icons.local_fire_department},
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DukaniProvider>(context);
    final categoryProducts = provider.products.where((p) => p.category == provider.selectedCategory).toList();

    return Column(
      children: [
        const SizedBox(height: 50),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: SizedBox(
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isCategorySelected)
                  Align(alignment: Alignment.centerRight, child: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => setState(() => isCategorySelected = false))),
                Align(alignment: Alignment.center, child: Text(isCategorySelected ? provider.selectedCategory : 'دكاني 👋', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: DukaniApp.neonPurple))
              : AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: !isCategorySelected
                ? GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 20, mainAxisSpacing: 20),
              itemCount: mainCategories.length,
              itemBuilder: (context, index) {
                final cat = mainCategories[index];
                return GestureDetector(
                  onTap: () { provider.selectCategory(cat['n']); setState(() => isCategorySelected = true); },
                  child: GlowingNeonBorder(color: cat['c'], child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(cat['i'], size: 50, color: cat['c']), const SizedBox(height: 10), Text(cat['n'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cat['c']))])),
                );
              },
            )
                : categoryProducts.isEmpty
                ? const Center(child: Text('لا توجد منتجات في هذا القسم', style: TextStyle(fontSize: 18, color: Colors.grey)))
                : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.65),
              itemCount: categoryProducts.length,
              itemBuilder: (context, index) => ProductCard(product: categoryProducts[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class GlowingNeonBorder extends StatelessWidget {
  final Widget child; final Color color;
  const GlowingNeonBorder({super.key, required this.child, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container( decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, spreadRadius: 1)]), child: Container(decoration: BoxDecoration(color: DukaniApp.darkCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.8), width: 2)), child: child));
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<DukaniProvider>(context, listen: false);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product))),
      child: Container(
        decoration: BoxDecoration(color: DukaniApp.darkCard, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
        child: Column(
            children: [
              Expanded(
                  child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Hero(
                          tag: product.id,
                          child: product.imagePath.startsWith('http')
                              ? Image.network(product.imagePath, fit: BoxFit.contain)
                              : Image.asset(product.imagePath, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.fastfood, size: 50, color: Colors.grey))
                      )
                  )
              ),
              Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('${product.price.toInt()} ر.ي', style: const TextStyle(color: DukaniApp.neonBlue)),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(icon: Icon(product.isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red), onPressed: () { if(checkAuth(context)) p.toggleFavorite(product.id); }),
                    IconButton(icon: const Icon(Icons.add_shopping_cart, color: DukaniApp.neonBlue), onPressed: () { if(checkAuth(context)) p.addToCart(product); }),
                  ]
              )
            ]
        ),
      ),
    );
  }
}

// --- 8. شاشة التفاصيل الفاخرة ---

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DukaniProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: DukaniApp.darkBg,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 420, pinned: true, stretch: true, backgroundColor: DukaniApp.darkCard, iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(decoration: BoxDecoration(gradient: RadialGradient(center: Alignment.center, radius: 0.8, colors: [DukaniApp.neonPurple.withOpacity(0.15), DukaniApp.darkBg]))),
                    Hero(tag: product.id, child: Padding(padding: const EdgeInsets.all(40.0), child: product.imagePath.startsWith('http') ? Image.network(product.imagePath, fit: BoxFit.contain) : Image.asset(product.imagePath, fit: BoxFit.contain))),
                    const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, DukaniApp.darkBg], stops: [0.6, 1.0])))),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(product.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.2))),
                        Text('${product.price.toInt()} ر.ي', style: const TextStyle(fontSize: 28, color: DukaniApp.neonBlue, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: DukaniApp.darkCard.withOpacity(0.5), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(children: const [Icon(Icons.star_rounded, color: Colors.amber, size: 28), SizedBox(height: 8), Text("4.8", style: TextStyle(fontSize: 14, color: Colors.grey))]),
                          Container(height: 30, width: 1, color: Colors.white10),
                          Column(children: const [Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 28), SizedBox(height: 8), Text("حار", style: TextStyle(fontSize: 14, color: Colors.grey))]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 35),
                    const Text("عن هذه الوجبة", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 15),
                    Text(product.description, style: TextStyle(fontSize: 17, color: Colors.white.withOpacity(0.7), height: 1.8)),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 30), color: DukaniApp.darkBg,
        child: InkWell(
          onTap: () {
            if(checkAuth(context)){
              provider.addToCart(product);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تمت الإضافة للسلة بنجاح 🛍️", textDirection: TextDirection.rtl), backgroundColor: Colors.green));
            }
          },
          child: Container(
            height: 65,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [DukaniApp.neonPurple, Color(0xFF9C27B0)]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: DukaniApp.neonPurple.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))]),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 26), SizedBox(width: 12), Text("أضف إلى السلة", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))]),
          ),
        ),
      ),
    );
  }
}

// --- 9. شاشة السلة والمفضلة ---

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) return const Center(child: Text('سجل الدخول لعرض المفضلة 🔒', style: TextStyle(fontSize: 18)));
    final favs = Provider.of<DukaniProvider>(context).favoriteProducts;
    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة ❤️')),
      body: favs.isEmpty ? const Center(child: Text('المفضلة فارغة')) : GridView.builder(padding: const EdgeInsets.all(16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.65), itemCount: favs.length, itemBuilder: (context, index) => ProductCard(product: favs[index])),
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) return const Center(child: Text('سجل الدخول لعرض السلة 🔒', style: TextStyle(fontSize: 18)));
    final p = Provider.of<DukaniProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('السلة 🛒')),
      body: p.cart.isEmpty ? const Center(child: Text('السلة فارغة')) : Column(
        children: [
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.all(16), itemCount: p.cart.length,
            itemBuilder: (context, index) {
              final item = p.cart[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: DukaniApp.darkCard, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  item.product.imagePath.startsWith('http') ? Image.network(item.product.imagePath, width: 60, height: 60) : Image.asset(item.product.imagePath, width: 60, height: 60, errorBuilder: (c, e, s) => const Icon(Icons.fastfood, color: Colors.grey)),
                  const SizedBox(width: 15),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)), Text('${item.product.price.toInt()} ر.ي', style: const TextStyle(color: DukaniApp.neonBlue))])),
                  Row(children: [
                    IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.orange), onPressed: () => p.decrementQuantity(item.product.id)),
                    Text('${item.quantity}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.green), onPressed: () => p.incrementQuantity(item.product.id)),
                  ]),
                ]),
              );
            },
          )),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: DukaniApp.neonPurple, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: () {
                p.placeOrder();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الطلب بنجاح! 🎉', textDirection: TextDirection.rtl), backgroundColor: Colors.green));
              },
              child: Text('إكمال الطلب (${p.cartTotal.toInt()} ر.ي)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          )
        ],
      ),
    );
  }
}
