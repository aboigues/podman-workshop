const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const redis = require('redis');
const promClient = require('prom-client');

const app = express();
const PORT = process.env.PORT || 4000;

// Middleware
app.use(cors());
app.use(express.json());

// Prometheus metrics
const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register]
});

// PostgreSQL connection
const pool = new Pool({
  host: process.env.POSTGRES_HOST || 'postgres',
  port: process.env.POSTGRES_PORT || 5432,
  database: process.env.POSTGRES_DB || 'taskplatform',
  user: process.env.POSTGRES_USER || 'taskuser',
  password: process.env.POSTGRES_PASSWORD || 'changeme',
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Redis client
let redisClient;
const initRedis = async () => {
  redisClient = redis.createClient({
    socket: {
      host: process.env.REDIS_HOST || 'redis',
      port: process.env.REDIS_PORT || 6379
    },
    password: process.env.REDIS_PASSWORD
  });

  redisClient.on('error', (err) => console.error('Redis Client Error', err));
  redisClient.on('connect', () => console.log('Redis Client Connected'));

  await redisClient.connect();
};

// Initialize database tables
const initDatabase = async () => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS tasks (
        id SERIAL PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        status VARCHAR(50) DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('Database tables initialized');
  } catch (error) {
    console.error('Error initializing database:', error);
  }
};

// Metrics middleware
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    httpRequestDuration.labels(req.method, req.route?.path || req.path, res.statusCode).observe(duration);
  });
  next();
});

// Health check endpoint
app.get('/api/health', async (req, res) => {
  const health = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    services: {
      postgres: 'unknown',
      redis: 'unknown'
    }
  };

  // Check PostgreSQL
  try {
    await pool.query('SELECT 1');
    health.services.postgres = 'healthy';
  } catch (error) {
    health.services.postgres = 'unhealthy';
    health.status = 'degraded';
  }

  // Check Redis
  try {
    if (redisClient && redisClient.isOpen) {
      await redisClient.ping();
      health.services.redis = 'healthy';
    } else {
      health.services.redis = 'disconnected';
      health.status = 'degraded';
    }
  } catch (error) {
    health.services.redis = 'unhealthy';
    health.status = 'degraded';
  }

  res.status(health.status === 'healthy' ? 200 : 503).json(health);
});

// Prometheus metrics endpoint
app.get('/api/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// Get all tasks
app.get('/api/tasks', async (req, res) => {
  try {
    // Try to get from cache
    if (redisClient && redisClient.isOpen) {
      const cached = await redisClient.get('tasks:all');
      if (cached) {
        return res.json(JSON.parse(cached));
      }
    }

    // Get from database
    const result = await pool.query('SELECT * FROM tasks ORDER BY created_at DESC');

    // Cache the result
    if (redisClient && redisClient.isOpen) {
      await redisClient.setEx('tasks:all', 60, JSON.stringify(result.rows));
    }

    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching tasks:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get single task
app.get('/api/tasks/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('SELECT * FROM tasks WHERE id = $1', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Task not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching task:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create task
app.post('/api/tasks', async (req, res) => {
  try {
    const { title, description } = req.body;

    if (!title) {
      return res.status(400).json({ error: 'Title is required' });
    }

    const result = await pool.query(
      'INSERT INTO tasks (title, description) VALUES ($1, $2) RETURNING *',
      [title, description]
    );

    // Invalidate cache
    if (redisClient && redisClient.isOpen) {
      await redisClient.del('tasks:all');
    }

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating task:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update task
app.put('/api/tasks/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, status } = req.body;

    const result = await pool.query(
      'UPDATE tasks SET title = COALESCE($1, title), description = COALESCE($2, description), status = COALESCE($3, status), updated_at = CURRENT_TIMESTAMP WHERE id = $4 RETURNING *',
      [title, description, status, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Task not found' });
    }

    // Invalidate cache
    if (redisClient && redisClient.isOpen) {
      await redisClient.del('tasks:all');
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error updating task:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Delete task
app.delete('/api/tasks/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM tasks WHERE id = $1 RETURNING *', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Task not found' });
    }

    // Invalidate cache
    if (redisClient && redisClient.isOpen) {
      await redisClient.del('tasks:all');
    }

    res.json({ message: 'Task deleted successfully' });
  } catch (error) {
    console.error('Error deleting task:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Stats endpoint
app.get('/api/stats', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        COUNT(*) as total,
        COUNT(*) FILTER (WHERE status = 'pending') as pending,
        COUNT(*) FILTER (WHERE status = 'in_progress') as in_progress,
        COUNT(*) FILTER (WHERE status = 'completed') as completed
      FROM tasks
    `);

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching stats:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Start server
const startServer = async () => {
  try {
    // Initialize database
    await initDatabase();

    // Initialize Redis
    await initRedis();

    // Start listening
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`Server listening on port ${PORT}`);
      console.log(`Health check: http://localhost:${PORT}/api/health`);
      console.log(`Metrics: http://localhost:${PORT}/api/metrics`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

// Handle shutdown gracefully
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully...');
  if (redisClient) await redisClient.quit();
  await pool.end();
  process.exit(0);
});

startServer();
