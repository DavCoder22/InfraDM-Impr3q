const { MongoClient } = require('mongodb');
const config = require('../config');

// Test data
const testProductImage = {
  product_id: 'test-product-' + Date.now(),
  name: 'test-product-image.jpg',
  url: 'https://example.com/images/test-product.jpg',
  size: 1024,
  width: 800,
  height: 600,
  format: 'jpg',
  created_at: new Date(),
  updated_at: new Date()
};

const testCategoryImage = {
  category_id: 'test-category-' + Date.now(),
  name: 'test-category-image.jpg',
  url: 'https://example.com/categories/test-category.jpg',
  size: 2048,
  width: 1200,
  height: 800,
  format: 'jpg',
  created_at: new Date(),
  updated_at: new Date()
};

describe('MongoDB Database Tests - Catalog', () => {
  let client;
  let db;
  let productImagesCollection;
  let categoryImagesCollection;

  beforeAll(async () => {
    // Connect to MongoDB
    client = new MongoClient(config.mongo.url, config.mongo.options);
    await client.connect();
    
    // Get the database and collections
    db = client.db();
    productImagesCollection = db.collection('product_images');
    categoryImagesCollection = db.collection('category_images');
  });

  afterAll(async () => {
    // Clean up and close the connection
    if (client) {
      // Delete test data
      if (testProductImage.product_id) {
        await productImagesCollection.deleteMany({ product_id: testProductImage.product_id });
      }
      if (testCategoryImage.category_id) {
        await categoryImagesCollection.deleteMany({ category_id: testCategoryImage.category_id });
      }
      await client.close();
    }
  });

  test('1. CREATE - Debe insertar una nueva imagen de producto', async () => {
    const result = await productImagesCollection.insertOne(testProductImage);
    expect(result.acknowledged).toBe(true);
    expect(result.insertedId).toBeDefined();
    
    // Save the inserted ID for later tests
    testProductImage._id = result.insertedId;
  });

  test('2. READ - Debe recuperar la imagen de producto insertada', async () => {
    const image = await productImagesCollection.findOne({ _id: testProductImage._id });
    
    expect(image).toBeDefined();
    expect(image.product_id).toBe(testProductImage.product_id);
    expect(image.name).toBe(testProductImage.name);
    expect(image.url).toBe(testProductImage.url);
  });

  test('3. UPDATE - Debe actualizar la imagen de producto', async () => {
    const newName = 'updated-product-image.jpg';
    const result = await productImagesCollection.updateOne(
      { _id: testProductImage._id },
      { $set: { name: newName, updated_at: new Date() } }
    );
    
    expect(result.acknowledged).toBe(true);
    expect(result.matchedCount).toBe(1);
    expect(result.modifiedCount).toBe(1);
    
    // Verify the update
    const updatedImage = await productImagesCollection.findOne({ _id: testProductImage._id });
    expect(updatedImage.name).toBe(newName);
  });

  test('4. CREATE - Debe insertar una nueva imagen de categoría', async () => {
    const result = await categoryImagesCollection.insertOne(testCategoryImage);
    expect(result.acknowledged).toBe(true);
    expect(result.insertedId).toBeDefined();
    
    // Save the inserted ID for later tests
    testCategoryImage._id = result.insertedId;
  });

  test('5. READ - Debe recuperar la imagen de categoría insertada', async () => {
    const image = await categoryImagesCollection.findOne({ _id: testCategoryImage._id });
    
    expect(image).toBeDefined();
    expect(image.category_id).toBe(testCategoryImage.category_id);
    expect(image.name).toBe(testCategoryImage.name);
    expect(image.url).toBe(testCategoryImage.url);
  });

  test('6. DELETE - Debe eliminar las imágenes de prueba', async () => {
    // Delete product image
    const deleteProductImage = await productImagesCollection.deleteOne({ _id: testProductImage._id });
    expect(deleteProductImage.acknowledged).toBe(true);
    expect(deleteProductImage.deletedCount).toBe(1);
    
    // Delete category image
    const deleteCategoryImage = await categoryImagesCollection.deleteOne({ _id: testCategoryImage._id });
    expect(deleteCategoryImage.acknowledged).toBe(true);
    expect(deleteCategoryImage.deletedCount).toBe(1);
    
    // Verify deletion
    const productImage = await productImagesCollection.findOne({ _id: testProductImage._id });
    const categoryImage = await categoryImagesCollection.findOne({ _id: testCategoryImage._id });
    
    expect(productImage).toBeNull();
    expect(categoryImage).toBeNull();
  });
});
