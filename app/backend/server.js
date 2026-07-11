const express = require('express');
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const helmet = require('helmet');

const app = express();

app.use(express.json());
app.use(cors());
app.use(helmet());

// Database connection
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'bankingdb',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  ssl:
    process.env.DB_SSL === 'true'
      ? { rejectUnauthorized: false }
      : false,
});

const JWT_SECRET =
  process.env.JWT_SECRET || 'dev-secret-change-in-prod';

// Authentication middleware
const auth = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid token' });
  }
};

// ==================== Root Endpoint ====================

app.get('/', (req, res) => {
  res.json({
    application: 'Banking API',
    status: 'Running',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development',
  });
});

// ==================== Health Check ====================

app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
  });
});

// ==================== Authentication ====================

app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    const { rows } = await pool.query(
      'SELECT * FROM users WHERE email = $1',
      [email]
    );

    if (!rows[0]) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const valid = await bcrypt.compare(
      password,
      rows[0].password_hash
    );

    if (!valid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign(
      {
        id: rows[0].id,
        email: rows[0].email,
      },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      token,
      user: {
        id: rows[0].id,
        name: rows[0].full_name,
        email: rows[0].email,
      },
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/auth/register', async (req, res) => {
  try {
    const { email, password, full_name, phone } = req.body;

    const hash = await bcrypt.hash(password, 10);

    const { rows } = await pool.query(
      `INSERT INTO users
      (email, password_hash, full_name, phone)
      VALUES ($1,$2,$3,$4)
      RETURNING id,email,full_name`,
      [email, hash, full_name, phone]
    );

    const accNum = 'ACC-' + Date.now().toString().slice(-8);

    await pool.query(
      `INSERT INTO accounts
      (user_id, account_number, account_type, balance)
      VALUES ($1,$2,$3,$4)`,
      [rows[0].id, accNum, 'savings', 0]
    );

    res.status(201).json({ user: rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==================== Accounts ====================

app.get('/api/accounts', auth, async (req, res) => {
  try {
    const { rows } = await pool.query(
      'SELECT * FROM accounts WHERE user_id = $1',
      [req.user.id]
    );

    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/accounts/:id/balance', auth, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT account_number, account_type, balance, currency
       FROM accounts
       WHERE id = $1 AND user_id = $2`,
      [req.params.id, req.user.id]
    );

    if (!rows[0]) {
      return res.status(404).json({
        error: 'Account not found',
      });
    }

    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==================== Transactions ====================

app.post('/api/transactions/transfer', auth, async (req, res) => {
  const client = await pool.connect();

  try {
    const {
      from_account,
      to_account,
      amount,
      description,
    } = req.body;

    if (amount <= 0) {
      return res.status(400).json({
        error: 'Invalid amount',
      });
    }

    await client.query('BEGIN');

    const from = await client.query(
      `SELECT *
       FROM accounts
       WHERE id=$1 AND user_id=$2
       FOR UPDATE`,
      [from_account, req.user.id]
    );

    if (!from.rows[0]) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        error: 'Source account not found',
      });
    }

    if (from.rows[0].balance < amount) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        error: 'Insufficient funds',
      });
    }

    const to = await client.query(
      'SELECT * FROM accounts WHERE id=$1 FOR UPDATE',
      [to_account]
    );

    if (!to.rows[0]) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        error: 'Destination account not found',
      });
    }

    await client.query(
      'UPDATE accounts SET balance = balance - $1 WHERE id=$2',
      [amount, from_account]
    );

    await client.query(
      'UPDATE accounts SET balance = balance + $1 WHERE id=$2',
      [amount, to_account]
    );

    const { rows } = await client.query(
      `INSERT INTO transactions
      (from_account,to_account,amount,type,description)
      VALUES ($1,$2,$3,$4,$5)
      RETURNING *`,
      [
        from_account,
        to_account,
        amount,
        'transfer',
        description || 'Fund transfer',
      ]
    );

    await client.query('COMMIT');

    res.status(201).json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    res.status(500).json({ error: err.message });
  } finally {
    client.release();
  }
});

app.get('/api/transactions', auth, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT
          t.*,
          fa.account_number AS from_acc_num,
          ta.account_number AS to_acc_num
       FROM transactions t
       LEFT JOIN accounts fa
         ON t.from_account = fa.id
       LEFT JOIN accounts ta
         ON t.to_account = ta.id
       WHERE fa.user_id = $1
          OR ta.user_id = $1
       ORDER BY t.created_at DESC
       LIMIT 50`,
      [req.user.id]
    );

    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==================== Start Server ====================

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`🚀 Banking API running on port ${PORT}`);
});
