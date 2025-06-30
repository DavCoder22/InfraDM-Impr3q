// Initialize MongoDB with a catalog database and user
db = db.getSiblingDB('catalog');

// Create a user for the catalog database
db.createUser({
  user: 'catalog_user',
  pwd: 'catalog_password',
  roles: [
    {
      role: 'readWrite',
      db: 'catalog'
    }
  ]
});

// Create collections for catalog images
db.createCollection('product_images');
db.createCollection('category_images');

// Create indexes for better query performance
db.product_images.createIndex({ product_id: 1 });
db.category_images.createIndex({ category_id: 1 });
