const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');

const app = express();
const PORT = 3001;
const JWT_SECRET = 'test-secret-key';

app.use(cors({
  origin: true,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
}));

app.use(express.json());

// Test users database (in-memory)
const users = [
  {
    id: 1,
    email: 'demo@devjourney.com',
    username: 'demo',
    password: 'password123', // In production, this should be hashed
  },
];

// Login endpoint
app.post('/api/auth/login', (req, res) => {
  console.log('LOGIN REQUEST:', req.body);
  
  const { email, password } = req.body;
  
  if (!email || !password) {
    return res.status(400).json({
      message: 'Email and password are required',
    });
  }
  
  const user = users.find(u => u.email === email && u.password === password);
  
  if (!user) {
    return res.status(401).json({
      message: 'Invalid credentials',
    });
  }
  
  const accessToken = jwt.sign(
    { userId: user.id, email: user.email },
    JWT_SECRET,
    { expiresIn: '7d' }
  );
  
  const refreshToken = jwt.sign(
    { userId: user.id, type: 'refresh' },
    JWT_SECRET,
    { expiresIn: '30d' }
  );
  
  const response = {
    accessToken,
    refreshToken,
    user: {
      id: user.id,
      email: user.email,
      username: user.username,
    },
  };
  
  console.log('LOGIN RESPONSE:', response);
  res.json(response);
});

// Register endpoint
app.post('/api/auth/register', (req, res) => {
  console.log('REGISTER REQUEST:', req.body);
  
  const { email, username, password } = req.body;
  
  if (!email || !username || !password) {
    return res.status(400).json({
      message: 'Email, username and password are required',
    });
  }
  
  const existingUser = users.find(u => u.email === email);
  if (existingUser) {
    return res.status(409).json({
      message: 'User already exists',
    });
  }
  
  const newUser = {
    id: users.length + 1,
    email,
    username,
    password, // In production, hash this
  };
  
  users.push(newUser);
  
  const accessToken = jwt.sign(
    { userId: newUser.id, email: newUser.email },
    JWT_SECRET,
    { expiresIn: '7d' }
  );
  
  const refreshToken = jwt.sign(
    { userId: newUser.id, type: 'refresh' },
    JWT_SECRET,
    { expiresIn: '30d' }
  );
  
  const response = {
    accessToken,
    refreshToken,
    user: {
      id: newUser.id,
      email: newUser.email,
      username: newUser.username,
    },
  };
  
  console.log('REGISTER RESPONSE:', response);
  res.json(response);
});

// Get current user
app.get('/api/auth/me', (req, res) => {
  const authHeader = req.headers.authorization;
  
  if (!authHeader) {
    return res.status(401).json({ message: 'No token provided' });
  }
  
  const token = authHeader.replace('Bearer ', '');
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = users.find(u => u.id === decoded.userId);
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    res.json({
      id: user.id,
      email: user.email,
      username: user.username,
    });
  } catch (error) {
    res.status(401).json({ message: 'Invalid token' });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Test server running on http://0.0.0.0:${PORT}`);
  console.log(`📝 Demo credentials: demo@devjourney.com / password123`);
  console.log(`🌐 Accessible from network at http://192.168.0.102:${PORT}`);
  
  // Keep process alive
  process.stdin.resume();
  
  // Handle process termination
  process.on('SIGINT', () => {
    console.log('\n⚠️  Server shutting down...');
    process.exit(0);
  });
});
