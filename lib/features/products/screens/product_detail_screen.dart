
// class ProductDetailScreen extends StatefulWidget {
//   final ProductModel product;

//   const ProductDetailScreen({super.key, required this.product});

//   @override
//   State<ProductDetailScreen> createState() => _ProductDetailScreenState();
// }

// class _ProductDetailScreenState extends State<ProductDetailScreen> {
//   int _currentImageIndex = 0;
//   int _quantity = 1;
//   bool _isFavourite = false;
//   late PageController _pageController;

//   @override
//   void initState() {
//     super.initState();
//     _pageController = PageController();
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }

//   List<_MediaItem> get _media {
//     final items = [
//       ...widget.product.images.map(
//           (e) => _MediaItem(type: _MediaType.image, url: e.image, id: e.id)),
//       ...widget.product.videos.map((e) => _MediaItem(
//           type: _MediaType.video,
//           url: e.video,
//           id: e.id,
//           thumbnail: e.thumbnail)),
//     ];
//     if (items.isEmpty) {
//       items.add(_MediaItem(
//           type: _MediaType.image,
//           url: AppConstants.kDefaultProductImage,
//           id: 0));
//     }
//     return items;
//   }

//   int get _discountPercent {
//     if (widget.product.discountPrice == null || widget.product.price <= 0) {
//       return 0;
//     }
//     return (((widget.product.price - widget.product.finalPrice) /
//                 widget.product.price) *
//             100)
//         .round();
//   }

//   bool get _inStock =>
//       widget.product.isAvailable && widget.product.stock > 0;

//   void _showAddedToCartSnackbar() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 2),
//         backgroundColor: AppColors.success,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         content: Row(
//           children: [
//             const Icon(Icons.check_circle_outline,
//                 color: AppColors.white, size: 20),
//             const SizedBox(width: 10),
//             Text(
//               '${widget.product.name} added to cart!',
//               style: const TextStyle(color: AppColors.white),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Returns true if the user is logged in. Otherwise pops open LoginScreen
//   /// and shows a gentle prompt, then returns false.
//   bool _requireLogin({required String action}) {
//     final auth = context.read<AuthController>();
//     if (auth.currentUser != null) return true;

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 2),
//         backgroundColor: AppColors.primary,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         content: Row(
//           children: [
//             const Icon(Icons.lock_outline_rounded,
//                 color: AppColors.white, size: 20),
//             const SizedBox(width: 10),
//             Text(
//               'Please log in to $action',
//               style: const TextStyle(color: AppColors.white),
//             ),
//           ],
//         ),
//       ),
//     );

//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const LoginScreen()),
//     );
//     return false;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final media = _media;

//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             stops: const [0.0, 0.4, 1.0],
//             colors: theme.brightness == Brightness.dark
//                 ? [
//                     const Color(0xFF2D2018),
//                     const Color(0xFF241C14),
//                     theme.scaffoldBackgroundColor,
//                   ]
//                 : [
//                     const Color(0xFFFAF0E4),
//                     const Color(0xFFFDF6EE),
//                     const Color(0xFFFDF8F3),
//                   ],
//           ),
//         ),
//         child: Column(
//           children: [
//             // ─── Scrollable Content ──────────────────────────────
//             Expanded(
//               child: CustomScrollView(
//                 physics: const BouncingScrollPhysics(),
//                 slivers: [
//                   // ── Gallery header (full-bleed) ──────────────
//                   SliverToBoxAdapter(
//                     child: Stack(
//                       children: [
//                         // ── Main Media ───────────────────────────
//                         SizedBox(
//                           height: 420,
//                           child: Stack(
//                             children: [
//                               PageView.builder(
//                                 controller: _pageController,
//                                 itemCount: media.length,
//                                 onPageChanged: (i) =>
//                                     setState(() => _currentImageIndex = i),
//                                 itemBuilder: (_, index) =>
//                                     _buildMediaView(media[index], theme),
//                               ),
//                               // Bottom smooth gradient for content transition
//                               Positioned(
//                                 left: 0,
//                                 right: 0,
//                                 bottom: 0,
//                                 child: Container(
//                                   height: 120,
//                                   decoration: BoxDecoration(
//                                     gradient: LinearGradient(
//                                       begin: Alignment.bottomCenter,
//                                       end: Alignment.topCenter,
//                                       colors: [
//                                         theme.scaffoldBackgroundColor
//                                             .withOpacity(0.8),
//                                         theme.scaffoldBackgroundColor
//                                             .withOpacity(0.4),
//                                         Colors.transparent,
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                                   // Discount badge
//                                   if (_discountPercent > 0)
//                                     Positioned(
//                                       bottom: 14,
//                                       left: 14,
//                                       child: Container(
//                                         padding: const EdgeInsets.symmetric(
//                                             horizontal: 10, vertical: 5),
//                                         decoration: BoxDecoration(
//                                           color: AppColors.error,
//                                           borderRadius:
//                                               BorderRadius.circular(8),
//                                           boxShadow: [
//                                             BoxShadow(
//                                               color: AppColors.error
//                                                   .withOpacity(0.4),
//                                               blurRadius: 8,
//                                               offset: const Offset(0, 3),
//                                             ),
//                                           ],
//                                         ),
//                                         child: Text(
//                                           '-$_discountPercent% OFF',
//                                           style: const TextStyle(
//                                             color: AppColors.white,
//                                             fontSize: 12,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   // Video tag
//                                   if (media[_currentImageIndex].type ==
//                                       _MediaType.video)
//                                     Positioned(
//                                       bottom: 14,
//                                       right: 14,
//                                       child: Container(
//                                         padding: const EdgeInsets.symmetric(
//                                             horizontal: 10, vertical: 5),
//                                         decoration: BoxDecoration(
//                                           color:
//                                               Colors.black.withOpacity(0.65),
//                                           borderRadius:
//                                               BorderRadius.circular(16),
//                                         ),
//                                         child: const Row(
//                                           children: [
//                                             Icon(Icons.play_circle_fill,
//                                                 color: AppColors.white,
//                                                 size: 13),
//                                             SizedBox(width: 4),
//                                             Text('Video',
//                                                 style: TextStyle(
//                                                     color: AppColors.white,
//                                                     fontSize: 11)),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                   // Dot indicators
//                                   if (media.length > 1)
//                                     Positioned(
//                                       bottom: 14,
//                                       left: 0,
//                                       right: 0,
//                                       child: Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.center,
//                                         children:
//                                             List.generate(media.length, (i) {
//                                           final active =
//                                               i == _currentImageIndex;
//                                           return AnimatedContainer(
//                                             duration: const Duration(
//                                                 milliseconds: 250),
//                                             margin: const EdgeInsets.symmetric(
//                                                 horizontal: 3),
//                                             width: active ? 18 : 7,
//                                             height: 7,
//                                             decoration: BoxDecoration(
//                                               color: active
//                                                   ? AppColors.white
//                                                   : AppColors.white
//                                                       .withOpacity(0.45),
//                                               borderRadius:
//                                                   BorderRadius.circular(4),
//                                             ),
//                                           );
//                                         }),
//                                       ),
//                                     ),
//                                 ],
//                               ),
//                             ),

//                           // ── Floating App Bar ─────────────────────
//                           Positioned(
//                             top: 10,
//                             left: 0,
//                             right: 0,
//                             child: SafeArea(
//                               child: Padding(
//                                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     _HeaderButton(
//                                       icon: Icons.arrow_back_ios_new,
//                                       onTap: () => Navigator.pop(context),
//                                       theme: theme,
//                                     ),
//                                     Row(
//                                       children: [
//                                         _HeaderButton(
//                                           icon: Icons.share_rounded,
//                                           onTap: () {
//                                             final text =
//                                                 '${widget.product.name}\nAED ${widget.product.finalPrice}\n\nCheck this out on UAE Ecom!';
//                                             Share.share(text);
//                                           },
//                                           theme: theme,
//                                         ),
//                                         const SizedBox(width: 12),
//                                         _HeaderButton(
//                                           icon: _isFavourite
//                                               ? Icons.favorite_rounded
//                                               : Icons.favorite_border_rounded,
//                                           color: _isFavourite
//                                               ? AppColors.primary
//                                               : null,
//                                           onTap: () {
//                                             HapticFeedback.lightImpact();
//                                             setState(() =>
//                                                 _isFavourite = !_isFavourite);
//                                           },
//                                           theme: theme,
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                 ],

//                 // ── Thumbnail strip ─────────────────────────────
//                 if (media.length > 1)
//                   SliverToBoxAdapter(
//                     child: Container(
//                       height: 74,
//                       margin: const EdgeInsets.only(top: 12),
//                       child: ListView.builder(
//                         padding:
//                             const EdgeInsets.symmetric(horizontal: 20),
//                         scrollDirection: Axis.horizontal,
//                         itemCount: media.length,
//                         itemBuilder: (_, index) {
//                           final isSelected = _currentImageIndex == index;
//                           return GestureDetector(
//                             onTap: () {
//                               _pageController.animateToPage(index,
//                                   duration:
//                                       const Duration(milliseconds: 300),
//                                   curve: Curves.easeInOut);
//                             },
//                             child: AnimatedContainer(
//                               duration: const Duration(milliseconds: 200),
//                               margin: const EdgeInsets.only(right: 10),
//                               width: 64,
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(12),
//                                 border: Border.all(
//                                   color: isSelected
//                                       ? AppColors.accent
//                                       : theme.dividerColor,
//                                   width: isSelected ? 2.5 : 1,
//                                 ),
//                                 boxShadow: isSelected
//                                     ? [
//                                         BoxShadow(
//                                           color: AppColors.accent
//                                               .withOpacity(0.25),
//                                           blurRadius: 8,
//                                           offset: const Offset(0, 3),
//                                         )
//                                       ]
//                                     : null,
//                               ),
//                               child: ClipRRect(
//                                 borderRadius: BorderRadius.circular(10),
//                                 child: _buildThumbnail(media[index], theme),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ),

//                 // ── Product Info Card ───────────────────────────
//                 SliverToBoxAdapter(
//                   child: Padding(
//                     padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Category + Stock row
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 10, vertical: 4),
//                               decoration: BoxDecoration(
//                                 color: theme.colorScheme.primary
//                                     .withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Text(
//                                 widget.product.categoryName.toUpperCase(),
//                                 style: TextStyle(
//                                   color: theme.colorScheme.primary,
//                                   fontSize: 11,
//                                   fontWeight: FontWeight.w700,
//                                   letterSpacing: 0.5,
//                                 ),
//                               ),
//                             ),
//                             if (!_inStock)
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 10, vertical: 4),
//                                 decoration: BoxDecoration(
//                                   color: AppColors.error.withOpacity(0.1),
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 child: const Text(
//                                   'Out of Stock',
//                                   style: TextStyle(
//                                     color: AppColors.error,
//                                     fontSize: 11,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               )
//                             else if (widget.product.stock > 0 &&
//                                 widget.product.stock < 10)
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 10, vertical: 4),
//                                 decoration: BoxDecoration(
//                                   color:
//                                       AppColors.warning.withOpacity(0.1),
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 child: Text(
//                                   'Only ${widget.product.stock} left!',
//                                   style: const TextStyle(
//                                     color: AppColors.warning,
//                                     fontSize: 11,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               )
//                             else
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 10, vertical: 4),
//                                 decoration: BoxDecoration(
//                                   color: AppColors.success.withOpacity(0.1),
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 child: const Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     Icon(Icons.check_circle,
//                                         color: AppColors.success, size: 12),
//                                     SizedBox(width: 4),
//                                     Text(
//                                       'In Stock',
//                                       style: TextStyle(
//                                         color: AppColors.success,
//                                         fontSize: 11,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                           ],
//                         ),

//                         const SizedBox(height: 12),

//                         // Product name
//                         Text(
//                           widget.product.name,
//                           style: TextStyle(
//                             color: theme.colorScheme.onSurface,
//                             fontSize: 26,
//                             fontWeight: FontWeight.w800,
//                             letterSpacing: -0.5,
//                             height: 1.2,
//                           ),
//                         ),

//                         const SizedBox(height: 12),

//                         // Rating row
//                         if (widget.product.rating > 0) ...[
//                           Row(
//                             children: [
//                               // Stars
//                               Row(
//                                 children: List.generate(5, (i) {
//                                   final filled =
//                                       i < widget.product.rating.round();
//                                   return Icon(
//                                     filled
//                                         ? Icons.star_rounded
//                                         : Icons.star_outline_rounded,
//                                     color: Colors.amber,
//                                     size: 18,
//                                   );
//                                 }),
//                               ),
//                               const SizedBox(width: 6),
//                               Text(
//                                 widget.product.rating
//                                     .toStringAsFixed(1),
//                                 style: TextStyle(
//                                   color: theme.colorScheme.onSurface
//                                       .withOpacity(0.85),
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 '(${widget.product.reviewsCount} reviews)',
//                                 style: TextStyle(
//                                   color: theme.colorScheme.onSurface
//                                       .withOpacity(0.5),
//                                   fontSize: 13,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                         ],

//                         // Price row
//                         Row(
//                           crossAxisAlignment: CrossAxisAlignment.end,
//                           children: [
//                             Text(
//                               'AED ${widget.product.finalPrice}',
//                               style: const TextStyle(
//                                 color: AppColors.primary, // Using primary red for price
//                                 fontSize: 28,
//                                 fontWeight: FontWeight.w900,
//                               ),
//                             ),
//                             if (widget.product.discountPrice != null) ...[
//                               const SizedBox(width: 10),
//                               Padding(
//                                 padding:
//                                     const EdgeInsets.only(bottom: 3),
//                                 child: Text(
//                                   'AED ${widget.product.price}',
//                                   style: TextStyle(
//                                     color: theme.colorScheme.onSurface
//                                         .withOpacity(0.45),
//                                     fontSize: 16,
//                                     decoration:
//                                         TextDecoration.lineThrough,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ],
//                         ),

//                         const SizedBox(height: 22),

//                         // ── Quantity Selector ───────────────────
//                         Row(
//                           mainAxisAlignment:
//                               MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               'Quantity',
//                               style: TextStyle(
//                                 color: theme.colorScheme.onSurface,
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             Container(
//                               decoration: BoxDecoration(
//                                 color: theme.cardColor,
//                                 borderRadius: BorderRadius.circular(12),
//                                 border:
//                                     Border.all(color: theme.dividerColor),
//                               ),
//                               child: Row(
//                                 children: [
//                                   _QtyButton(
//                                     icon: Icons.remove,
//                                     onTap: _quantity > 1
//                                         ? () => setState(
//                                             () => _quantity--)
//                                         : null,
//                                     theme: theme,
//                                   ),
//                                   SizedBox(
//                                     width: 38,
//                                     child: Text(
//                                       '$_quantity',
//                                       textAlign: TextAlign.center,
//                                       style: TextStyle(
//                                         color: theme.colorScheme.onSurface,
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ),
//                                   _QtyButton(
//                                     icon: Icons.add,
//                                     onTap: () =>
//                                         setState(() => _quantity++),
//                                     theme: theme,
//                                     isPrimary: true,
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),

//                         const SizedBox(height: 22),

//                         // ── Delivery & Services strip ───────────
//                         Container(
//                           padding: const EdgeInsets.all(14),
//                           decoration: BoxDecoration(
//                             color: theme.cardColor.withOpacity(0.6),
//                             borderRadius: BorderRadius.circular(14),
//                             border:
//                                 Border.all(color: theme.dividerColor),
//                           ),
//                           child: Row(
//                             mainAxisAlignment:
//                                 MainAxisAlignment.spaceAround,
//                             children: [
//                               _ServiceChip(
//                                 icon: Icons.local_shipping_outlined,
//                                 label: 'Free\nDelivery',
//                                 theme: theme,
//                               ),
//                               _Divider(theme: theme),
//                               _ServiceChip(
//                                 icon: Icons.refresh_rounded,
//                                 label: 'Easy\nReturns',
//                                 theme: theme,
//                               ),
//                               _Divider(theme: theme),
//                               _ServiceChip(
//                                 icon: Icons.verified_outlined,
//                                 label: 'Quality\nGuaranteed',
//                                 theme: theme,
//                               ),
//                               if (widget.product
//                                       .expectedDeliveryTime !=
//                                   null) ...[
//                                 _Divider(theme: theme),
//                                 _ServiceChip(
//                                   icon: Icons.access_time_rounded,
//                                   label: widget.product
//                                       .expectedDeliveryTime!,
//                                   theme: theme,
//                                 ),
//                               ],
//                             ],
//                           ),
//                         ),

//                         const SizedBox(height: 22),

//                         // ── Details ─────────────────────────────
//                         _SectionTitle(
//                             title: 'Details', theme: theme),
//                         const SizedBox(height: 10),
//                         _ExpandableText(
//                           text: widget.product.description.isNotEmpty
//                               ? widget.product.description
//                               : 'No description available.',
//                           theme: theme,
//                         ),

//                         const SizedBox(height: 22),

//                         // ── Product Highlights ──────────────────
//                         _SectionTitle(
//                             title: 'Product Highlights',
//                             theme: theme),
//                         const SizedBox(height: 12),
//                         _HighlightRow(
//                             icon: Icons.inventory_2_outlined,
//                             label: 'SKU',
//                             value: widget.product.sku ?? '—',
//                             theme: theme),
//                         if (widget.product.rating > 0)
//                           _HighlightRow(
//                               icon: Icons.star_outline_rounded,
//                               label: 'Rating',
//                               value:
//                                   '${widget.product.rating} / 5.0',
//                               theme: theme),
//                         _HighlightRow(
//                             icon: Icons.layers_outlined,
//                             label: 'Stock',
//                             value: '${widget.product.stock} units',
//                             theme: theme),

//                         const SizedBox(height: 100),
//                         // Extra bottom padding for the floating bar
//                       ],
//                     ),
//                   ),
//                 ),
//               ],  // slivers
//             ),  // CustomScrollView
//           ),  // Expanded

//           // ─── Bottom Action Bar ─────────────────────────────────
//           Container(
//             padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
//             decoration: BoxDecoration(
//               color: theme.cardColor.withOpacity(0.9),
//               borderRadius:
//                   const BorderRadius.vertical(top: Radius.circular(28)),
//               border:
//                   Border(top: BorderSide(color: theme.dividerColor)),
//               boxShadow: [
//                 BoxShadow(
//                   color: theme.shadowColor.withOpacity(0.12),
//                   blurRadius: 24,
//                   offset: const Offset(0, -8),
//                 ),
//               ],
//             ),
//             child: SafeArea(
//               top: false,
//               child: Row(
//                 children: [
//                   // ── Add to Cart ─────────────────────────
//                   Expanded(
//                     flex: 2,
//                     child: OutlinedButton(
//                       onPressed: _inStock
//                           ? () {
//                               if (_requireLogin(action: 'add to cart')) {
//                                 _showAddedToCartSnackbar();
//                               }
//                             }
//                           : null,
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: AppColors.primary,
//                         side: const BorderSide(
//                             color: AppColors.primary, width: 2),
//                         padding:
//                             const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                       ),
//                       child: const Text(
//                         'Add to Cart',
//                         style: TextStyle(
//                             fontSize: 15, fontWeight: FontWeight.w700),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),

//                   // ── Buy Now ─────────────────────────────
//                   Expanded(
//                     flex: 3,
//                     child: Container(
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: _inStock
//                               ? [AppColors.primary, AppColors.primaryDark]
//                               : [Colors.grey, Colors.grey.shade700],
//                         ),
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: _inStock
//                             ? [
//                                 BoxShadow(
//                                   color: AppColors.primary.withOpacity(0.35),
//                                   blurRadius: 12,
//                                   offset: const Offset(0, 6),
//                                 )
//                               ]
//                             : null,
//                       ),
//                       child: ElevatedButton(
//                         onPressed: _inStock
//                             ? () {
//                                 if (_requireLogin(action: 'buy this item')) {
//                                   // TODO: navigate to checkout
//                                 }
//                               }
//                             : null,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.transparent,
//                           foregroundColor: AppColors.white,
//                           shadowColor: Colors.transparent,
//                           padding:
//                               const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           elevation: 0,
//                         ),
//                         child: const Text(
//                           'Buy Now',
//                           style: TextStyle(
//                               fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMediaView(_MediaItem item, ThemeData theme) {
//     if (item.type == _MediaType.video) {
//       return Container(
//         color: Colors.black,
//         child: Stack(
//           alignment: Alignment.center,
//           children: [
//             if (item.thumbnail != null)
//               Image.network(item.thumbnail!,
//                   fit: BoxFit.cover,
//                   width: double.infinity,
//                   height: double.infinity,
//                   errorBuilder: (_, __, ___) =>
//                       Container(color: Colors.black))
//             else
//               Container(color: const Color(0xFF1E1E1E)),
//             Container(
//               width: 64,
//               height: 64,
//               decoration: BoxDecoration(
//                 color: Colors.black.withOpacity(0.55),
//                 shape: BoxShape.circle,
//                 border: Border.all(color: AppColors.white, width: 2),
//               ),
//               child:
//                   const Icon(Icons.play_arrow, color: AppColors.white, size: 36),
//             ),
//           ],
//         ),
//       );
//     }
//     return Container(
//       color: theme.cardColor,
//       child: item.url.isNotEmpty
//           ? Image.network(item.url,
//               fit: BoxFit.cover,
//               errorBuilder: (_, __, ___) => Image.network(
//                     AppConstants.kDefaultProductImage,
//                     fit: BoxFit.cover,
//                   ))
//           : Image.network(AppConstants.kDefaultProductImage,
//               fit: BoxFit.cover),
//     );
//   }

//   Widget _buildThumbnail(_MediaItem item, ThemeData theme) {
//     if (item.type == _MediaType.video) {
//       return Stack(
//         alignment: Alignment.center,
//         children: [
//           if (item.thumbnail != null)
//             Image.network(item.thumbnail!,
//                 fit: BoxFit.cover, width: 64, height: 64)
//           else
//             Container(color: Colors.black, width: 64, height: 64),
//           const Icon(Icons.play_circle, color: AppColors.white, size: 22),
//         ],
//       );
//     }
//     return item.url.isNotEmpty
//         ? Image.network(item.url, fit: BoxFit.cover, width: 64, height: 64)
//         : Container(color: theme.cardColor, width: 64, height: 64);
//   }
// }

// // ═════════════════════════════════════════────═══════════════════════════
// //  HELPER WIDGETS
// // ═══════════════════════════════════════════════════════════════════════

// class _QtyButton extends StatelessWidget {
//   final IconData icon;
//   final VoidCallback? onTap;
//   final ThemeData theme;
//   final bool isPrimary;

//   const _QtyButton({
//     required this.icon,
//     required this.onTap,
//     required this.theme,
//     this.isPrimary = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final enabled = onTap != null;
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 38,
//         height: 38,
//         decoration: BoxDecoration(
//           color: isPrimary
//               ? AppColors.primary
//               : enabled
//                   ? Colors.transparent
//                   : Colors.transparent,
//           borderRadius: isPrimary
//               ? const BorderRadius.only(
//                   topRight: Radius.circular(11),
//                   bottomRight: Radius.circular(11),
//                 )
//               : const BorderRadius.only(
//                   topLeft: Radius.circular(11),
//                   bottomLeft: Radius.circular(11),
//                 ),
//         ),
//         child: Icon(
//           icon,
//           size: 18,
//           color: isPrimary
//               ? AppColors.white
//               : enabled
//                   ? theme.colorScheme.onSurface
//                   : theme.colorScheme.onSurface.withOpacity(0.3),
//         ),
//       ),
//     );
//   }
// }

// class _ServiceChip extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final ThemeData theme;

//   const _ServiceChip(
//       {required this.icon, required this.label, required this.theme});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, color: AppColors.primary, size: 20),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             color: theme.colorScheme.onSurface.withOpacity(0.6),
//             fontSize: 10,
//             height: 1.3,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _Divider extends StatelessWidget {
//   final ThemeData theme;
//   const _Divider({required this.theme});

//   @override
//   Widget build(BuildContext context) =>
//       Container(width: 1, height: 36, color: theme.dividerColor);
// }

// class _SectionTitle extends StatelessWidget {
//   final String title;
//   final ThemeData theme;
//   const _SectionTitle({required this.title, required this.theme});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Container(
//           width: 4,
//           height: 18,
//           decoration: BoxDecoration(
//             color: AppColors.primary,
//             borderRadius: BorderRadius.circular(2),
//           ),
//         ),
//         const SizedBox(width: 8),
//         Text(
//           title,
//           style: TextStyle(
//             color: theme.colorScheme.onSurface,
//             fontSize: 17,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _ExpandableText extends StatefulWidget {
//   final String text;
//   final ThemeData theme;
//   const _ExpandableText({required this.text, required this.theme});

//   @override
//   State<_ExpandableText> createState() => _ExpandableTextState();
// }

// class _ExpandableTextState extends State<_ExpandableText> {
//   bool _expanded = false;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         AnimatedCrossFade(
//           firstChild: Text(
//             widget.text,
//             maxLines: 4,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(
//               color: widget.theme.colorScheme.onSurface.withOpacity(0.7),
//               fontSize: 15,
//               height: 1.6,
//             ),
//           ),
//           secondChild: Text(
//             widget.text,
//             style: TextStyle(
//               color: widget.theme.colorScheme.onSurface.withOpacity(0.7),
//               fontSize: 15,
//               height: 1.6,
//             ),
//           ),
//           crossFadeState: _expanded
//               ? CrossFadeState.showSecond
//               : CrossFadeState.showFirst,
//           duration: const Duration(milliseconds: 250),
//         ),
//         if (widget.text.length > 160) ...[
//           const SizedBox(height: 6),
//           GestureDetector(
//             onTap: () => setState(() => _expanded = !_expanded),
//             child: Text(
//               _expanded ? 'Show less' : 'Read more',
//               style: const TextStyle(
//                 color: AppColors.primary,
//                 fontSize: 13,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ],
//     );
//   }
// }

// class _HighlightRow extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String value;
//   final ThemeData theme;

//   const _HighlightRow({
//     required this.icon,
//     required this.label,
//     required this.value,
//     required this.theme,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: [
//           Container(
//             width: 34,
//             height: 34,
//             decoration: BoxDecoration(
//               color: AppColors.primary.withOpacity(0.08),
//               borderRadius: BorderRadius.circular(9),
//             ),
//             child: Icon(icon, color: AppColors.primary, size: 17),
//           ),
//           const SizedBox(width: 12),
//           Text(
//             label,
//             style: TextStyle(
//               color: theme.colorScheme.onSurface.withOpacity(0.55),
//               fontSize: 14,
//             ),
//           ),
//           const Spacer(),
//           Text(
//             value,
//             style: TextStyle(
//               color: theme.colorScheme.onSurface,
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─── Models ───────────────────────────────────────────────────────────
// enum _MediaType { image, video }

// class _MediaItem {
//   final _MediaType type;
//   final String url;
//   final int id;
//   final String? thumbnail;

//   _MediaItem(
//       {required this.type,
//       required this.url,
//       required this.id,
//       this.thumbnail});
// }

// class _HeaderButton extends StatelessWidget {
//   final IconData icon;
//   final VoidCallback onTap;
//   final ThemeData theme;
//   final Color? color;

//   const _HeaderButton({
//     required this.icon,
//     required this.onTap,
//     required this.theme,
//     this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 42,
//         height: 42,
//         decoration: BoxDecoration(
//           color: theme.cardColor.withOpacity(0.85),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: theme.dividerColor),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.08),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/core/config/app_constants.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';
import 'package:uae_ecom_project/features/auth/screens/login_screen.dart';
import 'package:uae_ecom_project/features/cart/controller/cart_controller.dart';
import 'package:uae_ecom_project/features/orders/controller/order_controller.dart';
import 'package:uae_ecom_project/features/orders/model/review_model.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';
import 'package:uae_ecom_project/features/products/widgets/bulk_order_card.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;
  int _quantity = 1;
  late PageController _pageController;
  List<ReviewModel> _reviews = [];
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    try {
      final controller = context.read<OrderController>();
      final reviews = await controller.fetchProductReviews(widget.product.id);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<_MediaItem> get _media {
    final items = <_MediaItem>[];
    
    // Add main image first if it exists
    if (widget.product.mainImage != null && widget.product.mainImage!.isNotEmpty) {
      items.add(_MediaItem(
        type: _MediaType.image,
        url: widget.product.mainImage!,
        id: -1, // Special ID for main image
      ));
    }

    // Add gallery images (avoiding duplicates if it matches main image)
    for (var img in widget.product.images) {
      if (img.image != widget.product.mainImage) {
        items.add(_MediaItem(
          type: _MediaType.image,
          url: img.image,
          id: img.id,
        ));
      }
    }

    // Add videos
    items.addAll(widget.product.videos.map((e) => _MediaItem(
          type: _MediaType.video,
          url: e.video,
          id: e.id,
          thumbnail: e.thumbnail)));

    if (items.isEmpty) {
      items.add(_MediaItem(
          type: _MediaType.image,
          url: AppConstants.kDefaultProductImage,
          id: 0));
    }
    return items;
  }

  int get _discountPercent {
    if (widget.product.discountPrice == null || widget.product.price <= 0) {
      return 0;
    }
    return (((widget.product.price - widget.product.finalPrice) /
                widget.product.price) *
            100)
        .round();
  }

  bool get _inStock =>
      widget.product.isAvailable && widget.product.stock > 0;

  void _showAddedToCartSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.success,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppColors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${trTextStatic(context, widget.product.name)} ${trStatic(context, 'added_to_cart')}',
                style: const TextStyle(color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns true if the user is logged in. Otherwise pops open LoginScreen
  /// and shows a gentle prompt, then returns false.
  bool _requireLogin({required String action}) {
    final auth = context.read<AuthController>();
    if (auth.currentUser != null) return true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.lock_outline_rounded,
                color: AppColors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                 '${trStatic(context, 'login_to_action')} ${trTextStatic(context, action)}',
                style: const TextStyle(color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = _media;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.4, 1.0],
            colors: theme.brightness == Brightness.dark
                ? [
                    const Color(0xFF001A1F),
                    const Color(0xFF002A35),
                    theme.scaffoldBackgroundColor,
                  ]
                : [
                    theme.scaffoldBackgroundColor,
                    const Color(0xFFF0F4F5),
                    theme.scaffoldBackgroundColor,
                  ],
          ),
        ),
        child: Column(
          children: [
            // ─── Scrollable Content ──────────────────────────────
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Gallery header (full-bleed) ──────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            // ── Main Media ───────────────────────────
                        SizedBox(
                          height: 280,
                          child: Stack(
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                itemCount: media.length,
                                onPageChanged: (i) =>
                                    setState(() => _currentImageIndex = i),
                                itemBuilder: (_, index) =>
                                    _buildMediaView(media[index], theme),
                              ),
                              // Removed blur/gradient overlays for a cleaner look
                              // Discount badge
                              if (_discountPercent > 0)
                                Positioned(
                                  bottom: 14,
                                  left: 14,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.error
                                              .withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      tr(context, 'discount_off', args: {'percent': _discountPercent.toString()}),
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              // Video tag
                              if (media[_currentImageIndex].type ==
                                  _MediaType.video)
                                Positioned(
                                  bottom: 14,
                                  right: 14,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withOpacity(0.65),
                                      borderRadius:
                                          BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.play_circle_fill,
                                            color: AppColors.white,
                                            size: 13),
                                        const SizedBox(width: 4),
                                        Text(tr(context, 'video_label'),
                                            style: TextStyle(
                                                color: AppColors.white,
                                                fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ),
                              // Dot indicators
                              if (media.length > 1)
                                Positioned(
                                  bottom: 14,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children:
                                        List.generate(media.length, (i) {
                                      final active =
                                          i == _currentImageIndex;
                                      return AnimatedContainer(
                                        duration: const Duration(
                                            milliseconds: 250),
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 3),
                                        width: active ? 18 : 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: active
                                              ? AppColors.white
                                              : AppColors.white
                                                  .withOpacity(0.45),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // ── Floating App Bar ─────────────────────
                        Positioned(
                          top: 10,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _HeaderButton(
                                      icon: Icons.arrow_back_ios_new,
                                      onTap: () => Navigator.pop(context),
                                      theme: theme,
                                    ),
                                    Row(
                                      children: [
                                        _HeaderButton(
                                          icon: Icons.share_rounded,
                                            onTap: () {
                                                final text =
                                                  '${trText(context, widget.product.name)}\n${tr(context, 'currency_aed')} ${widget.product.finalPrice}\n\n${tr(context, 'check_this_out')}';
                                              Share.share(text);
                                            },
                                          theme: theme,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        ],
                      ),
                    ),
                  ),),

                  // ── Thumbnail strip ─────────────────────────────
                  if (media.length > 1)
                    SliverToBoxAdapter(
                      child: Container(
                        height: 74,
                        margin: const EdgeInsets.only(top: 12),
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          itemCount: media.length,
                          itemBuilder: (_, index) {
                            final isSelected = _currentImageIndex == index;
                            return GestureDetector(
                              onTap: () {
                                _pageController.animateToPage(index,
                                    duration:
                                        const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 10),
                                width: 64,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.accent
                                        : theme.dividerColor,
                                    width: isSelected ? 2.5 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.accent
                                                .withOpacity(0.25),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          )
                                        ]
                                      : null,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _buildThumbnail(media[index], theme),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // ── Product Info Card ───────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category + Stock row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    trText(context, widget.product.categoryName).toUpperCase(),
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (!_inStock)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      tr(context, 'out_of_stock'),
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle,
                                            color: AppColors.success, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          tr(context, 'in_stock'),
                                          style: const TextStyle(
                                            color: AppColors.success,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Product name
                          Text(
                            trText(context, widget.product.name),
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                              height: 1.1,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Rating row
                          if (widget.product.rating > 0) ...[
                            Row(
                              children: [
                                // Stars
                                Row(
                                  children: List.generate(5, (i) {
                                    final filled =
                                        i < widget.product.rating.round();
                                    return Icon(
                                      filled
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      color: Colors.amber,
                                      size: 18,
                                    );
                                  }),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.product.rating
                                      .toStringAsFixed(1),
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.85),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${widget.product.reviewsCount} ${tr(context, 'reviews_label')})',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.5),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Price row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${tr(context, 'currency_aed')} ${widget.product.finalPrice}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (widget.product.discountPrice != null) ...[
                                const SizedBox(width: 10),
                                Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 3),
                                  child: Text(
                                    'AED ${widget.product.price}',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.45),
                                      fontSize: 16,
                                      decoration:
                                          TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 22),

                          // ── Quantity Selector ───────────────────
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                tr(context, 'quantity'),
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: theme.dividerColor),
                                ),
                                child: Row(
                                  children: [
                                    _QtyButton(
                                      icon: Icons.remove,
                                      onTap: _quantity > 1
                                          ? () => setState(
                                              () => _quantity--)
                                          : null,
                                      theme: theme,
                                    ),
                                    SizedBox(
                                      width: 38,
                                      child: Text(
                                        '$_quantity',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    _QtyButton(
                                      icon: Icons.add,
                                      onTap: () =>
                                          setState(() => _quantity++),
                                      theme: theme,
                                      isPrimary: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          // ── Delivery & Services strip ───────────
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.cardColor.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: theme.dividerColor),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                              children: [
                                _ServiceChip(
                                  icon: Icons.local_shipping_outlined,
                                  label: tr(context, 'free_delivery'),
                                  theme: theme,
                                ),
                                _Divider(theme: theme),
                                _ServiceChip(
                                  icon: Icons.refresh_rounded,
                                  label: tr(context, 'easy_returns'),
                                  theme: theme,
                                ),
                                _Divider(theme: theme),
                                _ServiceChip(
                                  icon: Icons.verified_outlined,
                                  label: tr(context, 'quality_guaranteed'),
                                  theme: theme,
                                ),
                                if (widget.product
                                        .expectedDeliveryTime !=
                                    null) ...[
                                  _Divider(theme: theme),
                                  _ServiceChip(
                                    icon: Icons.access_time_rounded,
                                    label: trText(context, widget.product.expectedDeliveryTime!),
                                    theme: theme,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          // ── Details ─────────────────────────────
                          _SectionTitle(
                              title: tr(context, 'product_info'), theme: theme),
                          const SizedBox(height: 12),
                          _ExpandableText(
                            text: widget.product.description.isNotEmpty
                                ? trText(context, widget.product.description)
                                : tr(context, 'default_description'),
                            theme: theme,
                          ),

                          const SizedBox(height: 24),

                          // ── Key Specifications (Demo Data) ──────
                          _SectionTitle(
                              title: tr(context, 'key_specs'),
                              theme: theme),
                          const SizedBox(height: 12),
                          _HighlightRow(
                              icon: Icons.public_rounded,
                              label: tr(context, 'origin'),
                              value: tr(context, 'origin_value'),
                              theme: theme),
                          _HighlightRow(
                              icon: Icons.thermostat_rounded,
                              label: tr(context, 'storage'),
                              value: tr(context, 'storage_value'),
                              theme: theme),
                          _HighlightRow(
                              icon: Icons.scale_rounded,
                              label: tr(context, 'approx_weight'),
                              value: tr(context, 'approx_weight_value'),
                              theme: theme),
                          _HighlightRow(
                              icon: Icons.verified_rounded,
                              label: tr(context, 'quality_grade'),
                              value: tr(context, 'quality_grade_value'),
                              theme: theme),

                          const SizedBox(height: 24),

                          // ── Usage & Preparation (Demo Data) ─────
                          _SectionTitle(
                              title: tr(context, 'cooking_prep'),
                              theme: theme),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.primary.withOpacity(0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _BuildTip(
                                  title: tr(context, 'cleaning'),
                                  desc: tr(context, 'cleaning_desc'),
                                  theme: theme,
                                ),
                                const Divider(height: 24),
                                _BuildTip(
                                  title: tr(context, 'best_for'),
                                  desc: tr(context, 'best_for_desc'),
                                  theme: theme,
                                ),
                                const Divider(height: 24),
                                _BuildTip(
                                  title: tr(context, 'storage_tip'),
                                  desc: tr(context, 'storage_tip_desc'),
                                  theme: theme,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ── Customer Reviews Section ─────────────
                          _buildReviewsSection(theme),

                          const SizedBox(height: 32),

                          // ── Bulk Order Section ──────────────────
                          BulkOrderCard(productName: widget.product.name),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Bottom Action Bar ─────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                color: theme.cardColor.withOpacity(0.9),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border:
                    Border(top: BorderSide(color: theme.dividerColor)),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // ── Add to Cart ─────────────────────────
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: _inStock
                            ? () async {
                                if (_requireLogin(action: trStatic(context, 'action_add_to_cart'))) {
                                  final success = await context
                                      .read<CartController>()
                                      .addToCart(widget.product.id, _quantity);
                                  if (success) {
                                    _showAddedToCartSnackbar();
                                  } else {
                                    final error = context.read<CartController>().error;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(error ?? 'Failed to add to cart'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              }
                            : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                              color: AppColors.primary, width: 2),
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          tr(context, 'add_to_cart'),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // ── Buy Now ─────────────────────────────
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _inStock
                                ? [AppColors.primary, AppColors.primaryDark]
                                : [Colors.grey, Colors.grey.shade700],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _inStock
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  )
                                ]
                              : null,
                        ),
                        child: ElevatedButton(
                          onPressed: _inStock
                              ? () async {
                                  if (_requireLogin(action: trStatic(context, 'action_buy'))) {
                                    // Add to cart first
                                    final success = await context
                                        .read<CartController>()
                                        .addToCart(widget.product.id, _quantity);
                                    
                                    if (success && mounted) {
                                      // Proceed to order summary (Cart Mode)
                                      Navigator.pushNamed(
                                        context,
                                        '/order',
                                        arguments: {
                                          'product': ProductModel.empty(),
                                          'quantity': 0,
                                        },
                                      );
                                    } else if (mounted) {
                                      final error = context.read<CartController>().error;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(error ?? 'Failed to prepare order'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: AppColors.white,
                            shadowColor: Colors.transparent,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            tr(context, 'buy_now'),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaView(_MediaItem item, ThemeData theme) {
    if (item.type == _MediaType.video) {
      return Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (item.thumbnail != null)
              Image.network(item.thumbnail!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.black))
            else
              Container(color: const Color(0xFF1E1E1E)),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2),
              ),
              child:
                  const Icon(Icons.play_arrow, color: AppColors.white, size: 36),
            ),
          ],
        ),
      );
    }
    return Container(
      color: theme.cardColor,
      child: Center(
        child: Image.network(
          item.url.isNotEmpty ? item.url : AppConstants.kDefaultProductImage,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => Image.network(
            AppConstants.kDefaultProductImage,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(_MediaItem item, ThemeData theme) {
    if (item.type == _MediaType.video) {
      return Stack(
        alignment: Alignment.center,
        children: [
          if (item.thumbnail != null)
            Image.network(item.thumbnail!,
                fit: BoxFit.cover, width: 64, height: 64)
          else
            Container(color: Colors.black, width: 64, height: 64),
          const Icon(Icons.play_circle, color: AppColors.white, size: 22),
        ],
      );
    }
    return item.url.isNotEmpty
        ? Image.network(item.url, fit: BoxFit.cover, width: 64, height: 64)
        : Container(color: theme.cardColor, width: 64, height: 64);
  }

  // ── Customer Reviews Section ────────────────────────────────────────
  Widget _buildReviewsSection(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              tr(context, 'customer_reviews'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (_reviews.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB800)),
                    const SizedBox(width: 3),
                    Text(
                      widget.product.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFFFFB800),
                      ),
                    ),
                    Text(
                      ' (${_reviews.length})',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Content
        if (_isLoadingReviews)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ),
          )
        else if (_reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withOpacity(0.06)),
            ),
            child: Column(
              children: [
                Icon(Icons.rate_review_outlined, size: 36, color: Colors.grey[350]),
                const SizedBox(height: 10),
                Text(
                  tr(context, 'no_reviews_yet'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr(context, 'be_the_first_to_review'),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(
            _reviews.length > 5 ? 5 : _reviews.length,
            (index) => _buildReviewCard(_reviews[index], theme, isDark),
          ),
      ],
    );
  }
  Widget _buildReviewCard(ReviewModel review, ThemeData theme, bool isDark) {
    final d = review.createdAt;
    final monthKeys = [
      'month_jan', 'month_feb', 'month_mar', 'month_apr', 
      'month_may', 'month_jun', 'month_jul', 'month_aug', 
      'month_sep', 'month_oct', 'month_nov', 'month_dec'
    ];
    final dateStr = '${d.day} ${tr(context, monthKeys[d.month - 1])} ${d.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info + rating + date
          Row(
            children: [
              // Avatar
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName.isNotEmpty ? trTextStatic(context, review.userName) : tr(context, 'customer_label'),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                    ),
                  ],
                ),
              ),
              // Stars
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 16,
                    color: i < review.rating ? const Color(0xFFFFB800) : Colors.grey[300],
                  );
                }),
              ),
            ],
          ),

          // Comment
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              trTextStatic(context, review.comment),
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],

          // Review images
          if (review.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              review.images[i],
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        review.images[i],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 60, height: 60, color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 16),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}


// ═════════════════════════════════════════════════════════════════════════
//  HELPER WIDGETS
// ═════════════════════════════════════════════════════════════════════════

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final ThemeData theme;
  final bool isPrimary;

  const _QtyButton({
    required this.icon,
    required this.onTap,
    required this.theme,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary
              : enabled
                  ? Colors.transparent
                  : Colors.transparent,
          borderRadius: isPrimary
              ? const BorderRadius.only(
                  topRight: Radius.circular(11),
                  bottomRight: Radius.circular(11),
                )
              : const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  bottomLeft: Radius.circular(11),
                ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isPrimary
              ? AppColors.white
              : enabled
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withOpacity(0.3),
        ),
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;

  const _ServiceChip(
      {required this.icon, required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 10,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  final ThemeData theme;
  const _Divider({required this.theme});

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: theme.dividerColor);
}

class _BuildTip extends StatelessWidget {
  final String title;
  final String desc;
  final ThemeData theme;

  const _BuildTip({
    required this.title,
    required this.desc,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.tips_and_updates_rounded,
                  color: AppColors.primary, size: 14),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            desc,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final ThemeData theme;
  const _SectionTitle({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ExpandableText extends StatefulWidget {
  final String text;
  final ThemeData theme;
  const _ExpandableText({required this.text, required this.theme});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          firstChild: Text(
            widget.text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: widget.theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 15,
              height: 1.6,
            ),
          ),
          secondChild: Text(
            widget.text,
            style: TextStyle(
              color: widget.theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 15,
              height: 1.6,
            ),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
        if (widget.text.length > 160) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? tr(context, 'show_less') : tr(context, 'read_more'),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _HighlightRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _HighlightRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: AppColors.primary, size: 17),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.55),
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Models ───────────────────────────────────────────────────────────
enum _MediaType { image, video }

class _MediaItem {
  final _MediaType type;
  final String url;
  final int id;
  final String? thumbnail;

  _MediaItem(
      {required this.type,
      required this.url,
      required this.id,
      this.thumbnail});
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final ThemeData theme;
  final Color? color;

  const _HeaderButton({
    required this.icon,
    required this.onTap,
    required this.theme, 
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color ?? theme.colorScheme.onSurface.withOpacity(0.8),
          size: 20,
        ),
      ),
    );
  }
}