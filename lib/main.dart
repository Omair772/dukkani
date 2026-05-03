import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- 1. نموذج البيانات وإدارة الحالة (Provider) ---

class Product {
  final String id;
  final String name;
  final String category;
  final String imagePath;
  final double price;
  bool isFavorite;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.imagePath,
    required this.price,
    this.isFavorite = false,
  });
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class DukaniProvider extends ChangeNotifier {
  final List<Product> _products = [
    // --- وجبات خفيفة (10) ---
    Product(id: 's1', name: 'شيبس مشكل عائلي', category: 'وجبات خفيفة', imagePath: 'assets/images/chips.png', price: 500),
    Product(id: 's2', name: 'بسكويت مالح ديمة', category: 'وجبات خفيفة', imagePath: 'assets/images/cookies.png', price: 200),
    Product(id: 's3', name: 'فشار بالكراميل', category: 'وجبات خفيفة', imagePath: 'assets/images/popcorn.png', price: 300),
    Product(id: 's4', name: 'مكسرات مشكلة ربع', category: 'وجبات خفيفة', imagePath: 'assets/images/nuts.png', price: 1200),
    Product(id: 's5', name: 'كرواسون شوكولاتة', category: 'وجبات خفيفة', imagePath: 'assets/images/croissant.png', price: 450),
    Product(id: 's6', name: 'كيك بالفانيليا', category: 'وجبات خفيفة', imagePath: 'assets/images/cake.png', price: 350),
    Product(id: 's7', name: 'أصابع البطاطس حار', category: 'وجبات خفيفة', imagePath: 'assets/images/sticks.png', price: 250),
    Product(id: 's8', name: 'معمول بالتمر', category: 'وجبات خفيفة', imagePath: 'assets/images/maamoul.png', price: 600),
    Product(id: 's9', name: 'شوكولاتة جالاكسي', category: 'وجبات خفيفة', imagePath: 'assets/images/galaxy.png', price: 700),
    Product(id: 's10', name: 'علكة بالنعناع', category: 'وجبات خفيفة', imagePath: 'assets/images/gum.png', price: 100),

    // --- عصائر (10) ---
    Product(id: 'j1', name: 'عصير برتقال طازج', category: 'عصائر', imagePath: 'assets/images/orange.png', price: 800),
    Product(id: 'j2', name: 'كوكتيل فواكه', category: 'عصائر', imagePath: 'assets/images/cocktail.png', price: 1200),
    Product(id: 'j3', name: 'عصير مانجو مركز', category: 'عصائر', imagePath: 'assets/images/mango.png', price: 900),
    Product(id: 'j4', name: 'سموذي فراولة', category: 'عصائر', imagePath: 'assets/images/strawberry.png', price: 1100),
    Product(id: 'j5', name: 'ليمون بالنعناع', category: 'عصائر', imagePath: 'assets/images/lemon.png', price: 750),
    Product(id: 'j6', name: 'عصير جوافة طبيعي', category: 'عصائر', imagePath: 'assets/images/guava.png', price: 800),
    Product(id: 'j7', name: 'عصير رمان حامض', category: 'عصائر', imagePath: 'assets/images/pomegranate.png', price: 1500),
    Product(id: 'j8', name: 'حليب بالموز', category: 'عصائر', imagePath: 'assets/images/banana_milk.png', price: 850),
    Product(id: 'j9', name: 'عصير تفاح أخضر', category: 'عصائر', imagePath: 'assets/images/apple.png', price: 900),
    Product(id: 'j10', name: 'آيس تي خوخ', category: 'عصائر', imagePath: 'assets/images/ice_tea.png', price: 700),

    // --- سلاشات (10) ---
    Product(id: 'l1', name: 'سلاش توت أزرق', category: 'سلاشات', imagePath: 'assets/images/slush_blue.png', price: 700),
    Product(id: 'l2', name: 'سلاش بطيخ أحمر', category: 'سلاشات', imagePath: 'assets/images/slush_red.png', price: 700),
    Product(id: 'l3', name: 'سلاش ليمون بارد', category: 'سلاشات', imagePath: 'assets/images/slush_lemon.png', price: 600),
    Product(id: 'l4', name: 'سلاش فيمتو أصلي', category: 'سلاشات', imagePath: 'assets/images/slush_vimto.png', price: 800),
    Product(id: 'l5', name: 'سلاش كرز منعش', category: 'سلاشات', imagePath: 'assets/images/slush_cherry.png', price: 750),
    Product(id: 'l6', name: 'سلاش عنب بارد', category: 'سلاشات', imagePath: 'assets/images/slush_grape.png', price: 700),
    Product(id: 'l7', name: 'سلاش برتقال مثلج', category: 'سلاشات', imagePath: 'assets/images/slush_orange.png', price: 650),
    Product(id: 'l8', name: 'سلاش أناناس ذهبي', category: 'سلاشات', imagePath: 'assets/images/slush_pineapple.png', price: 800),
    Product(id: 'l9', name: 'سلاش كولا غازي', category: 'سلاشات', imagePath: 'assets/images/slush_cola.png', price: 600),
    Product(id: 'l10', name: 'سلاش قوس قزح مشكل', category: 'سلاشات', imagePath: 'assets/images/slush_rainbow.png', price: 1000),

    // --- وجبات حارقة (10) ---
    Product(id: 'f1', name: 'برجر التنين الناري', category: 'وجبات حارقة', imagePath: 'assets/images/burger.png', price: 2500),
    Product(id: 'f2', name: 'باستا ديابلو حارة', category: 'وجبات حارقة', imagePath: 'assets/images/pasta.png', price: 2200),
    Product(id: 'f3', name: 'أجنحة دجاج بوفالو', category: 'وجبات حارقة', imagePath: 'assets/images/wings.png', price: 1800),
    Product(id: 'f4', name: 'زنجر حراق سوبر', category: 'وجبات حارقة', imagePath: 'assets/images/zinger.png', price: 1600),
    Product(id: 'f5', name: 'بطاطس تشيلي سبايسي', category: 'وجبات حارقة', imagePath: 'assets/images/chili_fries.png', price: 1300),
    Product(id: 'f6', name: 'بيتزا الهالبينو', category: 'وجبات حارقة', imagePath: 'assets/images/pizza_hot.png', price: 3500),
    Product(id: 'f7', name: 'تاكو مكسيكي ناري', category: 'وجبات حارقة', imagePath: 'assets/images/taco.png', price: 1400),
    Product(id: 'f8', name: 'رول دجاج فلفل', category: 'وجبات حارقة', imagePath: 'assets/images/chicken_roll.png', price: 1200),
    Product(id: 'f9', name: 'نودلز كوري x2 حراق', category: 'وجبات حارقة', imagePath: 'assets/images/noodles.png', price: 1100),
    Product(id: 'f10', name: 'ناجتس حراق جداً', category: 'وجبات حارقة', imagePath: 'assets/images/nuggets.png', price: 1400),
  ];

  String _selectedCategory = 'وجبات خفيفة';
  final List<CartItem> _cart = [];

  List<Product> get products => _products;
  String get selectedCategory => _selectedCategory;
  List<Product> get favoriteProducts => _products.where((p) => p.isFavorite).toList();
  List<CartItem> get cart => _cart;

  void selectCategory(String categoryName) {
    _selectedCategory = categoryName;
    notifyListeners();
  }

  void toggleFavorite(String productId) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      _products[index].isFavorite = !_products[index].isFavorite;
      notifyListeners();
    }
  }

  void addToCart(Product product) {
    final index = _cart.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      _cart[index].quantity++;
    } else {
      _cart.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void incrementQuantity(String productId) {
    final index = _cart.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      _cart[index].quantity++;
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
      notifyListeners();
    }
  }

  void removeFromCart(String productId) {
    _cart.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  double get cartTotal => _cart.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
}

// --- 2. التطبيق والسمات العامة ---

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

// --- 3. شاشة التنقل الرئيسية (Navigation) ---

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
    const Center(child: Text('حساب المستخدم')),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DukaniProvider>();

    return Scaffold(
      body: Directionality(textDirection: TextDirection.rtl, child: _pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
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
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'السلة',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }
}

// --- 4. شاشة المربعات الأربعة (HomeScreen) ---

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
        const SizedBox(height: 60),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              if (isCategorySelected)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => setState(() => isCategorySelected = false),
                ),
              Text(
                isCategorySelected ? provider.selectedCategory : 'دكاني 👋',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: !isCategorySelected
                ? GridView.builder(
              key: const ValueKey(1),
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: mainCategories.length,
              itemBuilder: (context, index) {
                final cat = mainCategories[index];
                return GestureDetector(
                  onTap: () {
                    provider.selectCategory(cat['n']);
                    setState(() => isCategorySelected = true);
                  },
                  child: GlowingNeonBorder(
                    color: cat['c'],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(cat['i'], size: 50, color: cat['c']),
                        const SizedBox(height: 10),
                        Text(cat['n'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cat['c'])),
                      ],
                    ),
                  ),
                );
              },
            )
                : GridView.builder(
              key: const ValueKey(2),
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.68, // تحسين النسبة لظهور السعر
              ),
              itemCount: categoryProducts.length,
              itemBuilder: (context, index) => ProductCard(product: categoryProducts[index]),
            ),
          ),
        ),
      ],
    );
  }
}

// --- 5. الويجت المساعدة (Neon Border, Product Card) ---

class GlowingNeonBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  const GlowingNeonBorder({super.key, required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, spreadRadius: 1)],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: DukaniApp.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.8), width: 2),
        ),
        child: child,
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<DukaniProvider>(context, listen: false);
    return Container(
      decoration: BoxDecoration(
        color: DukaniApp.darkCard,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                product.imagePath,
                errorBuilder: (c, e, s) => const Icon(Icons.fastfood, size: 50, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const SizedBox(height: 4),
          // إظهار السعر بوضوح
          Text(
            '${product.price.toInt()} ر.ي',
            style: const TextStyle(color: DukaniApp.neonBlue, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(product.isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red, size: 22),
                onPressed: () => p.toggleFavorite(product.id),
              ),
              IconButton(
                icon: const Icon(Icons.add_shopping_cart, color: DukaniApp.neonBlue, size: 22),
                onPressed: () => p.addToCart(product),
              ),
            ],
          )
        ],
      ),
    );
  }
}

// --- 6. شاشة المفضلة (FavoritesScreen) ---

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final favs = Provider.of<DukaniProvider>(context).favoriteProducts;
    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة ❤️')),
      body: favs.isEmpty
          ? const Center(child: Text('لا توجد منتجات في المفضلة'))
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.68,
        ),
        itemCount: favs.length,
        itemBuilder: (context, index) => ProductCard(product: favs[index]),
      ),
    );
  }
}

// --- 7. شاشة السلة (CartScreen) مع أزرار الكمية ---

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Provider.of<DukaniProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('سلة التسوق 🛒')),
      body: p.cart.isEmpty
          ? const Center(child: Text('السلة فارغة حالياً'))
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
                      Image.asset(item.product.imagePath, width: 60, height: 60, errorBuilder: (c, e, s) => const Icon(Icons.fastfood)),
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
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                            onPressed: () => p.decrementQuantity(item.product.id),
                          ),
                          Text('${item.quantity}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                            onPressed: () => p.incrementQuantity(item.product.id),
                          ),
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
              onPressed: () {
                // هنا يمكنك إضافة منطق الدفع
              },
              child: Text(
                'إكمال الطلب (${p.cartTotal.toInt()} ر.ي)',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          )
        ],
      ),
    );
  }
}