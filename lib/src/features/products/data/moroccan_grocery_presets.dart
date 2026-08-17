/// Liste préréglée des produits d'épicerie marocaine les plus courants
/// (noms en français, avec les marques), classée par catégorie, pour
/// éviter au commerçant de tout saisir manuellement.
class GroceryPresetItem {
  const GroceryPresetItem({required this.name, required this.category});

  final String name;
  final String category;
}

const List<String> moroccanGroceryCategories = [
  'Huiles',
  'Épicerie sèche',
  'Produits laitiers',
  'Boissons',
  'Eaux minérales',
  'Nettoyants et Javel',
  'Hygiène personnelle',
  'Biscuits et confiseries',
  'Conserves et sauces',
  'Pain et pâtisserie',
];

const List<GroceryPresetItem> moroccanGroceryPresets = [
  // ===== Huiles =====
  GroceryPresetItem(name: 'Huile Afia 1L', category: 'Huiles'),
  GroceryPresetItem(name: 'Huile Lesieur Cristal 1L', category: 'Huiles'),
  GroceryPresetItem(name: 'Huile El Kef 1L', category: 'Huiles'),
  GroceryPresetItem(name: 'Huile Chams 1L', category: 'Huiles'),
  GroceryPresetItem(name: 'Huile d\'olive Sidi 1L', category: 'Huiles'),
  GroceryPresetItem(name: 'Huile d\'olive Afriquia 1L', category: 'Huiles'),
  GroceryPresetItem(name: 'Huile de soja Coco 1L', category: 'Huiles'),
  GroceryPresetItem(name: 'Huile Afia 5L', category: 'Huiles'),

  // ===== Épicerie sèche =====
  GroceryPresetItem(name: 'Sucre Cosumar 1kg', category: 'Épicerie sèche'),
  GroceryPresetItem(name: 'Sucre en morceaux Cosumar', category: 'Épicerie sèche'),
  GroceryPresetItem(name: 'Farine Sitanaf 10kg', category: 'Épicerie sèche'),
  GroceryPresetItem(name: 'Farine Chaarat 10kg', category: 'Épicerie sèche'),
  GroceryPresetItem(name: 'Farine Dari 10kg', category: 'Épicerie sèche'),
  GroceryPresetItem(name: 'Sel Maïda', category: 'Épicerie sèche'),
  GroceryPresetItem(name: 'Riz Casablanca 1kg', category: 'Épicerie sèche'),
  GroceryPresetItem(name: 'Lentilles / Fèves / Pois chiches (au kg)', category: 'Épicerie sèche'),
  GroceryPresetItem(name: 'Couscous Chaarat', category: 'Épicerie sèche'),
  GroceryPresetItem(name: 'Vermicelles / Pâtes', category: 'Épicerie sèche'),
  GroceryPresetItem(name: 'Thé Sultan', category: 'Épicerie sèche'),
  GroceryPresetItem(name: 'Thé El Attas', category: 'Épicerie sèche'),
  GroceryPresetItem(name: 'Café Nescafé', category: 'Épicerie sèche'),
  GroceryPresetItem(name: 'Levure Saf', category: 'Épicerie sèche'),

  // ===== Produits laitiers =====
  GroceryPresetItem(name: 'Lait Centrale Danone 1L', category: 'Produits laitiers'),
  GroceryPresetItem(name: 'Lait Nakhil', category: 'Produits laitiers'),
  GroceryPresetItem(name: 'Fromage La Vache Qui Rit', category: 'Produits laitiers'),
  GroceryPresetItem(name: 'Fromage Jibal', category: 'Produits laitiers'),
  GroceryPresetItem(name: 'Yaourt Danone Activia', category: 'Produits laitiers'),
  GroceryPresetItem(name: 'Beurre', category: 'Produits laitiers'),
  GroceryPresetItem(name: 'Lait concentré Nido', category: 'Produits laitiers'),

  // ===== Boissons =====
  GroceryPresetItem(name: 'Coca-Cola 1.5L', category: 'Boissons'),
  GroceryPresetItem(name: 'Pepsi 1.5L', category: 'Boissons'),
  GroceryPresetItem(name: 'Hamoud Boualem', category: 'Boissons'),
  GroceryPresetItem(name: 'Jus Marrakech', category: 'Boissons'),
  GroceryPresetItem(name: 'Jus Rafraîchissant', category: 'Boissons'),

  // ===== Eaux minérales =====
  GroceryPresetItem(name: 'Sidi Ali 1.5L', category: 'Eaux minérales'),
  GroceryPresetItem(name: 'Oulmès 1.5L', category: 'Eaux minérales'),
  GroceryPresetItem(name: 'Ain Saiss 1.5L', category: 'Eaux minérales'),
  GroceryPresetItem(name: 'Sidi Harazem 1.5L', category: 'Eaux minérales'),
  GroceryPresetItem(name: 'Ain Ifrane 1.5L', category: 'Eaux minérales'),

  // ===== Nettoyants et Javel =====
  GroceryPresetItem(name: 'Javel Jawex', category: 'Nettoyants et Javel'),
  GroceryPresetItem(name: 'Javel Nilly', category: 'Nettoyants et Javel'),
  GroceryPresetItem(name: 'Lessive Tide', category: 'Nettoyants et Javel'),
  GroceryPresetItem(name: 'Lessive Ariel', category: 'Nettoyants et Javel'),
  GroceryPresetItem(name: 'Lessive Axion', category: 'Nettoyants et Javel'),
  GroceryPresetItem(name: 'Liquide vaisselle Fairy', category: 'Nettoyants et Javel'),
  GroceryPresetItem(name: 'Désinfectant Ajax', category: 'Nettoyants et Javel'),
  GroceryPresetItem(name: 'Nettoyant vitres', category: 'Nettoyants et Javel'),
  GroceryPresetItem(name: 'Papier hygiénique', category: 'Nettoyants et Javel'),
  GroceryPresetItem(name: 'Sacs poubelle', category: 'Nettoyants et Javel'),

  // ===== Hygiène personnelle =====
  GroceryPresetItem(name: 'Savon Lux', category: 'Hygiène personnelle'),
  GroceryPresetItem(name: 'Savon Dove', category: 'Hygiène personnelle'),
  GroceryPresetItem(name: 'Savon Jamila', category: 'Hygiène personnelle'),
  GroceryPresetItem(name: 'Dentifrice Signal', category: 'Hygiène personnelle'),
  GroceryPresetItem(name: 'Shampoing Head & Shoulders', category: 'Hygiène personnelle'),

  // ===== Biscuits et confiseries =====
  GroceryPresetItem(name: 'Biscuits Bimo', category: 'Biscuits et confiseries'),
  GroceryPresetItem(name: 'Biscuits Le Matin', category: 'Biscuits et confiseries'),
  GroceryPresetItem(name: 'Chocolat Kinder', category: 'Biscuits et confiseries'),
  GroceryPresetItem(name: 'Chips', category: 'Biscuits et confiseries'),

  // ===== Conserves et sauces =====
  GroceryPresetItem(name: 'Concentré de tomate Atlas', category: 'Conserves et sauces'),
  GroceryPresetItem(name: 'Concentré de tomate Aïcha', category: 'Conserves et sauces'),
  GroceryPresetItem(name: 'Concentré de tomate Dolly', category: 'Conserves et sauces'),
  GroceryPresetItem(name: 'Thon en conserve', category: 'Conserves et sauces'),
  GroceryPresetItem(name: 'Olives en conserve', category: 'Conserves et sauces'),
  GroceryPresetItem(name: 'Mayonnaise Aïcha', category: 'Conserves et sauces'),

  // ===== Pain et pâtisserie =====
  GroceryPresetItem(name: 'Pain français / Baguette', category: 'Pain et pâtisserie'),
  GroceryPresetItem(name: 'Pain de mie Sandwich', category: 'Pain et pâtisserie'),
  GroceryPresetItem(name: 'Croissant', category: 'Pain et pâtisserie'),
];
