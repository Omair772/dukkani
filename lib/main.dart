import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
    required this.id,
    required this.name,
    required this.category,
    required this.imagePath,
    required this.price,
    this.description = "",
    this.isFavorite = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['title'] ?? '',
      category: json['category'] ?? '',
      imagePath: json['image'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': name,
    'category': category,
    'image': imagePath,
    'description': description,
    'price': price,
  };
}

class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    product: Product.fromJson(json['product']),
    quantity: json['quantity'],
  );
}

// --- 2. إدارة الحالة (Provider) ---

class DukaniProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<CartItem> _cart = [];
  List<String> _favoriteIds = [];

  bool _isLoading = true;
  bool _isOffline = false;
  String _selectedCategory = '';

  List<Product> get products => _products;
  List<CartItem> get cart => _cart;
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  String get selectedCategory => _selectedCategory;
  List<Product> get favoriteProducts => _products.where((p) => p.isFavorite).toList();

  DukaniProvider() {
    fetchData();
  }

  Future<void> fetchData() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    // تحميل المفضلة والسلة المحفوظة
    final String? savedFavs = prefs.getString('fav_ids');
    if (savedFavs != null) {
      _favoriteIds = List<String>.from(json.decode(savedFavs));
    }

    final String? savedCart = prefs.getString('cart_data');
    if (savedCart != null) {
      final List<dynamic> cartJson = json.decode(savedCart);
      _cart = cartJson.map((item) => CartItem.fromJson(item)).toList();
    }

    try {
      final response = await http.get(Uri.parse('https://gist.githubusercontent.com/Omair772/b67e36ad77580c9cba511ebaa7bddc5b/raw/1eb9d12273e9357aa4284762b869b1b3f5f45c07/dukani.json'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        _products = jsonData.map((data) => Product.fromJson(data)).toList();
        await prefs.setString('cached_data', response.body);
        _isOffline = false;
      }
    } catch (e) {
      _isOffline = true;
      final String? cachedData = prefs.getString('cached_data');
      if (cachedData != null) {
        final List<dynamic> jsonData = json.decode(cachedData);
        _products = jsonData.map((data) => Product.fromJson(data)).toList();
      }
    }

    for (var p in _products) {
      if (_favoriteIds.contains(p.id)) p.isFavorite = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveCartToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String cartJson = json.encode(_cart.map((item) => item.toJson()).toList());
    await prefs.setString('cart_data', cartJson);
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
    if (index != -1) {
      _cart[index].quantity++;
      _saveCartToPrefs();
      notifyListeners();
    }
  }

  void decrementQuantity(String productId) {
    final index = _cart.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      if (_cart[index].quantity > 1) {
        _cart[index].quantity--;
      } else {
        _cart.removeAt(index);
      }
      _saveCartToPrefs();
      notifyListeners();
    }
  }

  double get cartTotal => _cart.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
}

// --- 3. التطبيق والسمات ---

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => DukaniProvider(),
      child: const DukaniApp(),
    ),
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
        scaffoldBackgroundColor: darkBg,
        primaryColor: neonPurple,
        appBarTheme: const AppBarTheme(
          backgroundColor: darkBg,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: darkCard,
          selectedItemColor: neonPurple,
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// --- 4. شاشة التنقل الرئيسية ---

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const HomeScreen(),
    const FavoritesScreen(),
    const CartScreen(),
    const AuthScreen(),
  ];

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
            BottomNavigationBarItem(
              icon: Badge(
                label: Text(provider.favoriteProducts.length.toString()),
                isLabelVisible: provider.favoriteProducts.isNotEmpty,
                child: const Icon(Icons.favorite),
              ),
              label: 'المفضلة',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                label: Text(provider.cart.length.toString()),
                isLabelVisible: provider.cart.isNotEmpty,
                backgroundColor: DukaniApp.neonBlue,
                textColor: Colors.black,
                child: const Icon(Icons.shopping_cart),
              ),
              label: 'السلة',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
          ],
        ),
      ),
    );
  }
}

// --- 5. شاشة الحساب (AuthScreen) وإضافة حقوق النشر ---

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          const Spacer(),
          const Icon(Icons.account_circle, size: 100, color: DukaniApp.neonPurple),
          const SizedBox(height: 20),
          const Text(
            'أهلاً بك في دكاني',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'سجل دخولك لتتمكن من إتمام الطلبات ومتابعتها بكل سهولة',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DukaniApp.neonPurple,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () {},
            child: const Text('تسجيل الدخول', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
          ),
          const SizedBox(height: 15),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: DukaniApp.neonBlue),
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () {},
            child: const Text('إنشاء حساب جديد', style: TextStyle(color: DukaniApp.neonBlue, fontSize: 18)),
          ),
          const Spacer(),
          // قسم حقوق النشر والتصميم
          Column(
            children: [
              const Text(
                'Made with ❤️ by',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Eng. OmairSadeq Aldedaa',
                style: TextStyle(
                  color: DukaniApp.neonBlue.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 30),
            ],
          )
        ],
      ),
    );
  }
}

// --- 6. الشاشة الرئيسية (HomeScreen) ---

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
        if (provider.isOffline)
          Container(
            width: double.infinity, color: Colors.orange.shade800, padding: const EdgeInsets.symmetric(vertical: 4),
            child: const Center(child: Text('وضع عدم الاتصال: عرض البيانات المحفوظة محلياً', style: TextStyle(fontSize: 12))),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: SizedBox(
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isCategorySelected)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => setState(() => isCategorySelected = false)),
                  ),
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
        child: Column(children: [
          Expanded(child: Padding(padding: const EdgeInsets.all(8), child: Hero(tag: product.id, child: product.imagePath.startsWith('http') ? Image.network(product.imagePath, fit: BoxFit.contain) : Image.asset(product.imagePath, fit: BoxFit.contain)))),
          Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('${product.price.toInt()} ر.ي', style: const TextStyle(color: DukaniApp.neonBlue)),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            IconButton(icon: Icon(product.isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red), onPressed: () => p.toggleFavorite(product.id)),
            IconButton(icon: const Icon(Icons.add_shopping_cart, color: DukaniApp.neonBlue), onPressed: () => p.addToCart(product)),
          ])
        ]),
      ),
    );
  }
}

// --- 7. شاشة التفاصيل الفاخرة ---

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
              expandedHeight: 420,
              pinned: true,
              stretch: true,
              backgroundColor: DukaniApp.darkCard,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.8,
                          colors: [
                            DukaniApp.neonPurple.withOpacity(0.15),
                            DukaniApp.darkBg,
                          ],
                        ),
                      ),
                    ),
                    Hero(
                      tag: product.id,
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: product.imagePath.startsWith('http')
                            ? Image.network(product.imagePath, fit: BoxFit.contain)
                            : Image.asset(product.imagePath, fit: BoxFit.contain),
                      ),
                    ),
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, DukaniApp.darkBg],
                            stops: [0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
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
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                        ),
                        Text(
                          '${product.price.toInt()} ر.ي',
                          style: const TextStyle(fontSize: 28, color: DukaniApp.neonBlue, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: DukaniApp.darkCard.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoItem(Icons.star_rounded, "4.8", Colors.amber),
                          _buildVerticalDivider(),
                          _buildInfoItem(Icons.local_fire_department_rounded, "حار", Colors.orange),
                          _buildVerticalDivider(),
                          _buildInfoItem(Icons.timer_rounded, "15 دقيقة", DukaniApp.neonBlue),
                        ],
                      ),
                    ),
                    const SizedBox(height: 35),
                    const Text(
                      "عن هذه الوجبة",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white.withOpacity(0.7),
                        height: 1.8,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
        color: DukaniApp.darkBg,
        child: InkWell(
          onTap: () {
            provider.addToCart(product);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("تمت الإضافة للسلة بنجاح 🛍️"),
                duration: Duration(seconds: 2),
                backgroundColor: DukaniApp.darkCard,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Container(
            height: 65,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [DukaniApp.neonPurple, Color(0xFF9C27B0)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: DukaniApp.neonPurple.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 26),
                SizedBox(width: 12),
                Text(
                  "أضف إلى السلة",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: Colors.white10);
  }
}

// --- 8. شاشة المفضلة ---

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final favs = Provider.of<DukaniProvider>(context).favoriteProducts;
    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة ❤️')),
      body: favs.isEmpty
          ? const Center(child: Text('لا توجد منتجات في المفضلة', style: TextStyle(fontSize: 18)))
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.65,
        ),
        itemCount: favs.length,
        itemBuilder: (context, index) => ProductCard(product: favs[index]),
      ),
    );
  }
}

// --- 9. شاشة السلة ---

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Provider.of<DukaniProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('سلة التسوق 🛒')),
      body: p.cart.isEmpty
          ? const Center(child: Text('السلة فارغة حالياً', style: TextStyle(fontSize: 18)))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: p.cart.length,
              itemBuilder: (context, index) {
                final item = p.cart[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: DukaniApp.darkCard, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      item.product.imagePath.startsWith('http')
                          ? Image.network(item.product.imagePath, width: 60, height: 60)
                          : Image.asset(item.product.imagePath, width: 60, height: 60, errorBuilder: (c, e, s) => const Icon(Icons.fastfood, color: Colors.grey)),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${item.product.price.toInt()} ر.ي', style: const TextStyle(color: DukaniApp.neonBlue)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.orange), onPressed: () => p.decrementQuantity(item.product.id)),
                          Text('${item.quantity}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.green), onPressed: () => p.incrementQuantity(item.product.id)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DukaniApp.neonPurple,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () {},
              child: Text(
                'إكمال الطلب (${p.cartTotal.toInt()} ر.ي)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          )
        ],
      ),
    );
  }
}
