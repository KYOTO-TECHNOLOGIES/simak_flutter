import 'package:uae_ecom_project/features/products/model/product_model.dart';

class GrillFryDummyData {
  GrillFryDummyData._();

  static final List<ProductModel> products = [
    ProductModel(
      id: 9001,
      name: 'Fried Pomfret',
      description:
          'Fresh silver pomfret marinated in aromatic coastal spices, fried to a golden crisp outside with juicy tender flakes inside.',
      price: 48.0,
      discountPrice: 38.0,
      finalPrice: 38.0,
      stock: 15,
      isAvailable: true,
      categoryName: 'GRILL & FRY',
      unit: '500g (Whole)',
      rating: 4.9,
      reviewsCount: 48,
      mainImage: 'assets/images/fried_pomfret.jpg',
      images: [
        ProductImage(
          id: 9101,
          image: 'assets/images/fried_pomfret.jpg',
          isMain: true,
        ),
      ],
      availableEmirates: const [
        'dubai',
        'abu dhabi',
        'sharjah',
        'ajman',
        'ras al khaimah',
        'fujairah',
        'umm al quwain',
      ],
      preparationSpecifications: [
        PreparationSpecification(
          id: 9201,
          name: 'Mild Coastal Seasoning',
          description: 'Light spice blend with lime and herbs',
        ),
        PreparationSpecification(
          id: 9202,
          name: 'Extra Spicy Masala',
          description: 'Traditional fiery chili and pepper rub',
        ),
      ],
    ),
    ProductModel(
      id: 9002,
      name: 'Grilled King Fish',
      description:
          'Thick King Fish steak flame-grilled over charcoal embers, basted in lemon garlic butter and Mediterranean herbs.',
      price: 55.0,
      discountPrice: 44.0,
      finalPrice: 44.0,
      stock: 12,
      isAvailable: true,
      categoryName: 'GRILL & FRY',
      unit: '400g Steak',
      rating: 4.8,
      reviewsCount: 36,
      mainImage: 'assets/images/grilled_king_fish.jpg',
      images: [
        ProductImage(
          id: 9102,
          image: 'assets/images/grilled_king_fish.jpg',
          isMain: true,
        ),
      ],
      availableEmirates: const [
        'dubai',
        'abu dhabi',
        'sharjah',
        'ajman',
        'ras al khaimah',
        'fujairah',
        'umm al quwain',
      ],
      preparationSpecifications: [
        PreparationSpecification(
          id: 9203,
          name: 'Garlic Butter Glaze',
          description: 'Melted garlic butter with parsley',
        ),
        PreparationSpecification(
          id: 9204,
          name: 'Smoky BBQ Rub',
          description: 'Hickory smoke marinade with paprika',
        ),
      ],
    ),
    ProductModel(
      id: 9003,
      name: 'Crispy Fried Prawns',
      description:
          'Jumbo succulent tiger prawns lightly coated in golden Japanese panko breadcrumbs, flash-fried crispy and served with dipping sauce.',
      price: 65.0,
      discountPrice: 49.0,
      finalPrice: 49.0,
      stock: 20,
      isAvailable: true,
      categoryName: 'GRILL & FRY',
      unit: '8-10 Large Prawns',
      rating: 5.0,
      reviewsCount: 62,
      mainImage: 'assets/images/crispy_fried_prawns.jpg',
      images: [
        ProductImage(
          id: 9103,
          image: 'assets/images/crispy_fried_prawns.jpg',
          isMain: true,
        ),
      ],
      availableEmirates: const [
        'dubai',
        'abu dhabi',
        'sharjah',
        'ajman',
        'ras al khaimah',
        'fujairah',
        'umm al quwain',
      ],
      preparationSpecifications: [
        PreparationSpecification(
          id: 9205,
          name: 'Sweet Chili Dip',
          description: 'Thai style sweet and spicy dipping sauce',
        ),
        PreparationSpecification(
          id: 9206,
          name: 'Spicy Dynamite Sauce',
          description: 'Creamy spicy sriracha mayo glaze',
        ),
      ],
    ),
    ProductModel(
      id: 9004,
      name: 'Grilled Salmon',
      description:
          'Premium Atlantic salmon fillet seared with smoky char marks, glazed with honey dill glaze on a bed of fresh greens.',
      price: 72.0,
      discountPrice: 59.0,
      finalPrice: 59.0,
      stock: 10,
      isAvailable: true,
      categoryName: 'GRILL & FRY',
      unit: '350g Fillet',
      rating: 4.9,
      reviewsCount: 54,
      mainImage: 'assets/images/grilled_salmon.jpg',
      images: [
        ProductImage(
          id: 9104,
          image: 'assets/images/grilled_salmon.jpg',
          isMain: true,
        ),
      ],
      availableEmirates: const [
        'dubai',
        'abu dhabi',
        'sharjah',
        'ajman',
        'ras al khaimah',
        'fujairah',
        'umm al quwain',
      ],
      preparationSpecifications: [
        PreparationSpecification(
          id: 9207,
          name: 'Honey Mustard Dill',
          description: 'Sweet honey mustard with fragrant dill',
        ),
        PreparationSpecification(
          id: 9208,
          name: 'Lemon Herb Butter',
          description: 'Zesty lemon butter reduction',
        ),
      ],
    ),
    ProductModel(
      id: 9005,
      name: 'Fried Calamari',
      description:
          'Tender ocean squid rings and tentacles dusted in seasoned flour with cracked sea salt and smoked paprika, served with tartar dip.',
      price: 45.0,
      discountPrice: 36.0,
      finalPrice: 36.0,
      stock: 18,
      isAvailable: true,
      categoryName: 'GRILL & FRY',
      unit: '300g Plate',
      rating: 4.7,
      reviewsCount: 31,
      mainImage: 'assets/images/fried_calamari.jpg',
      images: [
        ProductImage(
          id: 9105,
          image: 'assets/images/fried_calamari.jpg',
          isMain: true,
        ),
      ],
      availableEmirates: const [
        'dubai',
        'abu dhabi',
        'sharjah',
        'ajman',
        'ras al khaimah',
        'fujairah',
        'umm al quwain',
      ],
      preparationSpecifications: [
        PreparationSpecification(
          id: 9209,
          name: 'Homemade Tartar Sauce',
          description: 'Creamy caper and herb tartar',
        ),
        PreparationSpecification(
          id: 9210,
          name: 'Garlic Aioli',
          description: 'Rich roasted garlic aioli dip',
        ),
      ],
    ),
    ProductModel(
      id: 9006,
      name: 'Spicy Fried Fish',
      description:
          'Fiery coastal masala pan-fried fish fillets seasoned with crushed red chilies, curry leaves, ginger, and aromatic toasted spices.',
      price: 50.0,
      discountPrice: 39.0,
      finalPrice: 39.0,
      stock: 14,
      isAvailable: true,
      categoryName: 'GRILL & FRY',
      unit: '450g Cut',
      rating: 4.9,
      reviewsCount: 45,
      mainImage: 'assets/images/spicy_fried_fish.jpg',
      images: [
        ProductImage(
          id: 9106,
          image: 'assets/images/spicy_fried_fish.jpg',
          isMain: true,
        ),
      ],
      availableEmirates: const [
        'dubai',
        'abu dhabi',
        'sharjah',
        'ajman',
        'ras al khaimah',
        'fujairah',
        'umm al quwain',
      ],
      preparationSpecifications: [
        PreparationSpecification(
          id: 9211,
          name: 'Tawa Pan Fry',
          description: 'Crispy skillet fry in coconut oil',
        ),
        PreparationSpecification(
          id: 9212,
          name: 'Deep Fry Crisp',
          description: 'Golden crunchy batter coating',
        ),
      ],
    ),
    ProductModel(
      id: 9007,
      name: "Chef's Grill & Fry Feast",
      description:
          'A royal seafood feast for 2-3: whole grilled lobster tail, fried pomfret, crispy prawns, and calamari with signature sauces.',
      price: 139.0,
      discountPrice: 115.0,
      finalPrice: 115.0,
      stock: 8,
      isAvailable: true,
      categoryName: 'GRILL & FRY',
      unit: 'Feast Platter (2-3 Pax)',
      rating: 5.0,
      reviewsCount: 89,
      mainImage: 'assets/images/grill_and_fry.jpg',
      images: [
        ProductImage(
          id: 9107,
          image: 'assets/images/grill_and_fry.jpg',
          isMain: true,
        ),
      ],
      availableEmirates: const [
        'dubai',
        'abu dhabi',
        'sharjah',
        'ajman',
        'ras al khaimah',
        'fujairah',
        'umm al quwain',
      ],
      preparationSpecifications: [
        PreparationSpecification(
          id: 9213,
          name: 'Assorted Dipping Sauces',
          description: 'Includes tartar, sweet chili, and garlic butter',
        ),
      ],
    ),
  ];
}
