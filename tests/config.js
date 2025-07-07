require('dotenv').config();

module.exports = {
  // MySQL Configuration
  mysql: {
    host: 'localhost',
    port: 3307,
    user: process.env.MYSQL_USER || 'test_user',
    password: process.env.MYSQL_PASSWORD || 'test_password',
    database: process.env.MYSQL_DATABASE || 'test_db',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
  },
  
  // PostgreSQL Configuration
  postgres: {
    host: 'localhost',
    port: 55432,
    user: process.env.POSTGRES_USER || 'test_user',
    password: process.env.POSTGRES_PASSWORD || 'test_password',
    database: process.env.POSTGRES_DB || 'test_db',
    max: 10,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
  },
  
  // MongoDB Configuration
  mongo: {
    url: `mongodb://${process.env.MONGO_ROOT_USERNAME || 'test_user'}:${process.env.MONGO_ROOT_PASSWORD || 'test_password'}@localhost:27018/${process.env.MONGO_DATABASE || 'test_db'}?authSource=admin`,
    options: {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    }
  },
  
  // Redis Configuration
  redis: {
    host: 'localhost',
    port: 6380,
    password: process.env.REDIS_PASSWORD || 'test_password',
    db: 0
  }
};
